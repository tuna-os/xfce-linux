"""Invariants for OCI layer composition and GNOME stack omission.

Asserts that XFCE Linux composes a single standalone OCI layer without
parent base image, without GNOME OS stack bloat, without GNOME Shell/GDM,
and without live-ISO convenience hacks in the installed stack.
"""

from pathlib import Path
import yaml

REPO = Path(__file__).resolve().parents[2]
ELEMENTS = REPO / "elements"


def test_oci_xfce_linux_has_no_parent():
    """elements/oci/xfce-linux.bst must build a single OCI layer with no parent:."""
    content = (ELEMENTS / "oci/xfce-linux.bst").read_text()
    data = yaml.safe_load(content)

    assert data["kind"] == "script"
    # Ensure no parent location is mapped in build-depends
    for dep in data.get("build-depends", []):
        if isinstance(dep, dict) and "config" in dep:
            assert dep["config"].get("location") != "/parent", (
                "elements/oci/xfce-linux.bst must not map a /parent build dependency"
            )
            assert "gnomeos/image.bst" not in dep.get("filename", "")

    # Ensure build-oci command heredoc does not contain a parent: block
    assert "parent:" not in content, "elements/oci/xfce-linux.bst build-oci must have no parent:"
    assert "layer: /layer" in content, "elements/oci/xfce-linux.bst must specify layer: /layer"


def test_xfce_linux_stack_clean_integration_commands():
    """elements/oci/layers/xfce-linux-stack.bst must not contain live-ISO hacks or GDM/GNOME setup."""
    content = (ELEMENTS / "oci/layers/xfce-linux-stack.bst").read_text()
    data = yaml.safe_load(content)

    assert data["kind"] == "stack"
    # Must not depend on gnomeos/stack.bst
    for dep in data.get("depends", []):
        assert "oci/gnomeos/stack.bst" not in dep, (
            "xfce-linux-stack.bst must not depend on oci/gnomeos/stack.bst"
        )

    # Must include our hand-picked stack deps, os-release, initramfs, bootc
    depends_str = " ".join(str(d) for d in data.get("depends", []))
    assert "xfce-linux/deps.bst" in depends_str
    assert "oci/os-release.bst" in depends_str
    assert "linux-firmware.bst" in depends_str
    assert "bootc.bst" in depends_str
    assert "oci/initramfs.bst" in depends_str

    # Must NOT bake live-ISO conveniences into the OS stack
    assert "james@karnataka" not in content, "personal ssh public key must not be in OS stack"
    assert "PermitRootLogin" not in content, "PermitRootLogin must not be in OS stack"
    assert "systemctl enable sshd" not in content, "sshd enable must not be in OS stack"
    assert "xfce-wayland/install" not in content, "symlink hack must not be in OS stack"
    assert "custom.conf" not in content, "GDM custom.conf must not be in OS stack"
    assert "systemctl enable gdm" not in content, "GDM enable must not be in OS stack"


def test_deps_handpicked_os_services_omits_gnome_bloat():
    """elements/xfce-linux/deps.bst must hand-pick OS services and omit GNOME shell/apps/sdk."""
    content = (ELEMENTS / "xfce-linux/deps.bst").read_text()
    data = yaml.safe_load(content)
    deps_list = data.get("depends", [])

    # Must NOT pull GNOME OS umbrella deps or shell/apps/sdk metas
    for dep in deps_list:
        if isinstance(dep, str):
            assert "gnomeos-deps/deps.bst" not in dep, (
                "deps.bst must not depend on gnomeos-deps/deps.bst umbrella stack"
            )
            assert "meta-gnome-core-shell.bst" not in dep, "GNOME Shell must be omitted"
            assert "meta-gnome-core-apps.bst" not in dep, "GNOME core apps must be omitted"
            assert "sdk-platform.bst" not in dep, "GNOME SDK platform must be omitted"
            assert "xdg-desktop-portal-gnome.bst" not in dep, "GNOME portal backend must be omitted"

    # Must pull hand-picked OS services
    depends_str = " ".join(str(d) for d in deps_list)
    assert "core-deps/NetworkManager.bst" in depends_str
    assert "core-deps/accountsservice.bst" in depends_str
    assert "core-deps/upower.bst" in depends_str
    assert "core-deps/fwupd.bst" in depends_str
    assert "core-deps/xdg-desktop-portal-gtk.bst" in depends_str
    assert "pipewire-daemon.bst" in depends_str
    assert "wireplumber.bst" in depends_str
    assert "core/systemd-presets.bst" in depends_str
    assert "gnomeos-deps/preset-all.bst" in depends_str


def test_xfce_cluster_gtk_dependencies():
    """elements/xfce-linux/xfce-linux-cluster.bst should keep GTK3 and not pull GTK4."""
    content = (ELEMENTS / "xfce-linux/xfce-linux-cluster.bst").read_text()
    data = yaml.safe_load(content)
    deps_str = " ".join(str(d) for d in data.get("depends", []))
    assert "freedesktop-sdk.bst:components/gtk3.bst" in deps_str
    assert "gnome-build-meta.bst:sdk/gtk.bst" not in deps_str


def test_no_dead_meta_xfce_core_apps():
    """elements/core/meta-xfce-core-apps.bst should not exist after dropping the junction override."""
    assert not (ELEMENTS / "core/meta-xfce-core-apps.bst").exists()
    assert not (ELEMENTS / "core").exists()
    gnome_meta_conf = (ELEMENTS / "gnome-build-meta.bst").read_text()
    assert "meta-gnome-core-apps.bst" not in gnome_meta_conf
