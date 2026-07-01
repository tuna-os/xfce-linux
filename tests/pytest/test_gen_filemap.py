"""Unit tests for scripts/gen-filemap.py pure functions.

Tests the helper functions isolated from BST/subprocess calls:
- strip_ansi() — ANSI escape code removal
- guess_interval() — update interval heuristic
"""

import importlib.util
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# Load gen-filemap.py as a module (filename has hyphen, so importlib is needed)
MODULE_PATH = PROJECT_ROOT / "scripts" / "gen-filemap.py"
spec = importlib.util.spec_from_file_location("gen_filemap", MODULE_PATH)
gen_filemap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen_filemap)

strip_ansi = gen_filemap.strip_ansi
guess_interval = gen_filemap.guess_interval


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
