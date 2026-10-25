"""Invariants across the live-ISO build scripts.

Each assertion here encodes a bug class that actually shipped (see
docs/ci-and-iso-pipeline.md troubleshooting table). Cheap to run, no
containers needed — pure source inspection.
"""

import os
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TARGET = "xfce-linux"
INSTALLER_APP = "org.tunaos.InstallerXfce"
READY_MARKER = "XFCE_LINUX_LIVE_READY"

SRC = REPO / TARGET / "src"
INSTALL_FLATPAKS = (SRC / "install-flatpaks.sh").read_text()
CONFIGURE_LIVE = (SRC / "configure-live.sh").read_text()
CONTAINERFILE = (REPO / TARGET / "Containerfile").read_text()


def test_installer_app_id_consistent():
    """install-flatpaks.sh and configure-live.sh must bake and wire the SAME
    installer app ID — they once drifted apart and the installer never
    launched (autostart + fisherman symlink pointed at an uninstalled app)."""
    assert INSTALLER_APP in INSTALL_FLATPAKS
    assert INSTALLER_APP in CONFIGURE_LIVE
    for stale in ("org.bootcinstaller.Installer", "org.xfceinstaller"):
        assert stale not in INSTALL_FLATPAKS, f"stale installer id {stale} in install-flatpaks.sh"
        assert stale not in CONFIGURE_LIVE.replace(
            # the polkit action id is shared and fine
            "org.tunaos.Installer.install", ""
        ), f"stale installer id {stale} in configure-live.sh"


def test_live_ready_marker_present():
    """CI's boot gate greps the serial log for the ready marker; if
    configure-live.sh stops printing it every ISO 'fails' to boot."""
    assert READY_MARKER in CONFIGURE_LIVE


def test_payload_ref_points_at_our_image():
    ref = (REPO / TARGET / "payload_ref").read_text().strip()
    assert ref.startswith(f"ghcr.io/tuna-os/{TARGET}:"), ref


def test_polkit_action_id_is_shared_constant():
    """All four frontends escalate via the shared action id; renaming it
    breaks every installer at once."""
    assert "org.tunaos.Installer.install" in CONFIGURE_LIVE


def test_fisherman_symlink_target():
    """Frontends run `pkexec /usr/local/bin/fisherman`; the symlink must be
    created and the polkit annotate path must match."""
    assert "/usr/local/bin/fisherman" in CONFIGURE_LIVE
    assert re.search(r"annotate.*exec\.path.*>/usr/local/bin/fisherman<", CONFIGURE_LIVE)


def test_containerfile_wires_this_targets_dracut_module():
    assert f"95{TARGET}-isofile" in CONTAINERFILE
    module_dir = REPO / TARGET / "src" / "dracut" / f"95{TARGET}-isofile"
    assert (module_dir / "module-setup.sh").exists()
    setup = (module_dir / "module-setup.sh").read_text()
    hook = re.search(r'inst_hook initqueue \d+ "\$moddir/([^"]+)"', setup)
    assert hook, "module-setup.sh must install an initqueue hook"
    assert (module_dir / hook.group(1)).exists(), f"hook script {hook.group(1)} missing"


def test_single_root_justfile():
    """just >=1.30 hard-errors when both justfile and Justfile exist — this
    killed every CI invocation once. Extra recipes belong in iso.justfile."""
    assert (REPO / "Justfile").exists()
    assert not (REPO / "justfile").exists(), "second root justfile reintroduced"
    assert 'import "iso.justfile"' in (REPO / "Justfile").read_text()


def test_gitignore_does_not_swallow_target_containerfile():
    """An unanchored 'Containerfile' rule once silently dropped
    <target>/Containerfile from the repo."""
    gitignore = (REPO / ".gitignore").read_text() if (REPO / ".gitignore").exists() else ""
    for line in gitignore.splitlines():
        line = line.strip()
        assert line != "Containerfile", (
            "unanchored Containerfile gitignore rule — use /Containerfile"
        )


def test_no_quiet_karg_in_elements():
    """CI serial-log assertions depend on boot messages; a kargs.d drop-in
    adding 'quiet' would blind every boot gate."""
    for bst in (REPO / "elements").rglob("*.bst"):
        text = bst.read_text()
        if "kargs.d" in text:
            assert '"quiet"' not in text, f"{bst} adds quiet karg"


def test_high_frequency_workflows_cancel_superseded_runs():
    """Push bursts once left stale checks and image/ISO builds queued for
    hours. Newer work on the same ref must replace those obsolete runs."""
    workflows = REPO / ".github" / "workflows"
    names = (
        "test.yml",
        "build-iso.yml",
        "build-and-publish-xfce-linux.yml",
    )
    for name in names:
        text = (workflows / name).read_text()
        assert "concurrency:" in text, f"{name} lacks a concurrency group"
        assert re.search(
            r"^\s*cancel-in-progress:\s*true\s*(?:#.*)?$", text, re.MULTILINE
        ), f"{name} queues superseded same-ref runs"

    iso = (workflows / "build-iso.yml").read_text()
    assert "github.event.workflow_run.head_branch || github.ref_name" in iso, (
        "push and workflow_run ISO triggers must normalize to the same branch key"
    )


def test_scheduled_multirunner_preserves_in_progress_builds():
    """The multi-hour scheduled build must queue instead of discarding work."""
    workflow = (REPO / ".github" / "workflows" / "build-multirunner.yml").read_text()

    assert not re.search(r"^\s*push:\s*(?:#.*)?$", workflow, re.MULTILINE)
    assert re.search(
        r"^\s*cancel-in-progress:\s*false\s*(?:#.*)?$", workflow, re.MULTILINE
    )


def test_r2_publication_requires_boot_and_promotes_image_last():
    """A failed boot must never replace public objects; upload failures are fatal."""
    import yaml

    workflow = yaml.safe_load((REPO / '.github/workflows/build-iso.yml').read_text())
    steps = next(job['steps'] for job in workflow['jobs'].values() if 'steps' in job)
    boot = next(i for i, step in enumerate(steps) if step.get('name') == 'Boot verification (UEFI + serial)')
    assert not steps[boot].get('continue-on-error', False)
    uploads = [(i, step) for i, step in enumerate(steps) if 'rclone copyto' in step.get('run', '')]
    assert uploads
    for index, step in uploads:
        assert index > boot
        assert not step.get('continue-on-error', False)
        assert step['if'] == "${{ inputs.skip_upload != true && github.event_name != 'pull_request' }}"
        run = step['run']
        writes = re.findall(r'rclone copyto.*?(?=\n\s*(?:rclone|#)|\Z)', run, re.S)
        assert len(writes) == 8  # dated and latest ISO, checksum, signature, certificate
        assert '/${DATED}.cert"' in writes[3]
        assert 'xfce-linux-live-latest.iso-CHECKSUM"' in writes[4]
        assert 'xfce-linux-live-latest.iso.sig"' in writes[5]
        assert 'xfce-linux-live-latest.iso.cert"' in writes[6]
        assert writes[-1].rstrip().endswith('/xfce-linux-live-latest.iso"')
