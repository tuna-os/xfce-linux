"""Regression tests for the BuildStream dashboard log parser."""

import importlib.util
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

