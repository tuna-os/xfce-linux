#!/usr/bin/env bats
# Tests for the genmon migration script at files/xfce-binaries/install/usr/share/xfce4/genmon/scripts/migrate_to_xfconf.sh

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  SCRIPT="${REPO_ROOT}/files/xfce-binaries/install/usr/share/xfce4/genmon/scripts/migrate_to_xfconf.sh"
}

@test "migrate_to_xfconf.sh: exists" {
  run test -f "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "migrate_to_xfconf.sh: has shell shebang" {
  run head -1 "$SCRIPT"
  [[ "$output" =~ ^#!/.*sh ]]
}

@test "migrate_to_xfconf.sh: shows usage with no arguments" {
  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" =~ Usage ]]
}

@test "migrate_to_xfconf.sh: show subcommand runs successfully" {
  run bash "$SCRIPT" show
  [ "$status" -eq 0 ]
}

@test "migrate_to_xfconf.sh: help text lists show and doit" {
  run bash "$SCRIPT"
  [[ "$output" =~ show ]]
  [[ "$output" =~ doit ]]
}

@test "migrate_to_xfconf.sh: passes shellcheck" {
  run shellcheck -S error --exclude=SC1091,SC2045 "$SCRIPT"
  [ "$status" -eq 0 ]
}
