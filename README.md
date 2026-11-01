# XFCE Linux

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/tuna-os/xfce-linux/blob/main/LICENSE)

**An OCI image with XFCE Wayland, built through BuildStream** — a lightweight
and immutable OS image with the XFCE desktop.

Part of the [TunaOS](https://tunaos.org) ecosystem.
The current codename is **Brussels**. The Xfce Foundation e.V. started at
FOSDEM in Brussels in 2011
([upstream announcement](https://blog.xfce.org/2011/02/xfce-foundation-e-v-launched-at-fosdem/)).

![XFCE Linux wordmark](branding/brussels/xfce-linux-wordmark.svg)

Brussels is the product codename. Its icon and wallpaper are original TunaOS
artwork, not official Xfce Foundation branding.

![Brussels desktop wallpaper preview](branding/brussels/brussels-wallpaper.png)

Icon: [Brussels product mark](branding/brussels/brussels-logo.svg).

<!-- hive-contribute-plea: donated-compute appeal, keep in sync across repos -->
## Contribute compute — no code needed

**[Donate time with your AI CLI](https://hub.tunaos.org/#contribute).**

Your machine runs one task at a time using your signed-in AI coding CLI.
The relay alternates between eligible **School** (OS) and **Reef** (apps)
hives after each task. If one hive has no work, the other can continue.

The guide covers prerequisites, verified `just` setup, credentials, provider
costs, and how to stop with Ctrl+C. Your subscription quota or API charges apply.
Never post account credentials or API keys in issues or pull requests.

## Features

- **Lightweight** — XFCE desktop optimized for low-resource systems
- **Immutable** — OCI-based, atomic updates via `bootc`
- **Wayland** — modern display protocol
- **BuildStream** — reproducible builds from source

## Quick Start

```bash
# Pull the image
podman pull ghcr.io/tuna-os/xfce-linux:latest

# Switch an existing bootc system
sudo bootc switch ghcr.io/tuna-os/xfce-linux:latest
```

## Stable release channel

The release workflow publishes the first stable channel only after all checks
pass. The checks cover the nightly image, matching live ISO, plain install, and
LUKS install. After promotion, use the immutable image at:

```bash
podman pull ghcr.io/tuna-os/xfce-linux:stable
sudo bootc switch ghcr.io/tuna-os/xfce-linux:stable
```

The workflow publishes the stable live ISO and checksum under
`https://pub-<configured-r2-domain>/xfce-linux/stable/`. Their names are
`xfce-linux-live-latest.iso` and `xfce-linux-live-latest.iso-CHECKSUM`.
The promotion workflow verifies both objects before it marks the release as
ready. Thus, downstream download pages can safely use those stable names.

## Verifying Signatures

**OCI images:** Image signature verification is not yet in effect. See [`docs/signing.md`](docs/signing.md) for the implementation plan.

**Live ISO signatures** (`.sig` and `.cert` files accompany each dated ISO,
such as `xfce-linux-live-<date>-<sha>.iso.sig`):

```bash
cosign verify-blob xfce-linux-live-<date>-<sha>.iso \
  --certificate xfce-linux-live-<date>-<sha>.iso.cert \
  --signature xfce-linux-live-<date>-<sha>.iso.sig \
  --certificate-identity-regexp 'https://github.com/tuna-os/xfce-linux/\.github/workflows/build-iso\.yml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Docs

- [XFCE Linux on tunaos.org](https://tunaos.org/docs/xfce-linux)
- [Experimental local Mkosi DDI](docs/mkosi-ddi.md)
- [Contribution guide](CONTRIBUTING.md)

## License

Apache 2.0 — see [LICENSE](https://github.com/tuna-os/xfce-linux/blob/main/LICENSE).
