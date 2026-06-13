# XFCE Linux

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

**XFCE Wayland OCI image built with BuildStream** — a lightweight, immutable desktop OS image with the XFCE desktop environment.

Part of the [TunaOS](https://tunaos.org) ecosystem.

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

## Docs

- [XFCE Linux on tunaos.org](https://tunaos.org/docs/xfce-linux)
- [Contributing](CONTRIBUTING.md)

## License

Apache 2.0 — see [LICENSE](LICENSE).

