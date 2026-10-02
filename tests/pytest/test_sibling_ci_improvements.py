"""Tests for sibling CI and packaging improvements adopted from sibling repos (issue #165)."""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def test_project_conf_fatal_warnings():
    """project.conf must enforce fatal-warnings on overlaps, unaliased-url, and unstaged-files."""
    content = (REPO / "project.conf").read_text()
    assert "fatal-warnings:" in content
    assert "- overlaps" in content
    assert "- unaliased-url" in content
    assert "- unstaged-files" in content


def test_project_conf_connection_config():
    """project.conf artifacts and source-caches must configure connection-config timeouts and retries."""
    content = (REPO / "project.conf").read_text()
    assert "artifacts:" in content
    assert "source-caches:" in content
    assert content.count("connection-config:") >= 2
    assert "keepalive-time: 180" in content
    assert "retry-limit: 5" in content
    assert "retry-delay: 500" in content
    assert "request-timeout: 180" in content


def test_project_conf_includes_image_version():
    """project.conf must include include/image-version.yml under variables."""
    content = (REPO / "project.conf").read_text()
    assert "include/image-version.yml" in content
    var_match = re.search(r"variables:\s*\n\s*\(@\):[\s\S]*?- include/image-version\.yml", content)
    assert var_match is not None, "variables section must include include/image-version.yml"


def test_image_version_file():
    """include/image-version.yml must define expected defaults."""
    content = (REPO / "include" / "image-version.yml").read_text()
    assert "branch:" in content
    assert "image-version:" in content
    assert "commit:" in content
    assert "commit-date-pretty:" in content


def test_generate_image_version_recipe():
    """just/buildstream.just must provide the generate-image-version recipe."""
    content = (REPO / "just" / "buildstream.just").read_text()
    assert "generate-image-version" in content
    assert "include/image-version.yml" in content


def test_os_release_uses_image_version():
    """elements/oci/os-release.bst must use %{image-version}."""
    oci_os_release = (REPO / "elements" / "oci" / "os-release.bst").read_text()
    assert 'VERSION_ID="%{image-version}"' in oci_os_release or 'VERSION_ID: "%{image-version}"' in oci_os_release
    assert 'IMAGE_VERSION="%{image-version}"' in oci_os_release or 'IMAGE_VERSION: "%{image-version}"' in oci_os_release


def test_track_sources_workflow():
    """track-bst-sources.yml must include tag refresh and regression checks."""
    content = (REPO / ".github" / "workflows" / "track-bst-sources.yml").read_text()
    assert "Refresh tags in BST source mirrors" in content
    assert "Detect ref regressions" in content
    assert "Capture pre-track refs" in content


def test_project_conf_does_not_pin_branch():
    """project.conf must not set branch itself: the including file wins, so a
    value there would hide the branch generate-image-version writes."""
    content = (REPO / "project.conf").read_text()
    assert re.search(r"^\s+branch:", content, re.MULTILINE) is None


def test_image_builds_stamp_image_version():
    """Every workflow that builds the published image must regenerate
    include/image-version.yml first, or os-release ships the l.1 placeholder."""
    for name in ("build-multirunner.yml", "build-and-publish-xfce-linux.yml"):
        content = (REPO / ".github" / "workflows" / name).read_text()
        stamp = content.find("just generate-image-version")
        build = content.find("just bst ")
        assert stamp != -1, f"{name} never runs generate-image-version"
        assert stamp < build, f"{name} stamps the version after building"
        assert "OCI_IMAGE_VERSION: ${{ steps.version.outputs.version }}" in content
