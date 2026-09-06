"""Unit tests for scripts/gen-filemap.py.

Tests the helper functions isolated from BST/subprocess calls:
- strip_ansi() — ANSI escape code removal
- guess_interval() — update interval heuristic
- bst() — subprocess wrapper and its error path
- list_elements() — element name filtering
- list_all_contents() — artifact listing parser
- main() — end-to-end dry-run and file-writing paths
"""

import importlib.util
import json
import subprocess
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# Load gen-filemap.py as a module (filename has hyphen, so importlib is needed)
MODULE_PATH = PROJECT_ROOT / "scripts" / "gen-filemap.py"
spec = importlib.util.spec_from_file_location("gen_filemap", MODULE_PATH)
gen_filemap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen_filemap)

strip_ansi = gen_filemap.strip_ansi
guess_interval = gen_filemap.guess_interval
bst = gen_filemap.bst
list_elements = gen_filemap.list_elements
list_all_contents = gen_filemap.list_all_contents
main = gen_filemap.main


# ── strip_ansi tests ──────────────────────────────────────────────────────────

class TestStripAnsi:
    def test_strips_simple_escape(self):
        """Strip simple ANSI color code."""
        result = strip_ansi("\x1b[31mred\x1b[0m")
        assert result == "red", f"Expected 'red', got {result!r}"

    def test_strips_multiple_codes(self):
        """Strip multiple ANSI codes in one string."""
        result = strip_ansi("\x1b[1m\x1b[32mbold green\x1b[0m")
        assert result == "bold green", f"Expected 'bold green', got {result!r}"

    def test_strips_cursor_movement(self):
        """Strip cursor movement codes."""
        result = strip_ansi("\x1b[10A\x1b[Kline")
        assert result == "line", f"Expected 'line', got {result!r}"

    def test_preserves_normal_text(self):
        """String without ANSI codes should pass through unchanged."""
        text = "hello world"
        assert strip_ansi(text) == text

    def test_preserves_empty_string(self):
        """Empty string should remain empty."""
        assert strip_ansi("") == ""

    def test_strips_bracketless_reset(self):
        """Strip \x1b[m reset code."""
        result = strip_ansi("text\x1b[m")
        assert result == "text", f"Expected 'text', got {result!r}"


# ── guess_interval tests ──────────────────────────────────────────────────────

class TestGuessInterval:
    def test_xfce_linux_is_weekly(self):
        """Elements matching 'xfce-linux/' should be weekly."""
        assert guess_interval("xfce-linux/xfce4-session.bst") == "weekly"

    def test_gnome_is_monthly(self):
        """Elements matching 'gnome/' should be monthly."""
        assert guess_interval("gnome/gnome-shell.bst") == "monthly"

    def test_freedesktop_sdk_is_monthly(self):
        """Elements matching 'freedesktop-sdk' should be monthly."""
        assert guess_interval("freedesktop-sdk/sdk.bst") == "monthly"

    def test_unknown_element_defaults_to_monthly(self):
        """Elements not matching any hint should default to monthly."""
        assert guess_interval("kde/plasma.bst") == "monthly"
        assert guess_interval("custom/element.bst") == "monthly"
        assert guess_interval("unknown") == "monthly"

    def test_first_match_wins(self):
        """When multiple hints match, the first in INTERVAL_HINTS should win."""
        result = guess_interval("xfce-linux/freedesktop-sdk-dep.bst")
        assert result == "weekly", f"Expected 'weekly' (first match), got {result!r}"

    def test_case_sensitive_matching(self):
        """Matching should be case-sensitive (as implemented in the script)."""
        assert guess_interval("XFCE-LINUX/element.bst") == "monthly"


# ── bst() tests ───────────────────────────────────────────────────────────────

class _FakeResult:
    def __init__(self, returncode=0, stdout="", stderr=""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


class TestBst:
    def test_runs_just_bst_with_args(self, monkeypatch):
        """bst() should shell out to `just bst <args>` from the project root."""
        captured = {}

        def fake_run(cmd, cwd, capture_output, text):
            captured["cmd"] = cmd
            captured["cwd"] = cwd
            return _FakeResult(returncode=0, stdout="output\n")

        monkeypatch.setattr(subprocess, "run", fake_run)
        result = bst("show", "--format", "%{name}")

        assert captured["cmd"] == ["just", "bst", "show", "--format", "%{name}"]
        assert captured["cwd"] == gen_filemap.PROJECT_ROOT
        assert result == "output\n"

    def test_nonzero_exit_aborts(self, monkeypatch, capsys):
        """A failing `just bst` invocation should print stderr and exit(1)."""
        def fake_run(cmd, cwd, capture_output, text):
            return _FakeResult(returncode=1, stdout="", stderr="boom")

        monkeypatch.setattr(subprocess, "run", fake_run)

        with pytest.raises(SystemExit) as exc_info:
            bst("show", "target.bst")

        assert exc_info.value.code == 1
        assert "boom" in capsys.readouterr().err


# ── list_elements() tests ───────────────────────────────────────────────────

class TestListElements:
    def test_filters_to_bst_paths(self, monkeypatch):
        """Only lines that look like element paths (end in .bst) survive."""
        raw = "\n".join([
            "\x1b[32mxfce-linux/xfce4-session.bst\x1b[0m",
            "Resolved (variable-substituted name, not a real element)",
            "gnome/gnome-shell.bst",
            "",
            "   oci/layers/xfce-linux.bst   ",
        ])
        monkeypatch.setattr(gen_filemap, "bst", lambda *a: raw)

        result = list_elements("oci/xfce-linux.bst")

        assert result == [
            "xfce-linux/xfce4-session.bst",
            "gnome/gnome-shell.bst",
            "oci/layers/xfce-linux.bst",
        ]


# ── list_all_contents() tests ───────────────────────────────────────────────

class TestListAllContents:
    def test_parses_headers_and_entries(self, monkeypatch):
        """Element headers group subsequent tab-indented file entries."""
        raw = "\n".join([
            "xfce-linux/xfce4-session.bst:",
            "\t-rwxr-xr-x  exe  32003936  usr/bin/xfce4-session",
            "\tdrwxr-xr-x  dir         0  usr/share/icons",
            "gnome/gnome-shell.bst:",
            "\t-rw-r--r--  reg     1024  usr/lib/libmutter.so",
        ])
        monkeypatch.setattr(gen_filemap, "bst", lambda *a: raw)

        result = list_all_contents(["xfce-linux/xfce4-session.bst", "gnome/gnome-shell.bst"])

        assert result == {
            "xfce-linux/xfce4-session.bst": ["/usr/bin/xfce4-session"],
            "gnome/gnome-shell.bst": ["/usr/lib/libmutter.so"],
        }

    def test_skips_lines_before_any_header(self, monkeypatch):
        """Tab-indented entries seen before any element header are ignored."""
        raw = "\n\t-rwxr-xr-x  exe  100  usr/bin/orphan\nxfce-linux/x.bst:\n\t-rwxr-xr-x  exe  1  usr/bin/x"
        monkeypatch.setattr(gen_filemap, "bst", lambda *a: raw)

        result = list_all_contents(["xfce-linux/x.bst"])

        assert result == {"xfce-linux/x.bst": ["/usr/bin/x"]}

    def test_skips_short_malformed_lines(self, monkeypatch):
        """Lines with fewer than 4 whitespace-separated fields are ignored."""
        raw = "xfce-linux/x.bst:\n\ttoo short\n\t-rwxr-xr-x  exe  1  usr/bin/x"
        monkeypatch.setattr(gen_filemap, "bst", lambda *a: raw)

        result = list_all_contents(["xfce-linux/x.bst"])

        assert result == {"xfce-linux/x.bst": ["/usr/bin/x"]}

    def test_elements_with_no_files_are_absent(self, monkeypatch):
        """An element header with zero surviving entries yields no dict key
        (defaultdict is only populated on append)."""
        raw = "xfce-linux/empty.bst:\n\tdrwxr-xr-x  dir  0  usr/share/empty"
        monkeypatch.setattr(gen_filemap, "bst", lambda *a: raw)

        result = list_all_contents(["xfce-linux/empty.bst"])

        assert result == {}


# ── main() tests ─────────────────────────────────────────────────────────────

class TestMain:
    def _stub_bst_pipeline(self, monkeypatch, elements, contents):
        monkeypatch.setattr(gen_filemap, "list_elements", lambda target: elements)
        monkeypatch.setattr(gen_filemap, "list_all_contents", lambda els: contents)

    def test_dry_run_prints_json_without_writing(self, monkeypatch, capsys, tmp_path):
        fake_output = tmp_path / "filemap.json"
        monkeypatch.setattr(gen_filemap, "OUTPUT_PATH", fake_output)
        self._stub_bst_pipeline(
            monkeypatch,
            elements=["xfce-linux/x.bst"],
            contents={"xfce-linux/x.bst": ["/usr/bin/x"]},
        )
        monkeypatch.setattr(sys, "argv", ["gen-filemap.py", "--dry-run"])

        rc = main()

        assert rc == 0
        assert not fake_output.exists()
        out = capsys.readouterr().out
        parsed = json.loads(out)
        assert parsed == {
            "xfce-linux/x.bst": {"interval": "weekly", "files": ["/usr/bin/x"]}
        }

    def test_writes_filemap_and_manifest(self, monkeypatch, tmp_path):
        fake_output = tmp_path / "files" / "filemap.json"
        monkeypatch.setattr(gen_filemap, "OUTPUT_PATH", fake_output)
        self._stub_bst_pipeline(
            monkeypatch,
            elements=["xfce-linux/x.bst"],
            contents={"xfce-linux/x.bst": ["/usr/bin/x"]},
        )
        monkeypatch.setattr(sys, "argv", ["gen-filemap.py"])

        rc = main()

        assert rc == 0
        written = json.loads(fake_output.read_text())
        assert written == {
            "xfce-linux/x.bst": {"interval": "weekly", "files": ["/usr/bin/x"]}
        }
        manifest = (fake_output.parent / "fakecap-manifest.tsv").read_text()
        assert "/usr/bin/x\txfce-linux/x.bst\tweekly" in manifest

    def test_skips_oci_layers_prefix(self, monkeypatch, tmp_path):
        """oci/layers/* aggregation elements must not appear in the filemap."""
        fake_output = tmp_path / "filemap.json"
        monkeypatch.setattr(gen_filemap, "OUTPUT_PATH", fake_output)
        self._stub_bst_pipeline(
            monkeypatch,
            elements=["xfce-linux/x.bst", "oci/layers/xfce-linux.bst"],
            contents={
                "xfce-linux/x.bst": ["/usr/bin/x"],
                "oci/layers/xfce-linux.bst": ["/usr/bin/x", "/usr/bin/y"],
            },
        )
        monkeypatch.setattr(sys, "argv", ["gen-filemap.py"])

        main()

        written = json.loads(fake_output.read_text())
        assert list(written.keys()) == ["xfce-linux/x.bst"]

    def test_empty_file_lists_are_excluded(self, monkeypatch, tmp_path):
        fake_output = tmp_path / "filemap.json"
        monkeypatch.setattr(gen_filemap, "OUTPUT_PATH", fake_output)
        self._stub_bst_pipeline(
            monkeypatch,
            elements=["xfce-linux/empty.bst"],
            contents={"xfce-linux/empty.bst": []},
        )
        monkeypatch.setattr(sys, "argv", ["gen-filemap.py"])

        main()

        written = json.loads(fake_output.read_text())
        assert written == {}

    def test_custom_target_is_forwarded(self, monkeypatch, tmp_path):
        fake_output = tmp_path / "filemap.json"
        monkeypatch.setattr(gen_filemap, "OUTPUT_PATH", fake_output)
        seen = {}

        def fake_list_elements(target):
            seen["target"] = target
            return []

        monkeypatch.setattr(gen_filemap, "list_elements", fake_list_elements)
        monkeypatch.setattr(gen_filemap, "list_all_contents", lambda els: {})
        monkeypatch.setattr(sys, "argv", ["gen-filemap.py", "--target", "oci/layers/bluefin.bst"])

        main()

        assert seen["target"] == "oci/layers/bluefin.bst"
