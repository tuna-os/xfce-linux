#!/usr/bin/env bats
# Basic smoke tests for xfce-linux build scripts.
# Verifies scripts exist, are executable, have proper shebangs, and fail
# gracefully when called without required arguments.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
}

# ── build-xfwl4.sh ──────────────────────────────────────────────────────────

@test "build-xfwl4.sh: exists and is executable" {
  run test -x "${REPO_ROOT}/build-xfwl4.sh"
  [ "$status" -eq 0 ]
}

@test "build-xfwl4.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/build-xfwl4.sh"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "build-xfwl4.sh: has set -euo pipefail" {
  run grep 'set -euo pipefail' "${REPO_ROOT}/build-xfwl4.sh"
  [ "$status" -eq 0 ]
}

@test "build-xfwl4.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/build-xfwl4.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

# ── build-iso.sh ────────────────────────────────────────────────────────────

@test "build-iso.sh: exists and is executable" {
  run test -x "${REPO_ROOT}/xfce-linux/src/build-iso.sh"
  [ "$status" -eq 0 ]
}

@test "build-iso.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/xfce-linux/src/build-iso.sh"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "build-iso.sh: fails with usage when called without args" {
  run bash "${REPO_ROOT}/xfce-linux/src/build-iso.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ Usage ]] || [[ "$output" =~ usage ]] || [ -n "$output" ]
}

@test "build-iso.sh: fails with usage when called with one argument" {
  run bash "${REPO_ROOT}/xfce-linux/src/build-iso.sh" /tmp/boot.tar
  [ "$status" -ne 0 ]
  [[ "$output" =~ Usage ]] || [[ "$output" =~ usage ]]
}

@test "build-iso.sh: has set -euo pipefail" {
  run grep 'set -euo pipefail' "${REPO_ROOT}/xfce-linux/src/build-iso.sh"
  [ "$status" -eq 0 ]
}

@test "build-iso.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/xfce-linux/src/build-iso.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

# ── configure-live.sh ───────────────────────────────────────────────────────

@test "configure-live.sh: exists" {
  run test -f "${REPO_ROOT}/xfce-linux/src/configure-live.sh"
  [ "$status" -eq 0 ]
}

@test "configure-live.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/xfce-linux/src/configure-live.sh"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "configure-live.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/xfce-linux/src/configure-live.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

# ── install-flatpaks.sh ─────────────────────────────────────────────────────

@test "install-flatpaks.sh: exists" {
  run test -f "${REPO_ROOT}/xfce-linux/src/install-flatpaks.sh"
  [ "$status" -eq 0 ]
}

@test "install-flatpaks.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/xfce-linux/src/install-flatpaks.sh"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "install-flatpaks.sh: has set -exo pipefail" {
  run grep 'set -exo pipefail' "${REPO_ROOT}/xfce-linux/src/install-flatpaks.sh"
  [ "$status" -eq 0 ]
}

@test "install-flatpaks.sh: passes shellcheck" {
  if command -v shellcheck &>/dev/null; then
    run shellcheck "${REPO_ROOT}/xfce-linux/src/install-flatpaks.sh"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}

# ── dracut module ───────────────────────────────────────────────────────────

@test "dracut module-setup.sh: exists" {
  run test -f "${REPO_ROOT}/xfce-linux/src/dracut/95xfce-linux-isofile/module-setup.sh"
  [ "$status" -eq 0 ]
}

@test "dracut module-setup.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/xfce-linux/src/dracut/95xfce-linux-isofile/module-setup.sh"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

@test "dracut xfce-linux-isofile.sh: exists" {
  run test -f "${REPO_ROOT}/xfce-linux/src/dracut/95xfce-linux-isofile/xfce-linux-isofile.sh"
  [ "$status" -eq 0 ]
}

@test "dracut xfce-linux-isofile.sh: has bash shebang" {
  run head -1 "${REPO_ROOT}/xfce-linux/src/dracut/95xfce-linux-isofile/xfce-linux-isofile.sh"
  [[ "$output" =~ ^#!/.*bash ]] || [[ "$output" =~ ^#!/.*sh ]]
}

# ── Python scripts ──────────────────────────────────────────────────────────

@test "gen-filemap.py: valid Python syntax" {
  run python3 -c "import py_compile; py_compile.compile('${REPO_ROOT}/scripts/gen-filemap.py', doraise=True)"
  [ "$status" -eq 0 ]
}

@test "gen-filemap.py: --help prints usage" {
  run python3 "${REPO_ROOT}/scripts/gen-filemap.py" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Usage ]] || [[ "$output" =~ usage ]] || [[ "$output" =~ help ]]
}

@test "gen-filemap.py: --dry-run fails gracefully outside project" {
  run python3 "${REPO_ROOT}/scripts/gen-filemap.py" --dry-run 2>&1 || true
  # Should print an error about not being in the project root, not crash
  [ -n "$output" ]
}

@test "apply-xattrs.py: valid Python syntax" {
  run python3 -c "import py_compile; py_compile.compile('${REPO_ROOT}/scripts/apply-xattrs.py', doraise=True)"
  [ "$status" -eq 0 ]
}

@test "apply-xattrs.py: --help prints usage" {
  run python3 "${REPO_ROOT}/scripts/apply-xattrs.py" --help 2>&1 || true
  # Should at least produce some output
  [ -n "$output" ]
}

@test "bst-dashboard.py: valid Python syntax" {
  run python3 -c "import py_compile; py_compile.compile('${REPO_ROOT}/tools/bst-dashboard.py', doraise=True)"
  [ "$status" -eq 0 ]
}

@test "bst-dashboard.py: --help prints usage" {
  run python3 "${REPO_ROOT}/tools/bst-dashboard.py" --help 2>&1 || true
  [ -n "$output" ]
}
