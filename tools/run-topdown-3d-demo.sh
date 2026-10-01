#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$godot_bin" ]; then
  echo "Set GODOT_EXE to an installed Godot executable." >&2
  exit 1
fi
mode="review-worlds"
scene="res://Main.tscn"
case "${1:-}" in
  --verify) mode="check-runs" ;;
  --production) scene="res://production/Production.tscn" ;;
  --verify-production|--verify-navigation|--verify-resolution) mode="check-runs"; scene="res://production/Production.tscn" ;;
  "") ;;
  *) echo "Usage: sh tools/run-topdown-3d-demo.sh [--verify | --production | --verify-production | --verify-navigation | --verify-resolution]" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
  echo "Only one mode is supported." >&2
  exit 2
fi
topic="topdown-3d"
resolution="1440x810"
if [ "$scene" = "res://production/Production.tscn" ]; then
  topic="godot-production-line"
  resolution="1440x900"
fi
log_dir="$repo_root/tools/runtime-intake/$mode/$topic"
mkdir -p "$log_dir"
run_stamp="$(date -u +%Y%m%dT%H%M%SZ)-$$"
exec "$godot_bin" --path "$repo_root/tools/visual-studies/topdown-3d" \
  --resolution "$resolution" "$scene" --no-header --log-file "$log_dir/$run_stamp.log" -- "$@"
