#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
mode="${1:-state}"
batch="${2:-}"
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Use an explicit safe batch name.' >&2; exit 2 ;; esac
log_root="$repo_root/tools/runtime-intake/check-runs/factory-item-admission-v1/$batch"
background=false
case "$mode" in background-write) mode=write; background=true ;; background-read) mode=read; background=true ;; esac
case "$mode" in
  state|menu|write) if [ -d "$log_root" ]; then echo 'Use a new batch; evidence is retained.' >&2; exit 2; fi; set -- ;;
  process-read) if [ ! -f "$log_root/partial.json" ] || [ -f "$log_root/read-result.json" ]; then echo 'Requires unconsumed successful state batch.' >&2; exit 2; fi; set -- --read ;;
  read|review) if [ ! -f "$log_root/expected.json" ] || [ -f "$log_root/read-result.json" ]; then echo 'Requires unused write or copied review batch.' >&2; exit 2; fi; set -- --read; if [ "$mode" = review ]; then set -- "$@" --visual-only; fi ;;
  *) echo 'Usage: sh tools/check-factory-admission.sh state/process-read/menu/background-write/background-read/write/read/review <batch>' >&2; exit 2 ;;
esac
mkdir -p "$log_root"
if [ "$mode" = state ] || [ "$mode" = process-read ]; then
  "$godot_bin" --headless --path "$repo_root/client" --script res://scripts/checks/factory_admission_check.gd --no-header --log-file "$log_root/$mode.log" -- "--evidence=$log_root" "$@"
elif [ "$mode" = menu ]; then
  "$godot_bin" --headless --path "$repo_root/client" --script res://scripts/checks/factory_admission_menu_check.gd --no-header --log-file "$log_root/menu.log" -- "--evidence=$log_root"
elif [ "$background" = true ]; then
  "$godot_bin" --headless --path "$repo_root/client" --script res://scripts/checks/factory_admission_boot_check.gd --no-header --log-file "$log_root/$mode.log" -- "--batch=$batch" --background "$@"
else
  "$godot_bin" --path "$repo_root/client" --script res://scripts/checks/factory_admission_boot_check.gd --no-header --log-file "$log_root/$mode.log" -- "--batch=$batch" "$@"
fi
if rg '^(SCRIPT ERROR|ERROR:)' "$log_root/$mode.log" | rg -v 'Condition "ret != noErr"' >/dev/null; then echo 'Admission check reported errors; inspect retained log.' >&2; exit 1; fi
