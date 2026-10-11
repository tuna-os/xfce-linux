"""Dependency tree discovery service for BuildStream."""

import os
import subprocess
import threading


class DeptreeService:
    def __init__(self, bst_image: str, bst_target: str, project_dir: str):
        self.bst_image = bst_image
        self.bst_target = bst_target
        self.project_dir = project_dir
        self.lock = threading.Lock()
        self.deptree: dict = {"status": "idle", "nodes": {}, "root": ""}

    def get_data(self) -> dict:
        with self.lock:
            return dict(self.deptree)

    def fetch(self):
        """Run bst show in the BST container and populate deptree."""
        with self.lock:
            if self.deptree["status"] == "loading":
                return   # already in progress
            self.deptree = {"status": "loading", "nodes": {}, "root": self.bst_target}

        try:
            cache_dir = os.path.join(os.path.expanduser("~"), ".cache", "buildstream")
            result = subprocess.run(
                [
                    "podman", "run", "--rm",
                    "--privileged", "--device", "/dev/fuse", "--network=host",
                    "-v", f"{self.project_dir}:/src:rw",
                    "-v", f"{cache_dir}:/root/.cache/buildstream:rw",
                    "-w", "/src",
                    self.bst_image,
                    "bst", "show", "--deps", "all",
                    "--format", "%{name}\t%{deps}\n",
                    self.bst_target,
                ],
                capture_output=True, text=True, timeout=300,
            )
            if result.returncode != 0:
                raise RuntimeError(result.stderr.strip()[-500:] or "bst show failed")

            nodes: dict[str, list] = {}
            current_name: "str | None" = None
            current_deps: list = []

            def _flush():
                if current_name is not None:
                    nodes[current_name] = current_deps[:]

            for raw_line in result.stdout.splitlines():
                if "\t" in raw_line:
                    _flush()
                    name_part, dep_part = raw_line.split("\t", 1)
                    current_name = name_part.strip()
                    current_deps = []
                    dep_part = dep_part.strip()
                    if dep_part and dep_part != "[]":
                        dep = dep_part.lstrip("-").strip()
                        if dep:
                            current_deps.append(dep)
                elif current_name is not None:
                    stripped = raw_line.strip()
                    if stripped.startswith("-"):
                        dep = stripped.lstrip("-").strip()
                        if dep:
                            current_deps.append(dep)
            _flush()

            with self.lock:
                self.deptree = {"status": "ready", "nodes": nodes, "root": self.bst_target}
        except Exception as exc:
            with self.lock:
                self.deptree = {"status": "error", "nodes": {}, "root": self.bst_target,
                                "error": str(exc)[:500]}

    def fetch_async(self):
        t = threading.Thread(target=self.fetch, daemon=True)
        t.start()
        return t
