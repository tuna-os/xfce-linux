# XFCE Linux Roadmap

**Last updated**: 2026-09-17 | **Status**: Alpha — Beta release gate verification in progress

Part of the [TunaOS](https://tunaos.org) ecosystem. XFCE Linux is the
lightweight XFCE Wayland OCI image, built from source with BuildStream.

## Current strategic focus

The near-term goal is one reproducible, installable Beta release. Release
readiness is measured by a promoted outcome, not by the presence of workflows
or the closure of implementation issues.

As of September 2026, CI image signing has migrated to static cosign keys (#164). Scheduled
multi-runner image builds and live-ISO verification pipelines are undergoing final Q4 audit,
moving the project toward its first tagged Beta release once all exit gates are satisfied.

## Alpha → Beta release gate

All evidence below must refer to the same candidate commit. The release tracker
stays open until every row is evidenced.

| Outcome | Exit evidence | Status (2026-09-17) |
| --- | --- | --- |
| Reproducible OCI image | A scheduled multi-runner build publishes an image and records its immutable digest | In progress — cosign key signing enabled (#164) |
| Matching live media | ISO, checksum, signature, and certificate are published for the candidate | In progress — downstream ISO pipeline verification |
| Install validation | Plain and LUKS install E2E checks pass against the candidate | In progress — E2E install test suite execution |
| Stable promotion | `stable` resolves to the candidate digest and the promotion workflow verifies the image and ISO objects | Blocked on build and install gates |
| Discoverable release | A GitHub Release records the digest, signed artifact URLs, known limitations, and upgrade path | Planned for Q4 2026 Beta tag |
| User-path validation | The public install guide is followed successfully against the promoted candidate | Planned following release candidate |

The first five rows are release blockers. User-path validation may be completed
with a release candidate, but must be recorded before Beta is announced.

## Operating cadence

- Review the release gate weekly while any blocker is red.
- Link each row to a durable workflow run, digest, artifact, or documentation
  check in the release tracker.
- Reopen the release tracker when evidence regresses before promotion.
- Do not count workflow implementation or a single isolated green job as a
  completed release outcome.

## After the first Beta

1. Publish a documented release cadence and support window.
2. Track XFCE and base-runtime currency with upgrade-test evidence.
3. Validate the lightweight positioning with boot-time, memory, and image-size
   measurements against at least one mainstream TunaOS desktop.
4. Evaluate HWE and ARM64 only after the Beta release gate is repeatable; each
   additional hardware target must include an owner and ongoing CI capacity.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
