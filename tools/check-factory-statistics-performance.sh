#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
mode="${1:-}"
batch="${2:-}"
source_snapshot="${3:-}"
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'An explicit unique batch is required' >&2; exit 2 ;; esac
case "$mode" in prepare|window) ;; *) echo 'Usage: sh tools/check-factory-statistics-performance.sh prepare|window <batch> <absolute-source-snapshot>' >&2; exit 2 ;; esac
case "$source_snapshot" in "$repo_root"/tools/runtime-intake/*) ;; *) echo 'Source must be inside repository runtime-intake' >&2; exit 2 ;; esac
[ -f "$source_snapshot" ] || { echo 'Source snapshot not found' >&2; exit 2; }
log_root="$repo_root/tools/runtime-intake/check-runs/factory-statistics-v1/$batch"
[ ! -e "$log_root" ] || { echo 'Batch already exists; retain it and choose a new name' >&2; exit 2; }
mkdir -p "$log_root"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ "$mode" = prepare ]; then set -- --headless; else set --; fi
"$godot_bin" "$@" --path "$repo_root/client" --script res://scripts/checks/factory_statistics_performance_check.gd --no-header --log-file "$log_root/$mode.log" -- "--batch=$batch" "--source=$source_snapshot" "--${mode}-only"
if rg '^(SCRIPT ERROR|ERROR:)' "$log_root/$mode.log" | rg -v 'Condition "ret != noErr"' >/dev/null; then
  echo "Statistics performance check reported errors: $log_root/$mode.log" >&2
  exit 1
fi
