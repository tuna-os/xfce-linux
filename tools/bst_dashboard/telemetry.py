"""System resource sampling adapters for BuildStream dashboard."""

import os
import time
import subprocess
import threading

class TelemetrySampler:
    def __init__(self, get_container_id_fn=None):
        self.get_container_id = get_container_id_fn or (lambda: "")
        self._lock = threading.Lock()
        self._sysinfo = {
            "cpu_pct": 0.0, "cpu_cores": [], "mem_used": 0, "mem_total": 0,
            "bst_cpu_pct": None, "bst_mem": None, "cpu_temp": None,
            "bst_running": False
        }
        self._cpu_prev: list[tuple[int, int]] = []
        self._thread = None
        self._running = False

    def get_sysinfo(self) -> dict:
        with self._lock:
            return dict(self._sysinfo)

    def is_bst_running(self) -> bool:
        with self._lock:
            return self._sysinfo.get("bst_running", False)

    @staticmethod
    def read_proc_stat() -> list[tuple[int, int]]:
        """Return a list of (idle_ticks, total_ticks), first entry is aggregate."""
        stats = []
        try:
            with open("/proc/stat") as f:
                for line in f:
                    if not line.startswith("cpu"):
                        break
                    parts = line.split()
                    vals = list(map(int, parts[1:8]))
                    idle  = vals[3] + vals[4]
                    total = sum(vals)
                    stats.append((idle, total))
        except Exception:
            pass
        return stats

    @staticmethod
    def read_proc_meminfo() -> tuple[int, int]:
        """Return (used_bytes, total_bytes) from /proc/meminfo."""
        info: dict[str, int] = {}
        with open("/proc/meminfo") as f:
            for line in f:
                k, v = line.split(":", 1)
                info[k.strip()] = int(v.split()[0])   # kB
        total = info.get("MemTotal", 0)
        avail = info.get("MemAvailable", 0)
        return (total - avail) * 1024, total * 1024

    @staticmethod
    def bst_container_stats(cid: str) -> tuple[float | None, int | None]:
        """Return (cpu_pct, mem_bytes) for the running BST container, or (None, None)."""
        if not cid:
            return None, None
        try:
            r = subprocess.run(
                ["podman", "stats", "--no-stream", "--format",
                 "{{.CPUPerc}},{{.MemUsage}}", cid],
                capture_output=True, text=True, timeout=3,
            )
            line = r.stdout.strip()
            if not line:
                return None, None
            cpu_str, mem_str = line.split(",", 1)
            cpu = float(cpu_str.strip().rstrip("%"))
            mem_used_str = mem_str.split("/")[0].strip()
            mul = 1
            for suffix, factor in [("GiB", 1 << 30), ("MiB", 1 << 20), ("kB", 1000)]:
                if mem_used_str.endswith(suffix):
                    mul = factor
                    mem_used_str = mem_used_str[:-len(suffix)]
                    break
            mem_bytes = int(float(mem_used_str) * mul)
            return cpu, mem_bytes
        except Exception:
            return None, None

    @staticmethod
    def get_cpu_temp() -> "float | None":
        """Return CPU package temperature in °C from hwmon or thermal_zone, or None."""
        try:
            hwmon_base = "/sys/class/hwmon"
            for hwmon_dir in sorted(os.listdir(hwmon_base)):
                hwmon_path = os.path.join(hwmon_base, hwmon_dir)
                try:
                    with open(os.path.join(hwmon_path, "name")) as f:
                        name = f.read().strip()
                except Exception:
                    continue
                if name not in ("coretemp", "k10temp", "zenpower", "cpu_thermal"):
                    continue
                best = None
                for fname in sorted(os.listdir(hwmon_path)):
                    if not (fname.startswith("temp") and fname.endswith("_input")):
                        continue
                    label = ""
                    try:
                        with open(os.path.join(hwmon_path, fname.replace("_input", "_label"))) as f:
                            label = f.read().strip()
                    except Exception:
                        pass
                    try:
                        with open(os.path.join(hwmon_path, fname)) as f:
                            val = int(f.read().strip()) / 1000.0
                    except Exception:
                        continue
                    if any(k in label for k in ("Package", "Tdie", "Tccd")):
                        return val
                    if best is None:
                        best = val
                if best is not None:
                    return best
        except Exception:
            pass

        try:
            for zone_dir in sorted(os.listdir("/sys/class/thermal")):
                if not zone_dir.startswith("thermal_zone"):
                    continue
                zone_path = os.path.join("/sys/class/thermal", zone_dir)
                try:
                    with open(os.path.join(zone_path, "type")) as f:
                        tz_type = f.read().strip().lower()
                    if any(k in tz_type for k in ("cpu", "x86", "acpitz")):
                        with open(os.path.join(zone_path, "temp")) as f:
                            return int(f.read().strip()) / 1000.0
                except Exception:
                    continue
        except Exception:
            pass
        return None

    def sample_once(self):
        stats = self.read_proc_stat()
        if not self._cpu_prev or len(self._cpu_prev) != len(stats):
            self._cpu_prev = stats
            return

        cpu_pcts = []
        for i in range(len(stats)):
            idle, total = stats[i]
            prev_idle, prev_total = self._cpu_prev[i]
            d_total = total - prev_total
            pct = round(100.0 * (1.0 - (idle - prev_idle) / d_total), 1) if d_total else 0.0
            cpu_pcts.append(max(0.0, min(100.0, pct)))

        self._cpu_prev = stats

        mem_used, mem_total = self.read_proc_meminfo()
        cid = self.get_container_id()
        bst_cpu, bst_mem = self.bst_container_stats(cid) if cid else (None, None)
        cpu_temp = self.get_cpu_temp()

        with self._lock:
            self._sysinfo["cpu_pct"]     = cpu_pcts[0]
            self._sysinfo["cpu_cores"]   = cpu_pcts[1:]
            self._sysinfo["mem_used"]    = mem_used
            self._sysinfo["mem_total"]   = mem_total
            self._sysinfo["bst_cpu_pct"] = bst_cpu
            self._sysinfo["bst_mem"]     = bst_mem
            self._sysinfo["cpu_temp"]    = cpu_temp
            self._sysinfo["bst_running"] = bool(cid)

    def _loop(self):
        while self._running:
            try:
                self.sample_once()
            except Exception:
                pass
            time.sleep(2)

    def start(self):
        if self._thread is None:
            self._running = True
            self._thread = threading.Thread(target=self._loop, daemon=True)
            self._thread.start()
