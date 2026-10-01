#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
mode="${1:-state}"
batch="${2:-state-$(date +%s)-$$}"
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Invalid batch name' >&2; exit 2 ;; esac
log_root="$repo_root/tools/runtime-intake/check-runs/factory-statistics-v1/$batch"
mkdir -p "$log_root"
case "$mode" in
  state)
    "$godot_bin" --headless --path "$repo_root/client" --script res://scripts/checks/factory_statistics_check.gd --no-header --log-file "$log_root/state.log"
    ;;
  write|read|ui)
    if [ "$#" -lt 2 ]; then echo 'Window checks require an explicit batch name' >&2; exit 2; fi
    if [ "$mode" = read ]; then set -- --read; elif [ "$mode" = ui ]; then set -- --ui-only; else set --; fi
    "$godot_bin" --path "$repo_root/client" --script res://scripts/checks/factory_statistics_boot_check.gd --no-header --log-file "$log_root/$mode.log" -- "--batch=$batch" "$@"
    ;;
  *) echo 'Usage: sh tools/check-factory-statistics.sh [state|ui|write|read] [batch]' >&2; exit 2 ;;
esac
if rg '^(SCRIPT ERROR|ERROR:)' "$log_root/$mode.log" | rg -v 'Condition "ret != noErr"' >/dev/null; then
  echo "Statistics $mode check reported errors: $log_root/$mode.log" >&2
  exit 1
fi
echo "Factory statistics $mode check completed."
