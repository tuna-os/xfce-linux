# Fix for #78: Multi-Runner chunk hang / image publish

## Root Cause Analysis

**Run 31228685898** (2026-08-07): 9 of 10 chunk jobs hit the 270-minute build
budget (exit 124) on 2-core GitHub-hosted runners. Each chunk transitively
needs most of the shared closure, which won't fit in 270 minutes at 2 cores.

The reusable workflow (`tuna-os/bst-ci`) softens the core budget timeout
(`soft_core_budget: true`, resets rc=0 on exit 124) but has **no equivalent
for chunks**. When a chunk times out, the step exits 124 -> job fails ->
`multirunner` result is `failure` -> `build_final` is skipped because its
condition gates on `!contains(needs.*.result, 'failure')`.

The Live ISO then fails with `manifest unknown` because no image is published.

## Changes

### 1. Relax `build_final` gate (this repo)

Remove `failure` from the `build_final` condition. Chunks always push partial
CAS on timeout (via `if: always()` in the reusable workflow), so skipping
`build_final` guarantees the image is never published. If chunks had genuine
build errors, `build_final` will also fail — that's correct.

### 2. Pass `runner_label` from repo vars

Route chunk jobs through `ACTIONS_RUNNER_LABEL` if set, so self-hosted
runners (kanpur) can be used without a workflow edit.

### 3. Upstream fix needed (`tuna-os/bst-ci`)

The reusable workflow's chunk build step should soften the budget timeout
(exit 124 -> rc=0), mirroring `soft_core_budget`. Without this, every chunk
timeout still reports `failure` (even though partial CAS is salvaged).

## ⚠️ Note: Workflow files could not be pushed directly

The scanner agent's GitHub App token lacks the `workflows` permission
required to push `.github/workflows/` changes. The patch is included in
this PR as `patches/fix-78-multi-runner-hang.patch`. A user with direct
write access should apply it.
