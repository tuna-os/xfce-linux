# Fix for #78: Multi-Runner chunk hang / image publish

## Root Cause Analysis

The multi-runner chunk jobs time out on 2-core GitHub-hosted runners after
270 minutes (the budget). The chunks' build step exits with code 124 (timeout),
which is NOT softened for chunks in the reusable workflow (`tuna-os/bst-ci`),
unlike `build_core` which has `soft_core_budget: true`.

When chunks fail with timeout, the `multirunner` reusable workflow reports
`failure`. The caller's `build_final` job has:
```yaml
if: always() && !contains(needs.*.result, 'failure') && !contains(needs.*.result, 'cancelled')
```
This skips `build_final` entirely, so the image is never published.

## Changes Required

### 1. `build-multirunner.yml` (this repo) — relax build_final gate

```diff
-    if: always() && !contains(needs.*.result, 'failure') && !contains(needs.*.result, 'cancelled')
+    # Allow build_final to run even when chunks failed (including budget
+    # timeouts), because chunks always push their partial CAS on timeout
+    # via if: always().  Skipping build_final on chunk failure guarantees
+    # the image is never published.  If chunks had genuine build errors
+    # (not timeouts), build_final will also fail — which is correct.
+    #
+    # We still skip on cancelled: a cancelled run means CAS pushes may
+    # not have completed, so the final assembly would start from a
+    # half-written cache.
+    if: always() && !contains(needs.*.result, 'cancelled')
```

### 2. `build-multirunner.yml` — pass runner_label from repo vars

```diff
       image_name: xfce-linux
       bst_target: oci/xfce-linux.bst
       num_chunks: ${{ inputs.num_chunks || '10' }}
       core_split: "200"
+      runner_label: ${{ vars.ACTIONS_RUNNER_LABEL || 'ubuntu-24.04' }}
```

### 3. `tuna-os/bst-ci` (upstream reusable workflow) — soften chunk budget timeouts

The chunk build step in `multirunner-build.yml` needs a `soft_chunk_budget`
parameter (analogous to `soft_core_budget`). When a chunk exhausts its
270-minute budget, exit code 124 should be reset to 0 so the chunk job
reports success (its partial CAS is already pushed via `if: always()`).

## Why This Wasn't Pushed Directly

The scanner agent's GitHub App token lacks the `workflows` permission,
which GitHub requires for pushing changes to `.github/workflows/` files.
This is a separate infrastructure issue.
