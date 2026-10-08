"""Unit tests for bst_dashboard package components."""

import sys
from pathlib import Path
from unittest import mock

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[2]
TOOLS_DIR = str(PROJECT_ROOT / "tools")
if TOOLS_DIR not in sys.path:
    sys.path.insert(0, TOOLS_DIR)

from bst_dashboard.model import State
from bst_dashboard.parser import parse_line, reset_state, enrich_cmake
from bst_dashboard.telemetry import TelemetrySampler
from bst_dashboard.process import BuildProcessManager
from bst_dashboard.deptree import DeptreeService


def test_package_model_state_defaults():
    s = State()
    snap = s.snapshot(build_running_fn=lambda: False, sysinfo={"cpu_pct": 10.0})
    assert snap["active"] == []
    assert snap["completed"] == []
    assert snap["failures"] == []
    assert snap["sysinfo"]["cpu_pct"] == 10.0
    assert snap["build_running"] is False


def test_package_parser_line_tracking():
    s = State()
    parse_line("[00:00:01][abcdef][build:foo.bst] START   foo/abcdef-build.log", s)
    assert "abcdef" in s.active
    assert s.active["abcdef"]["element"] == "foo.bst"

    parse_line("[00:00:02][abcdef][build:foo.bst] SUCCESS foo/abcdef-build.log", s)
    assert "abcdef" not in s.active
    assert s.success_count == 1
    assert len(s.completed) == 1


def test_package_process_manager_lifecycle():
    pm = BuildProcessManager(
        bst_image="test-image",
        bst_target="test-target",
        project_dir="/tmp/test",
        log_file="/tmp/test.log",
        is_telemetry_running_fn=lambda: False,
    )
    with mock.patch("subprocess.run") as mock_run:
        mock_run.return_value = mock.Mock(stdout="cid-123\n")
        assert pm.bst_container_id() == "cid-123"

    mock_proc = mock.Mock()
    mock_proc.poll.return_value = None
    pm.build_proc = mock_proc
    assert pm.build_running() is True


def test_package_telemetry_sampler_proc_stat(monkeypatch, tmp_path):
    proc_stat = tmp_path / "stat"
    proc_stat.write_text("cpu  100 20 50 800 10 0 0 0\ncpu0 50 10 25 400 5 0 0 0\n")
    monkeypatch.setattr("builtins.open", mock.mock_open(read_data=proc_stat.read_text()))

    stats = TelemetrySampler.read_proc_stat()
    assert len(stats) >= 1
    # idle = 800 + 10 = 810
    assert stats[0][0] == 810


def test_package_deptree_service_fetch():
    ds = DeptreeService(
        bst_image="test-image",
        bst_target="target.bst",
        project_dir="/tmp/test",
    )
    with mock.patch("subprocess.run") as mock_run:
        mock_run.return_value = mock.Mock(
            returncode=0,
            stdout="pkg.bst\t- dep1.bst\n- dep2.bst\n",
        )
        ds.fetch()
        data = ds.get_data()
        assert data["status"] == "ready"
        assert "pkg.bst" in data["nodes"]
        assert data["nodes"]["pkg.bst"] == ["dep1.bst", "dep2.bst"]
