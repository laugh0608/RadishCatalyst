#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
mode="${1:-state}"
batch="${2:-state-$(date +%s)-$$}"
background=false
case "$mode" in
  background-write) mode=write; background=true ;;
  background-read) mode=read; background=true ;;
esac
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Invalid batch name' >&2; exit 2 ;; esac
log_root="$repo_root/tools/runtime-intake/check-runs/factory-device-interaction-v1/$batch"
case "$mode" in
  state) ;;
  write|preview)
    if [ "$#" -lt 2 ] || [ -d "$log_root" ]; then
      echo 'Write/preview requires a new explicit batch name; existing evidence is retained.' >&2
      exit 2
    fi
    ;;
  read)
    if [ "$#" -lt 2 ] || [ ! -f "$log_root/expected.json" ] || [ -f "$log_root/read-result.json" ]; then
      echo 'Read requires a completed write batch not already consumed by read.' >&2
      exit 2
    fi
    ;;
  *) echo 'Usage: sh tools/check-factory-device-interaction.sh [state|background-write|background-read|write|read|preview] [batch]' >&2; exit 2 ;;
esac
mkdir -p "$log_root"
if [ "$mode" = state ]; then
  "$godot_bin" --headless --path "$repo_root/client" --script res://scripts/checks/factory_device_interaction_check.gd --no-header --log-file "$log_root/state.log"
else
  if [ "$mode" = read ]; then set -- --read; elif [ "$mode" = preview ]; then set -- --preview-only; else set --; fi
  if [ "$background" = true ]; then
    "$godot_bin" --headless --path "$repo_root/client" --script res://scripts/checks/factory_device_interaction_boot_check.gd --no-header --log-file "$log_root/$mode.log" -- "--batch=$batch" --background "$@"
  else
    "$godot_bin" --path "$repo_root/client" --script res://scripts/checks/factory_device_interaction_boot_check.gd --no-header --log-file "$log_root/$mode.log" -- "--batch=$batch" "$@"
  fi
fi
if rg '^(SCRIPT ERROR|ERROR:)' "$log_root/$mode.log" | rg -v 'Condition "ret != noErr"' >/dev/null; then
  echo "Device interaction $mode check reported errors: $log_root/$mode.log" >&2
  exit 1
fi
echo "Factory device interaction $mode check completed."
