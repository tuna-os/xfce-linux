"""State model for BuildStream dashboard."""

import time
import threading


class State:
    def __init__(self):
        self._lock = threading.Lock()
        self.active: dict = {}
        self.completed: list = []
        self.failures: list = []
        self._summary_elements: set = set()  # elements named in BST Failure Summary
        self.pulled: int = 0
        self.success_count: int = 0
        self.failure_count: int = 0
        self.cached_count: int = 0    # build-queue skipped (already in local cache)
        self.total_elements: int = 0  # from Pipeline Summary "Total: N"
        self.recent_lines: list = []
        # Wall-clock timestamps from the log file itself
        self.build_start_ts: float = 0.0   # parsed from "=== Build started at ==="
        self.build_end_ts: float = 0.0     # mtime of log file when build last changed
        self.catching_up: bool = True       # True while doing initial log replay
        self.version = 0

    def snapshot(self, build_running_fn=None, sysinfo=None):
        with self._lock:
            live = bool(self.active) or self.catching_up
            if live:
                # Build is running: elapsed = now - start
                elapsed = int(time.time() - self.build_start_ts) if self.build_start_ts else 0
            elif self.build_end_ts and self.build_start_ts:
                # Build finished: show actual duration
                elapsed = int(self.build_end_ts - self.build_start_ts)
            else:
                elapsed = 0
            done = self.success_count + self.cached_count + self.pulled + self.failure_count
            is_running = build_running_fn() if build_running_fn else False
            return {
                "active": list(self.active.values()),
                "completed": self.completed[-60:],
                "failures": self.failures,
                "pulled": self.pulled,
                "success": self.success_count,
                "failure": self.failure_count,
                "cached": self.cached_count,
                "done": done,
                "total": self.total_elements,
                "recent": self.recent_lines[-80:],
                "elapsed": elapsed,
                "live": live,
                "catching_up": self.catching_up,
                "build_running": is_running,
                "version": self.version,
                "sysinfo": dict(sysinfo) if sysinfo is not None else {},
            }

    def update(self, fn):
        with self._lock:
            fn(self)
            self.version += 1
