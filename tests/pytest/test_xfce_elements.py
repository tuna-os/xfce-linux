"""Unit tests and invariants for XFCE elements built from upstream release tags.

Validates that:
- All XFCE desktop components have dedicated .bst elements in elements/xfce-linux/
- The obsolete prebuilt binary tarball element (xfce-binaries.bst) is retired
- The /var/home/james symlink hack is removed from the stack integration commands
- The xfce-wayland-src symlink is removed from repository root
- All XFCE elements have valid YAML structure, kinds, and sources
- include/aliases.yml contains the xfce alias
- xfwl4 installs the upstream session desktop file
"""

import os
from pathlib import Path
import yaml

REPO = Path(__file__).resolve().parents[2]
ELEMENTS_DIR = REPO / "elements" / "xfce-linux"

EXPECTED_XFCE_ELEMENTS = [
    "xfce4-dev-tools.bst",
    "libxfce4util.bst",
    "xfconf.bst",
    "libxfce4ui.bst",
    "garcon.bst",
    "libxfce4windowing.bst",
    "exo.bst",
    "xfwm4.bst",
    "xfce4-panel.bst",
    "xfce4-session.bst",
    "xfce4-settings.bst",
    "xfdesktop.bst",
    "thunar.bst",
    "tumbler.bst",
    "xfce4-appfinder.bst",
    "xfce4-terminal.bst",
    "xfce4-notifyd.bst",
    "xfce4-power-manager.bst",
    "xfwl4.bst",
]


def test_xfce_binaries_element_retired():
    """xfce-binaries.bst must be deleted (issue #158)."""
    assert not (ELEMENTS_DIR / "xfce-binaries.bst").exists(), (
        "xfce-binaries.bst should be retired and deleted"
    )


def test_xfce_wayland_symlink_retired():
    """xfce-wayland-src symlink must be removed from repo root."""
    assert not (REPO / "xfce-wayland-src").exists(), (
        "xfce-wayland-src symlink should be removed from repository root"
    )


def test_all_expected_xfce_elements_exist():
    """Every component must have a corresponding .bst element."""
    for elem_name in EXPECTED_XFCE_ELEMENTS:
        elem_path = ELEMENTS_DIR / elem_name
        assert elem_path.exists(), f"Missing element: {elem_name}"


def test_all_xfce_elements_valid_yaml_and_sources():
    """Each element must parse as valid YAML with kind, description, and git_repo sources."""
    for elem_name in EXPECTED_XFCE_ELEMENTS:
        elem_path = ELEMENTS_DIR / elem_name
        data = yaml.safe_load(elem_path.read_text())
        assert isinstance(data, dict), f"{elem_name} is not a valid YAML mapping"
        assert "kind" in data, f"{elem_name} missing 'kind'"
        assert "sources" in data, f"{elem_name} missing 'sources'"
        assert len(data["sources"]) >= 1, f"{elem_name} has empty 'sources'"
        first_src = data["sources"][0]
        assert first_src.get("kind") in ["git_repo", "git_module"], (
            f"{elem_name} first source is not git_repo or git_module"
        )
        assert "ref" in first_src, f"{elem_name} missing 'ref'"
        assert "track" in first_src, f"{elem_name} missing 'track'"


def test_xfce_alias_in_aliases_yml():
    """include/aliases.yml must define the xfce git alias."""
    aliases_file = REPO / "include" / "aliases.yml"
    data = yaml.safe_load(aliases_file.read_text())
    assert "aliases" in data
    assert "xfce" in data["aliases"], "xfce alias missing from include/aliases.yml"
    assert "gitlab.xfce.org" in data["aliases"]["xfce"]


def test_no_james_symlink_hack_in_stack():
    """xfce-linux-stack.bst must not contain the /var/home/james symlink hack."""
    stack_path = REPO / "elements" / "oci" / "layers" / "xfce-linux-stack.bst"
    content = stack_path.read_text()
    assert "/var/home/james/dev/xfce-wayland" not in content, (
        "xfce-linux-stack.bst still contains /var/home/james symlink hack"
    )


def test_xfce_cluster_references_all_components():
    """xfce-linux-cluster.bst must depend on all built XFCE components and not xfce-binaries."""
    cluster_path = ELEMENTS_DIR / "xfce-linux-cluster.bst"
    content = cluster_path.read_text()
    assert "xfce-binaries.bst" not in content, "xfce-linux-cluster.bst must not reference xfce-binaries.bst"
    for elem_name in EXPECTED_XFCE_ELEMENTS:
        if elem_name == "xfce4-dev-tools.bst":
            continue  # build-time dependency only
        assert f"xfce-linux/{elem_name}" in content, (
            f"xfce-linux-cluster.bst missing dependency on xfce-linux/{elem_name}"
        )


def test_xfwl4_installs_session_desktop():
    """xfwl4.bst must install xfwl4.desktop and session symlink."""
    xfwl4_path = ELEMENTS_DIR / "xfwl4.bst"
    content = xfwl4_path.read_text()
    assert "xfwl4.desktop" in content
    assert "wayland-sessions" in content
