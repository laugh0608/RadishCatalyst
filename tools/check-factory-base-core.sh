#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
mode="${1:-state}"
batch="${2:-$mode-$(date +%s)-$$}"
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Invalid batch name' >&2; exit 2 ;; esac
case "$mode" in
  state) set -- --headless --script res://scripts/checks/factory_base_core_check.gd --quit-after 600 ;;
  window|framing|play|empty-yard) set -- --script res://scripts/checks/factory_base_core_boot_check.gd ;;
  *) echo 'Usage: sh tools/check-factory-base-core.sh [state|window|framing|play|empty-yard] [batch]' >&2; exit 2 ;;
esac
run_root="$repo_root/tools/runtime-intake/check-runs/factory-base-core-v1/$batch"
mkdir -p "$(dirname "$run_root")"
if ! mkdir "$run_root"; then echo 'Use a new batch; existing evidence is retained.' >&2; exit 2; fi
set -- "$@" --log-file "$run_root/run.log" -- "--batch=$batch"
case "$mode" in
  framing) set -- "$@" --framing ;;
  play) set -- "$@" --play ;;
  empty-yard) set -- "$@" --play --empty-yard ;;
esac
status=0
"$godot_bin" --path "$repo_root/client" "$@" > "$run_root/console.log" 2>&1 || status=$?
tail -n 32 "$run_root/console.log"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q '^(SCRIPT ERROR|ERROR:)' "$run_root/console.log" "$run_root/run.log"; then
  echo "Godot reported errors: $run_root" >&2
  exit 1
fi
case "$mode" in
  state) rg -q '^Factory core state:' "$run_root/run.log" ;;
  window|framing) test -f "$run_root/window-result.json" ;;
esac
