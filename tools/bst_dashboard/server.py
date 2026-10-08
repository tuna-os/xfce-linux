"""HTTP handler and server for BuildStream dashboard."""

import os
import json
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

from .parser import ANSI, enrich_cmake


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Handle requests in a separate thread."""
    daemon_threads = True


class DashboardHandler(BaseHTTPRequestHandler):
    state = None
    process_manager = None
    telemetry = None
    deptree_service = None
    html_content = ""

    def log_message(self, *args):
        pass  # silence access log

    def _json_reply(self, data: dict):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _norm_path(self):
        """Strip /bst prefix so we work both via Caddy and Tailscale Serve directly."""
        p = self.path.split("?", 1)
        path = p[0].rstrip("/") or "/"
        query = p[1] if len(p) > 1 else ""
        if path.startswith("/bst"):
            path = path[4:] or "/"
        return path, query

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        self.rfile.read(length)
        path, _ = self._norm_path()
        if path == "/api/start":
            ok = self.process_manager.start_build() if self.process_manager else False
            self._json_reply({"ok": ok})
        elif path == "/api/stop":
            ok = self.process_manager.stop_build() if self.process_manager else False
            self._json_reply({"ok": ok})
        elif path == "/api/deptree/refresh":
            if self.deptree_service:
                self.deptree_service.fetch_async()
            self._json_reply({"ok": True})
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        path, query = self._norm_path()
        if path == "/api/state":
            running_fn = self.process_manager.build_running if self.process_manager else (lambda: False)
            sysinfo = self.telemetry.get_sysinfo() if self.telemetry else {}
            snap = self.state.snapshot(build_running_fn=running_fn, sysinfo=sysinfo)
            enrich_cmake(snap)
            data = json.dumps(snap).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
        elif path == "/api/deptree":
            payload = self.deptree_service.get_data() if self.deptree_service else {"status": "idle", "nodes": {}, "root": ""}
            # Auto-trigger fetch if idle
            if payload.get("status") == "idle" and self.deptree_service:
                self.deptree_service.fetch_async()
                payload["status"] = "loading"
            data = json.dumps(payload).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
        elif path == "/api/log":
            params = dict(p.split("=", 1) for p in query.split("&") if "=" in p)
            log_path = None
            if "path" in params:
                # Direct path (for failures) — validate it stays inside buildstream logs
                candidate = urllib.parse.unquote(params["path"])
                bst_logs = os.path.expanduser("~/.cache/buildstream/logs")
                if os.path.abspath(candidate).startswith(bst_logs):
                    log_path = candidate
            elif "hash" in params:
                h = params["hash"]
                if self.state:
                    with self.state._lock:
                        entry = self.state.active.get(h)
                        if entry:
                            log_path = entry.get("log")
            if not log_path or not os.path.exists(log_path):
                body = b"Log not available"
                self.send_response(404)
            else:
                try:
                    with open(log_path, "rb") as f:
                        raw = f.read().decode("utf-8", errors="replace")
                    lines = ANSI.sub("", raw).splitlines()[-300:]
                    body = "\n".join(lines).encode()
                    self.send_response(200)
                except Exception as e:
                    body = str(e).encode()
                    self.send_response(500)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)
        else:
            body = self.html_content.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)
