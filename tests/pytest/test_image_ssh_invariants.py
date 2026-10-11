"""Invariants for remote access in the published OS image.

The image enables sshd, so anything this repository writes into the image's
SSH configuration is reachable on every installed machine. These assertions
encode the shape that shipped once and must not come back: a developer
public key committed into the element, and a PermitRootLogin override that
re-enabled root password authentication on top of the empty root password
the image already carries.

Pure source inspection — no build, no container.
"""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
ELEMENTS = REPO / "elements"

# Any element that composes the image, not just the one that regressed.
ELEMENT_FILES = sorted(ELEMENTS.rglob("*.bst"))

PUBKEY_RE = re.compile(
    r"ssh-(?:ed25519|rsa|dss)\s+AAAA[0-9A-Za-z+/=]{20,}|"
    r"ecdsa-sha2-nistp\d+\s+AAAA[0-9A-Za-z+/=]{20,}"
)


def test_no_ssh_public_key_baked_into_any_element():
    """A key committed here is a key in every published image: it cannot be
    rotated or revoked per machine, and whoever holds the private half can
    log in as root everywhere xfce-linux is installed."""
    offenders = []
    for path in ELEMENT_FILES:
        for lineno, line in enumerate(path.read_text().splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue  # prose about this rule is fine
            if PUBKEY_RE.search(line):
                offenders.append(f"{path.relative_to(REPO)}:{lineno}")
    assert not offenders, (
        "SSH public key baked into the image; add keys per deployment "
        f"instead: {offenders}"
    )


def test_no_authorized_keys_written_by_any_element():
    offenders = []
    for path in ELEMENT_FILES:
        for lineno, line in enumerate(path.read_text().splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            if "authorized_keys" in line:
                offenders.append(f"{path.relative_to(REPO)}:{lineno}")
    assert not offenders, (
        f"element writes an authorized_keys file into the image: {offenders}"
    )


def test_no_permit_root_login_yes_override():
    """`PermitRootLogin yes` allows root password authentication. This image
    ships root with an empty password (elements/oci/xfce-linux.bst), so the
    combination is a root login with no credential. OpenSSH's default,
    prohibit-password, still permits a key-based root login."""
    offenders = []
    for path in ELEMENT_FILES:
        for lineno, line in enumerate(path.read_text().splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            if re.search(r"PermitRootLogin\s+yes", line):
                offenders.append(f"{path.relative_to(REPO)}:{lineno}")
    assert not offenders, (
        f"PermitRootLogin yes written into the image: {offenders}"
    )
