#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
mode="${1:-state}"
batch="${2:-state-$(date +%s)-$$}"
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Invalid batch name' >&2; exit 2 ;; esac
topic="factory-conveyor-routing-v1"
boot_script="factory_routing_boot_check.gd"
case "$mode" in
  replacement-write|replacement-read|replacement-background-write|replacement-background-read)
    topic="factory-attachment-replacement-v1"
    boot_script="factory_attachment_replacement_boot_check.gd"
    mode="${mode#replacement-}"
    ;;
esac
log_root="$repo_root/tools/runtime-intake/check-runs/$topic/$batch"
background=false
case "$mode" in
  background-write) mode=write; background=true ;;
  background-read) mode=read; background=true ;;
  background-preview) mode=preview; background=true ;;
esac
case "$mode" in
  state|menu) if [ -d "$log_root" ]; then echo 'Use a new batch; prior evidence is retained.' >&2; exit 2; fi; set -- ;;
  process-read) if [ ! -f "$log_root/expected.json" ] || [ -f "$log_root/read-result.json" ]; then echo 'Requires unconsumed successful state batch.' >&2; exit 2; fi; set -- --read ;;
  write) if [ "$#" -lt 2 ] || [ -d "$log_root" ]; then echo 'Write requires a new explicit batch.' >&2; exit 2; fi; set -- ;;
  preview) if [ "$#" -lt 2 ] || [ -d "$log_root" ]; then echo 'Preview requires a new explicit batch.' >&2; exit 2; fi; set -- --connection-preview-only ;;
  review) if [ ! -f "$log_root/expected.json" ] || [ -f "$log_root/read-result.json" ]; then echo 'Review requires an unused isolated copy of a write snapshot.' >&2; exit 2; fi; set -- --read --visual-only ;;
  read) if [ ! -f "$log_root/expected.json" ] || [ -f "$log_root/read-result.json" ]; then echo 'Read requires an unconsumed write batch.' >&2; exit 2; fi; set -- --read ;;
  *) echo 'Usage: sh tools/check-factory-routing.sh [state|menu|process-read|background-preview|preview|background-write|background-read|write|read|review|replacement-write|replacement-read|replacement-background-write|replacement-background-read] [batch]' >&2; exit 2 ;;
esac
mkdir -p "$log_root"
if [ "$mode" = state ] || [ "$mode" = process-read ]; then
  "$godot_bin" --headless --path "$repo_root/client" --script res://scripts/checks/factory_routing_check.gd --no-header --log-file "$log_root/$mode.log" -- "--evidence=$log_root" "$@"
elif [ "$mode" = menu ]; then
  "$godot_bin" --headless --path "$repo_root/client" --script res://scripts/checks/factory_routing_menu_check.gd --no-header --log-file "$log_root/$mode.log" -- "--evidence=$log_root"
elif [ "$background" = true ]; then
  "$godot_bin" --headless --path "$repo_root/client" --script "res://scripts/checks/$boot_script" --no-header --log-file "$log_root/$mode.log" -- "--batch=$batch" --background "$@"
else
  "$godot_bin" --path "$repo_root/client" --script "res://scripts/checks/$boot_script" --no-header --log-file "$log_root/$mode.log" -- "--batch=$batch" "$@"
fi
if rg '^(SCRIPT ERROR|ERROR:)' "$log_root/$mode.log" | rg -v 'Condition "ret != noErr"' >/dev/null; then
  echo "Routing $mode check reported errors: $log_root/$mode.log" >&2; exit 1
fi
