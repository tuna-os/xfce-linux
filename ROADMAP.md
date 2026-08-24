# XFCE Linux Roadmap

**Last updated**: 2026-08-24 | **Status**: Alpha → Beta (gate in progress, #105/#106)

Part of the [TunaOS](https://tunaos.org) ecosystem. Lightweight XFCE Wayland
OCI image built with BuildStream — the low-resource desktop entry point.

---

## Current Status (August 2026)

- **Active development** — 96+ commits since the last ROADMAP update (06-13);
  scheduled multi-runner builds, live-ISO, and stable-promotion pipelines in
  place; BuildStream dashboard parser + failure-dedup coverage landed 08-23/24.
- **Distribution**: `ghcr.io/tuna-os/xfce-linux:latest` exists, but **zero
  GitHub Releases and zero tags** — no digest-addressable stable artifact,
  no checksums, no signatures (see #105).
- **Gate status**: outcome-based Alpha→Beta gate being defined in #106;
  release outcome untracked until a tagged release exists (#105).

### Priorities

| Priority | Item | Tracking | Status |
|----------|------|----------|--------|
| P0 | First release outcome — tagged OCI + ISO + checksum/signature together | #105 | 🔴 No release yet |
| P1 | Define Alpha→Beta gate criteria | #106 | 🟡 Open |
| P1 | Scheduled builds reliably green (multi-runner, live-ISO) | (nightly) | 🟡 Flaky |
| P2 | ROADMAP freshness — this document updated 08-24 | (org #1997) | ✅ Done |

---

## Alpha → Beta (outcome-based)

Gate exits when all are evidenced together (per #105):

- Scheduled multi-runner build publishes a digest-addressable OCI image.
- Matching live ISO, checksum, signature, and certificate are published.
- Plain-install and LUKS-install paths verified on a published artifact.

## Planned

- **XFCE 4.20+** — track latest XFCE releases.
- **Flatpak integration** — Flathub preconfigured.
- **Hardware variants** — HWE kernel, ARM64.

## Contributing

See CONTRIBUTING.md. Strategic planning tracked by strategist agent
(#105/#106); implementation by the org hive lanes.

---

*ROADMAP refreshed by strategist agent (ACMM L6 — full mode). Signed-off-by: hanthor-hive-agent[bot] <290068839+hanthor-hive-agent[bot]@users.noreply.github.com>*
