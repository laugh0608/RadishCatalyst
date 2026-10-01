#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$godot_bin" ]; then
  echo "Set GODOT_EXE to an installed Godot executable." >&2
  exit 1
fi
log_dir="$repo_root/tools/runtime-intake/2026-09-06-pipe-module-validation/logs"
mkdir -p "$log_dir"
run_stamp="$(date -u +%Y%m%dT%H%M%SZ)-$$"
exec "$godot_bin" --path "$repo_root/client" \
  --script "$repo_root/tools/run_pipe_visual_study.gd" --no-header \
  --log-file "$log_dir/review-$run_stamp.log" -- "$@"
