#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
mode="${1:-state}"
batch="${2:-$mode-$(date +%s)-$$}"
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Invalid batch name' >&2; exit 2 ;; esac
case "$mode" in state|window|play) ;; *) echo 'Usage: sh tools/check-factory-integrated-c.sh [state|window|play] [batch]' >&2; exit 2 ;; esac
if [ "$mode" = play ]; then
  batch="${2:-current}"
  run_root="$repo_root/tools/runtime-intake/review-worlds/factory-integrated-c-v1/$batch"
  mkdir -p "$run_root"
else
  run_root="$repo_root/tools/runtime-intake/check-runs/factory-integrated-c-v1/$batch"
  mkdir -p "$(dirname "$run_root")"
  if ! mkdir "$run_root"; then echo 'Use a new batch; existing evidence is retained.' >&2; exit 2; fi
fi
run_godot() {
  stage="$1"
  shift
  status=0
  "$godot_bin" --path "$repo_root/client" --log-file "$run_root/$stage.log" "$@" > "$run_root/$stage-console.log" 2>&1 || status=$?
  tail -n 42 "$run_root/$stage-console.log"
  if [ "$status" -ne 0 ]; then exit "$status"; fi
  if rg -q '^(SCRIPT ERROR|ERROR:)' "$run_root/$stage-console.log" "$run_root/$stage.log"; then exit 1; fi
}
case "$mode" in
  state)
    run_godot write --headless --quit-after 600 --script res://scripts/checks/factory_fixed_burn_check.gd -- "--batch=$batch"
    rg -q '^Factory integrated C write:' "$run_root/write.log"
    run_godot read --headless --quit-after 600 --script res://scripts/checks/factory_fixed_burn_check.gd -- "--batch=$batch" --read
    rg -q '^Factory integrated C read:' "$run_root/read.log"
    ;;
  window)
    run_godot window --script res://scripts/checks/factory_fixed_burn_boot_check.gd -- "--batch=$batch" --window
    test -f "$run_root/window-result.json"
    ;;
  play)
    run_godot "play-$(date +%s)-$$" --script res://scripts/checks/factory_fixed_burn_boot_check.gd -- "--batch=$batch" --play
    ;;
esac
