"""Regression tests for the BuildStream dashboard log parser."""

import importlib.util
import io
from pathlib import Path
from unittest import mock

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = PROJECT_ROOT / "tools" / "bst-dashboard.py"


def _load_dashboard():
    spec = importlib.util.spec_from_file_location("bst_dashboard", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    # Importing the dashboard normally starts its daemon sampler. Unit tests
    # exercise parser logic only, so keep the background loop dormant.
    with mock.patch("threading.Thread.start"):
        spec.loader.exec_module(module)
    return module


@pytest.fixture
def dashboard(monkeypatch):
    module = _load_dashboard()
    module.STATE = module.State()
    monkeypatch.setattr(module, "build_running", lambda: False)
    return module


def event(status, *, action="build", element="xfce-linux/session.bst",
          build_hash="abcdef", message="xfce/session/abcdef-build.log"):
    return f"[00:00:01][{build_hash}][{action}:{element}] {status:<7} {message}"


def test_build_header_resets_previous_run(dashboard, monkeypatch):
    dashboard.STATE.success_count = 4
    dashboard.STATE.active["old"] = {"element": "old.bst"}
    monkeypatch.setattr(dashboard.time, "time", lambda: 99.0)

    dashboard.parse_line("=== Build started at invalid timestamp ===")

    snap = dashboard.STATE.snapshot()
    assert snap["success"] == 0
    assert snap["active"] == []
    assert snap["catching_up"] is True
    assert dashboard.STATE.build_start_ts == 99.0


def test_start_and_success_track_active_and_completed(dashboard, monkeypatch):
    times = iter((100.0, 112.0, 113.0))
    monkeypatch.setattr(dashboard.time, "time", lambda: next(times))

    dashboard.parse_line(event("START"))
    assert dashboard.STATE.active["abcdef"]["element"] == "xfce-linux/session.bst"
    assert dashboard.STATE.active["abcdef"]["log"].endswith(
        ".cache/buildstream/logs/xfce/session/abcdef-build.log"
    )

    dashboard.parse_line(event("SUCCESS"))

    assert dashboard.STATE.active == {}
    assert dashboard.STATE.success_count == 1
    assert dashboard.STATE.completed == [{
        "element": "xfce-linux/session.bst",
        "hash": "abcdef",
        "duration": 12,
        "status": "success",
    }]


@pytest.mark.parametrize(
    ("status", "expected_cached", "expected_pulled"),
    (("SKIPPED", 1, 0), ("SUCCESS", 0, 1)),
)
def test_pull_events_update_cache_accounting(
    dashboard, status, expected_cached, expected_pulled
):
    dashboard.parse_line(event(status, action="pull", message="Pull artifact"))

    assert dashboard.STATE.cached_count == expected_cached
    assert dashboard.STATE.pulled == expected_pulled


def test_pipeline_summary_filters_cascade_failures(dashboard, monkeypatch):
    dashboard.STATE.failures = [
        {"element": "root.bst", "hash": "1"},
        {"element": "cascade.bst", "hash": "2"},
    ]
    dashboard.STATE.failure_count = 2
    dashboard.STATE._summary_elements.add("root.bst")
    dashboard.STATE.active["still-running"] = {"element": "cascade.bst"}
    monkeypatch.setattr(dashboard.time, "time", lambda: 250.0)

    dashboard.parse_line("Pipeline Summary")

    assert dashboard.STATE.active == {}
    assert dashboard.STATE.failures == [{"element": "root.bst", "hash": "1"}]
    assert dashboard.STATE.failure_count == 1
    assert dashboard.STATE.catching_up is False
    assert dashboard.STATE.build_end_ts == 250.0


def test_summary_total_and_failed_queue_backfill(dashboard):
    dashboard.parse_line("  Total: 42")
    dashboard.parse_line("  Build Queue: processed 8, skipped 2, failed 3")

    assert dashboard.STATE.total_elements == 42
    assert dashboard.STATE.failure_count == 3


def test_failure_summary_adds_root_cause_and_log(dashboard, monkeypatch):
    monkeypatch.setattr(dashboard.os.path, "expanduser", lambda path: "/home/test/logs")

    dashboard.parse_line("    kde-build-meta.bst:kde/plasma/kwin.bst:")
    dashboard.parse_line("    /root/.cache/buildstream/logs/kde/kwin/failed.log")

    assert dashboard.STATE.failure_count == 1
    assert dashboard.STATE.failures[0]["element"] == "kde/plasma/kwin.bst"
    assert dashboard.STATE.failures[0]["log"] == "/home/test/logs/kde/kwin/failed.log"


def test_reset_state_preserves_pipeline_total(dashboard):
    dashboard.STATE.total_elements = 17
    dashboard.STATE.success_count = 2
    dashboard.STATE.recent_lines.append("old output")

    dashboard.reset_state()

    assert dashboard.STATE.total_elements == 17
    assert dashboard.STATE.success_count == 0
    assert dashboard.STATE.recent_lines == []
    assert dashboard.STATE.catching_up is True


def test_ansi_is_removed_before_recent_log_capture(dashboard):
    dashboard.parse_line("\x1b[31mplain warning\x1b[0m")

    assert dashboard.STATE.recent_lines == ["plain warning"]


def test_deeply_indented_failure_output_is_not_recent_noise(dashboard):
    dashboard.parse_line("        compiler diagnostic")

    assert dashboard.STATE.recent_lines == []


def test_top_level_command_failed_completes_active_job(dashboard, monkeypatch):
    # BuildStream emits top-level failures as "FAILURE ... Command failed"
    # with no .log path, so is_top is False for this line — but the job
    # must still leave `active` and be counted as a failure. Regression
    # test for the previously unreachable FAILURE branch (issue #108).
    times = iter((100.0, 130.0, 130.0))
    monkeypatch.setattr(dashboard.time, "time", lambda: next(times))

    dashboard.parse_line(event("START"))
    assert "abcdef" in dashboard.STATE.active

    dashboard.parse_line(event("FAILURE", message="Command failed"))

    assert dashboard.STATE.active == {}
    assert dashboard.STATE.failure_count == 1
    assert dashboard.STATE.failures[0]["hash"] == "abcdef"
    assert dashboard.STATE.failures[0]["status"] == "failure"
    assert dashboard.STATE.completed[-1]["status"] == "failure"


def test_failure_event_for_untracked_hash_is_ignored(dashboard):
    # A FAILURE line for a hash never seen in a START event is a sub-event
    # BST emits underneath the top-level job — it must not fabricate a
    # completed/failure entry.
    dashboard.parse_line(event("FAILURE", build_hash="never-started",
                                message="Command failed"))

    assert dashboard.STATE.completed == []
    assert dashboard.STATE.failures == []
    assert dashboard.STATE.failure_count == 0


def test_live_failure_updates_existing_failure_summary_catchup_entry(
    dashboard, monkeypatch
):
    # On catch-up, the Failure Summary block is parsed before the live START
    # for the same element, leaving a hash-less placeholder in `failures`.
    # A later live FAILURE event for that element must fill in the
    # placeholder rather than appending a duplicate.
    dashboard.parse_line("    kde-build-meta.bst:kde/plasma/kwin.bst:")
    assert dashboard.STATE.failures == [
        {"element": "kde/plasma/kwin.bst", "hash": "", "duration": 0,
         "status": "failure", "log": ""}
    ]

    times = iter((100.0, 130.0, 130.0))
    monkeypatch.setattr(dashboard.time, "time", lambda: next(times))
    dashboard.parse_line(event("START", element="kde/plasma/kwin.bst",
                                build_hash="deadbeef"))
    dashboard.parse_line(event("FAILURE", element="kde/plasma/kwin.bst",
                                build_hash="deadbeef", message="Command failed"))

    assert len(dashboard.STATE.failures) == 1
    assert dashboard.STATE.failures[0]["hash"] == "deadbeef"
    assert dashboard.STATE.failures[0]["duration"] == 30
    assert dashboard.STATE.failure_count == 1


def test_pull_queue_summary_does_not_backfill_failure_count(dashboard):
    # SUMMARY_QUEUE_RE matches both "Pull Queue:" and "Build Queue:" lines,
    # but only a Build Queue failure count should ever backfill state.
    dashboard.parse_line("  Pull Queue: processed 5, skipped 0, failed 9")

    assert dashboard.STATE.failure_count == 0


def test_summary_queue_backfill_skipped_when_failures_already_tracked(dashboard):
    dashboard.STATE.failure_count = 2

    dashboard.parse_line("  Build Queue: processed 8, skipped 2, failed 5")

    # Live-tracked failures are authoritative; the summary count is only a
    # fallback for failures that never produced a live FAILURE event.
    assert dashboard.STATE.failure_count == 2


# ── Build process control ───────────────────────────────────────────────────


@pytest.fixture
def raw_dashboard():
    """Like `dashboard`, but leaves build_running() unmocked so process-control
    tests can exercise it directly."""
    return _load_dashboard()


def test_bst_container_id_returns_stripped_stdout(raw_dashboard, monkeypatch):
    result = mock.Mock(stdout="  abc123\n")
    monkeypatch.setattr(raw_dashboard.subprocess, "run", lambda *a, **k: result)

    assert raw_dashboard._bst_container_id() == "abc123"


def test_bst_container_id_swallows_errors(raw_dashboard, monkeypatch):
    def _raise(*a, **k):
        raise OSError("podman not found")

    monkeypatch.setattr(raw_dashboard.subprocess, "run", _raise)

    assert raw_dashboard._bst_container_id() == ""


def test_build_running_true_when_proc_alive(raw_dashboard, monkeypatch):
    proc = mock.Mock()
    proc.poll.return_value = None
    raw_dashboard.BUILD_PROC = proc

    assert raw_dashboard.build_running() is True


def test_build_running_false_when_proc_exited_and_sysinfo_clear(raw_dashboard, monkeypatch):
    proc = mock.Mock()
    proc.poll.return_value = 0
    raw_dashboard.BUILD_PROC = proc
    raw_dashboard._sysinfo["bst_running"] = False

    assert raw_dashboard.build_running() is False


def test_build_running_falls_back_to_sysinfo_flag(raw_dashboard):
    raw_dashboard.BUILD_PROC = None
    raw_dashboard._sysinfo["bst_running"] = True

    assert raw_dashboard.build_running() is True


def test_start_build_refuses_when_already_running(raw_dashboard, monkeypatch):
    monkeypatch.setattr(raw_dashboard, "build_running", lambda: True)
    popen = mock.Mock()
    monkeypatch.setattr(raw_dashboard.subprocess, "Popen", popen)

    assert raw_dashboard.start_build() is False
    popen.assert_not_called()


def test_start_build_launches_podman_and_writes_header(raw_dashboard, monkeypatch, tmp_path):
    monkeypatch.setattr(raw_dashboard, "build_running", lambda: False)
    monkeypatch.setattr(raw_dashboard.os.path, "expanduser", lambda p: str(tmp_path))
    log_file = tmp_path / "build.log"
    monkeypatch.setattr(raw_dashboard, "LOG_FILE", str(log_file))
    popen = mock.Mock()
    monkeypatch.setattr(raw_dashboard.subprocess, "Popen", popen)

    assert raw_dashboard.start_build() is True
    assert log_file.exists()
    assert "Build started" in log_file.read_text()
    popen.assert_called_once()
    cmd = popen.call_args[0][0]
    assert cmd[0] == "podman"
    assert raw_dashboard.BST_TARGET in cmd


def test_stop_build_terminates_process_and_stops_container(raw_dashboard, monkeypatch):
    proc = mock.Mock()
    proc.poll.return_value = None
    raw_dashboard.BUILD_PROC = proc
    monkeypatch.setattr(raw_dashboard, "_bst_container_id", lambda: "cid123")
    run = mock.Mock()
    monkeypatch.setattr(raw_dashboard.subprocess, "run", run)

    assert raw_dashboard.stop_build() is True
    proc.terminate.assert_called_once()
    run.assert_called_once()
    assert "cid123" in run.call_args[0][0]


def test_stop_build_returns_false_when_nothing_to_stop(raw_dashboard, monkeypatch):
    raw_dashboard.BUILD_PROC = None
    monkeypatch.setattr(raw_dashboard, "_bst_container_id", lambda: "")

    assert raw_dashboard.stop_build() is False


def test_stop_build_swallows_podman_stop_errors(raw_dashboard, monkeypatch):
    raw_dashboard.BUILD_PROC = None
    monkeypatch.setattr(raw_dashboard, "_bst_container_id", lambda: "cid123")

    def _raise(*a, **k):
        raise OSError("timed out")

    monkeypatch.setattr(raw_dashboard.subprocess, "run", _raise)

    assert raw_dashboard.stop_build() is False


# ── cmake/rust progress enrichment ──────────────────────────────────────────


def test_enrich_cmake_sets_progress_from_bracket_markers(raw_dashboard, tmp_path):
    log = tmp_path / "job.log"
    log.write_text("building...\n[12/34] Building CXX object foo.cpp.o\n")
    snap = {"active": [{"log": str(log)}]}

    raw_dashboard._enrich_cmake(snap)

    assert snap["active"][0]["cmake_done"] == 12
    assert snap["active"][0]["cmake_total"] == 34


def test_enrich_cmake_counts_rust_crates_when_not_finished(raw_dashboard, tmp_path):
    # RUST_COMPILE_RE anchors with `^` and no re.MULTILINE, so findall can
    # only ever match at the very start of the tail — one hit per read, not
    # one per "Compiling" line in the buffer.
    log = tmp_path / "job.log"
    log.write_text("   Compiling foo v1.0\n   Compiling bar v2.0\n")
    snap = {"active": [{"log": str(log)}]}

    raw_dashboard._enrich_cmake(snap)

    assert snap["active"][0]["rust_crates"] == 1
    assert snap["active"][0]["rust_done"] is True


def test_enrich_cmake_skips_jobs_without_log_path(raw_dashboard):
    snap = {"active": [{"log": ""}, {}]}

    raw_dashboard._enrich_cmake(snap)  # must not raise

    assert "cmake_done" not in snap["active"][0]


def test_enrich_cmake_swallows_missing_file(raw_dashboard):
    snap = {"active": [{"log": "/nonexistent/path.log"}]}

    raw_dashboard._enrich_cmake(snap)  # must not raise

    assert "cmake_done" not in snap["active"][0]


# ── Dependency tree ──────────────────────────────────────────────────────────


def test_fetch_deptree_parses_bst_show_output(raw_dashboard, monkeypatch):
    stdout = (
        "root.bst\t- a.bst\n"
        "- b.bst\n"
        "a.bst\t[]\n"
        "b.bst\t- a.bst\n"
    )
    result = mock.Mock(returncode=0, stdout=stdout, stderr="")
    monkeypatch.setattr(raw_dashboard.subprocess, "run", lambda *a, **k: result)

    raw_dashboard._fetch_deptree()

    assert raw_dashboard._deptree["status"] == "ready"
    assert raw_dashboard._deptree["nodes"]["root.bst"] == ["a.bst", "b.bst"]
    assert raw_dashboard._deptree["nodes"]["a.bst"] == []
    assert raw_dashboard._deptree["nodes"]["b.bst"] == ["a.bst"]


def test_fetch_deptree_records_error_on_nonzero_exit(raw_dashboard, monkeypatch):
    result = mock.Mock(returncode=1, stdout="", stderr="boom")
    monkeypatch.setattr(raw_dashboard.subprocess, "run", lambda *a, **k: result)

    raw_dashboard._fetch_deptree()

    assert raw_dashboard._deptree["status"] == "error"
    assert "boom" in raw_dashboard._deptree["error"]


def test_fetch_deptree_skips_when_already_loading(raw_dashboard, monkeypatch):
    raw_dashboard._deptree = {"status": "loading", "nodes": {}, "root": ""}
    run = mock.Mock()
    monkeypatch.setattr(raw_dashboard.subprocess, "run", run)

    raw_dashboard._fetch_deptree()

    run.assert_not_called()


# ── System resource sampling ────────────────────────────────────────────────


def test_read_proc_stat_parses_idle_and_total(raw_dashboard, monkeypatch):
    fake = mock.mock_open(read_data="cpu  1 2 3 4 5 6 7\ncpu0 1 1 1 1 1 1 1\nintr 0\n")
    monkeypatch.setattr("builtins.open", fake)

    stats = raw_dashboard._read_proc_stat()

    assert stats[0] == (4 + 5, 1 + 2 + 3 + 4 + 5 + 6 + 7)
    assert len(stats) == 2


def test_read_proc_stat_swallows_errors(raw_dashboard, monkeypatch):
    def _raise(*a, **k):
        raise OSError("no /proc")

    monkeypatch.setattr("builtins.open", _raise)

    assert raw_dashboard._read_proc_stat() == []


def test_read_proc_meminfo_computes_used_and_total(raw_dashboard, monkeypatch):
    fake = mock.mock_open(
        read_data="MemTotal:       1000 kB\nMemAvailable:    400 kB\nOther:    1 kB\n"
    )
    monkeypatch.setattr("builtins.open", fake)

    used, total = raw_dashboard._read_proc_meminfo()

    assert used == (1000 - 400) * 1024
    assert total == 1000 * 1024


def test_bst_container_stats_returns_none_for_empty_cid(raw_dashboard):
    assert raw_dashboard._bst_container_stats("") == (None, None)


def test_bst_container_stats_parses_gib(raw_dashboard, monkeypatch):
    result = mock.Mock(stdout="12.5%,1.50GiB / 31.7GiB\n")
    monkeypatch.setattr(raw_dashboard.subprocess, "run", lambda *a, **k: result)

    cpu, mem = raw_dashboard._bst_container_stats("cid")

    assert cpu == 12.5
    assert mem == int(1.50 * (1 << 30))


def test_bst_container_stats_parses_mib(raw_dashboard, monkeypatch):
    result = mock.Mock(stdout="3.0%,256.00MiB / 8.00GiB\n")
    monkeypatch.setattr(raw_dashboard.subprocess, "run", lambda *a, **k: result)

    cpu, mem = raw_dashboard._bst_container_stats("cid")

    assert cpu == 3.0
    assert mem == int(256.00 * (1 << 20))


def test_bst_container_stats_returns_none_on_empty_output(raw_dashboard, monkeypatch):
    result = mock.Mock(stdout="")
    monkeypatch.setattr(raw_dashboard.subprocess, "run", lambda *a, **k: result)

    assert raw_dashboard._bst_container_stats("cid") == (None, None)


def test_bst_container_stats_swallows_errors(raw_dashboard, monkeypatch):
    def _raise(*a, **k):
        raise OSError("podman missing")

    monkeypatch.setattr(raw_dashboard.subprocess, "run", _raise)

    assert raw_dashboard._bst_container_stats("cid") == (None, None)


# ── HTTP handler ─────────────────────────────────────────────────────────────


def _make_handler(dashboard_module, path, body=b""):
    handler = dashboard_module.Handler.__new__(dashboard_module.Handler)
    handler.path = path
    handler.headers = {"Content-Length": str(len(body))}
    handler.rfile = io.BytesIO(body)
    handler.wfile = io.BytesIO()
    handler.send_response = mock.Mock()
    handler.send_header = mock.Mock()
    handler.end_headers = mock.Mock()
    return handler


def test_norm_path_strips_bst_prefix(dashboard):
    handler = _make_handler(dashboard, "/bst/api/state?x=1")

    path, query = handler._norm_path()

    assert path == "/api/state"
    assert query == "x=1"


def test_norm_path_passes_through_without_prefix(dashboard):
    handler = _make_handler(dashboard, "/api/state")

    path, query = handler._norm_path()

    assert path == "/api/state"
    assert query == ""


def test_do_post_start_calls_start_build(dashboard, monkeypatch):
    monkeypatch.setattr(dashboard, "start_build", lambda: True)
    handler = _make_handler(dashboard, "/api/start")

    handler.do_POST()

    handler.send_response.assert_called_once_with(200)
    assert b'"ok": true' in handler.wfile.getvalue()


def test_do_post_stop_calls_stop_build(dashboard, monkeypatch):
    monkeypatch.setattr(dashboard, "stop_build", lambda: False)
    handler = _make_handler(dashboard, "/api/stop")

    handler.do_POST()

    assert b'"ok": false' in handler.wfile.getvalue()


def test_do_post_deptree_refresh_starts_thread(dashboard, monkeypatch):
    started = mock.Mock()
    monkeypatch.setattr(dashboard.threading.Thread, "start", started)
    handler = _make_handler(dashboard, "/api/deptree/refresh")

    handler.do_POST()

    started.assert_called_once()
    assert b'"ok": true' in handler.wfile.getvalue()


def test_do_post_unknown_path_404s(dashboard):
    handler = _make_handler(dashboard, "/api/nope")

    handler.do_POST()

    handler.send_response.assert_called_once_with(404)


def test_do_get_state_enriches_and_replies(dashboard, monkeypatch):
    monkeypatch.setattr(dashboard, "_enrich_cmake", lambda snap: snap.update(cmake_done=1))
    handler = _make_handler(dashboard, "/api/state")

    handler.do_GET()

    handler.send_response.assert_called_once_with(200)
    assert b"cmake_done" in handler.wfile.getvalue()


def test_do_get_deptree_triggers_fetch_when_idle(dashboard, monkeypatch):
    dashboard._deptree = {"status": "idle", "nodes": {}, "root": ""}
    started = mock.Mock()
    monkeypatch.setattr(dashboard.threading.Thread, "start", started)
    handler = _make_handler(dashboard, "/api/deptree")

    handler.do_GET()

    started.assert_called_once()
    assert b'"loading"' in handler.wfile.getvalue()


def test_do_get_log_by_hash_returns_tail(dashboard, tmp_path):
    log = tmp_path / "j.log"
    log.write_text("line1\nline2\nline3\n")
    dashboard.STATE.active["deadbeef"] = {"log": str(log)}
    handler = _make_handler(dashboard, "/api/log?hash=deadbeef")

    handler.do_GET()

    handler.send_response.assert_called_once_with(200)
    assert b"line1" in handler.wfile.getvalue()


def test_do_get_log_missing_returns_404(dashboard):
    handler = _make_handler(dashboard, "/api/log?hash=nope")

    handler.do_GET()

    handler.send_response.assert_called_once_with(404)


def test_do_get_log_rejects_path_outside_buildstream_logs(dashboard, monkeypatch, tmp_path):
    monkeypatch.setattr(dashboard.os.path, "expanduser", lambda p: str(tmp_path / "logs"))
    outside = tmp_path / "outside.log"
    outside.write_text("secret")
    handler = _make_handler(dashboard, f"/api/log?path={outside}")

    handler.do_GET()

    handler.send_response.assert_called_once_with(404)


def test_do_get_unknown_path_serves_html(dashboard):
    handler = _make_handler(dashboard, "/")

    handler.do_GET()

    handler.send_response.assert_called_once_with(200)
    assert handler.wfile.getvalue() == dashboard.HTML.encode()

