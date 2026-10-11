"""Process lifecycle management for BuildStream container builds."""

import os
import datetime
import subprocess
import threading
import multiprocessing


class BuildProcessManager:
    def __init__(self, bst_image: str, bst_target: str, project_dir: str, log_file: str, is_telemetry_running_fn=None):
        self.bst_image = bst_image
        self.bst_target = bst_target
        self.project_dir = project_dir
        self.log_file = log_file
        self.is_telemetry_running_fn = is_telemetry_running_fn or (lambda: False)
        self.lock = threading.Lock()
        self.build_proc: "subprocess.Popen | None" = None

    def bst_container_id(self) -> str:
        """Return container ID of any running BST2 container, or empty string."""
        try:
            result = subprocess.run(
                ["podman", "ps", "-q", "--filter", f"ancestor={self.bst_image}"],
                capture_output=True, text=True, timeout=3,
            )
            return result.stdout.strip()
        except Exception:
            return ""

    def build_running(self) -> bool:
        if self.build_proc is not None and self.build_proc.poll() is None:
            return True
        return self.is_telemetry_running_fn()

    def start_build(self) -> bool:
        with self.lock:
            if self.build_running():
                return False
            nproc = multiprocessing.cpu_count()
            cache_dir = os.path.join(os.path.expanduser("~"), ".cache", "buildstream")
            os.makedirs(cache_dir, exist_ok=True)
            with open(self.log_file, "w") as f:
                f.write(f"=== Build started at {datetime.datetime.now().strftime('%c')} ===\n")
            log_f = open(self.log_file, "a")
            cmd = [
                "podman", "run", "--rm",
                "--privileged", "--device", "/dev/fuse", "--network=host",
                "-v", f"{self.project_dir}:/src:rw",
                "-v", f"{cache_dir}:/root/.cache/buildstream:rw",
                "-w", "/src",
                self.bst_image,
                "bash", "-c", 'bst --colors "$@"', "--",
                "--max-jobs", str(max(1, nproc // 2)),
                "--fetchers", str(nproc),
                "build", self.bst_target,
            ]
            self.build_proc = subprocess.Popen(cmd, stdout=log_f, stderr=log_f)
            return True

    def stop_build(self) -> bool:
        with self.lock:
            killed = False
            if self.build_proc is not None and self.build_proc.poll() is None:
                self.build_proc.terminate()
                killed = True
            cid = self.bst_container_id()
            if cid:
                try:
                    subprocess.run(["podman", "stop", cid], timeout=10)
                    killed = True
                except Exception:
                    pass
            return killed
