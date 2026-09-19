# XFCE Linux Roadmap

**Last updated**: 2026-09-17 | **Status**: Alpha — Q4 2026 release target active

Part of the [TunaOS](https://tunaos.org) ecosystem. XFCE Linux is the
lightweight XFCE Wayland OCI image, built from source with BuildStream.

## Current strategic focus

The near-term goal is one reproducible, installable Beta release in Q4 2026. Release
readiness is measured by a promoted outcome, not by the presence of workflows
or the closure of implementation issues.

As of September 2026, scheduled multi-runner image builds and downstream live-ISO runs
are being stabilized under the Q4 release push. The stable-promotion pipeline will be
triggered as soon as all gate criteria pass against a single release candidate commit.

## Alpha → Beta release gate

All evidence below must refer to the same candidate commit. The release tracker
stays open until every row is evidenced.

| Outcome | Exit evidence | Status (2026-09-17) |
| --- | --- | --- |
| Reproducible OCI image | A scheduled multi-runner build publishes an image and records its immutable digest | In progress — multi-runner build matrix undergoing stabilization |
| Matching live media | ISO, checksum, signature, and certificate are published for the candidate | In progress — downstream live-ISO pipeline validation |
| Install validation | Plain and LUKS install E2E checks pass against the candidate | In progress — test harness coverage active |
| Stable promotion | `stable` resolves to the candidate digest and the promotion workflow verifies the image and ISO objects | Blocked on build and install gates |
| Discoverable release | A GitHub Release records the digest, signed artifact URLs, known limitations, and upgrade path | Planned for Q4 2026 Beta release |
| User-path validation | The public install guide is followed successfully against the promoted candidate | Planned following release candidate promotion |

The first five rows are release blockers. User-path validation may be completed
with a release candidate, but must be recorded before Beta is announced.

## Operating cadence

- Review the release gate weekly while any blocker is red.
- Link each row to a durable workflow run, digest, artifact, or documentation
  check in the release tracker.
- Reopen the release tracker when evidence regresses before promotion.
- Do not count workflow implementation or a single isolated green job as a
  completed release outcome.

## Q4 2026 / Q1 2027 Strategic Objectives

1. **Q4 2026 Beta Milestone**: Complete Alpha-to-Beta release gate verification and publish initial Beta ISO artifacts.
2. **Performance Benchmarking**: Validate lightweight positioning with boot-time, memory footprint, and image-size metrics compared to GNOME/KDE variants.
3. **Q1 2027 General Availability**: Establish documented release cadence, automated dependency currency checks, and stable upgrade pathways.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
