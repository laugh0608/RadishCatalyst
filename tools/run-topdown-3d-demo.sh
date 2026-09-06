#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$godot_bin" ]; then
  echo "Set GODOT_EXE to an installed Godot executable." >&2
  exit 1
fi
mode="review-worlds"
case "${1:-}" in
  --verify) mode="check-runs" ;;
  "") ;;
  *) echo "Usage: sh tools/run-topdown-3d-demo.sh [--verify]" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
  echo "Only --verify is supported." >&2
  exit 2
fi
log_dir="$repo_root/tools/runtime-intake/$mode/topdown-3d"
mkdir -p "$log_dir"
run_stamp="$(date -u +%Y%m%dT%H%M%SZ)-$$"
exec "$godot_bin" --path "$repo_root/tools/visual-studies/topdown-3d" \
  --resolution 1440x810 --no-header --log-file "$log_dir/$run_stamp.log" -- "$@"
