# XFCE Linux — Documentation Index

This directory holds documentation that is either infrastructure-focused
(signing, CI/ISO pipeline, ADRs) or archival (dated session reports). For
project overview, build/run instructions, and current status, start with the
top-level docs instead:

- **[../README.md](../README.md)** — what this image is, how to pull/build
  it, the stable release channel, and signature verification.
- **[../AGENTS.md](../AGENTS.md)** — architecture summary, `just` commands,
  and known issues for anyone (human or agent) working on this repo.
- **[../CONTRIBUTING.md](../CONTRIBUTING.md)** — contributor workflow and
  development setup.

## In this directory

- **[ci-and-iso-pipeline.md](ci-and-iso-pipeline.md)** — the full CI →
  image → ISO chain and its troubleshooting log. Update this when you fix a
  CI/ISO bug (see AGENTS.md's CI gate rules).
- **[signing.md](signing.md)** — cosign image signing.
- **[adr/](adr/)** — architecture decision records (e.g.
  [0001-wayland-greeter.md](adr/0001-wayland-greeter.md)).
- **[technical/](technical/)** and **[reference/](reference/)** — dated
  session reports from early development (May–August 2026), kept for
  history. Each file is marked `ste-disable-file` and describes the state
  at a specific time, not current state. Metrics, "Known Issues," or
  completion percentages in these files are not live. The top-level README
  and AGENTS.md reflect what actually ships today.
