#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
mode="${1:-state}"
batch="${2:-$mode-$(date +%s)-$$}"
case "$mode" in state|window|storage-state|storage-window|play) ;; *) echo 'Usage: sh tools/check-factory-grid-controls.sh [state|window|storage-state|storage-window|play] [batch]' >&2; exit 2 ;; esac
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Invalid batch name' >&2; exit 2 ;; esac
if [ "$mode" = play ]; then
  run_root="$repo_root/tools/runtime-intake/review-worlds/factory-grid-controls-v1/$batch"
  mkdir -p "$run_root"
else
  run_root="$repo_root/tools/runtime-intake/check-runs/factory-grid-controls-v1/$batch"
  mkdir -p "$(dirname "$run_root")"
  if ! mkdir "$run_root"; then echo 'Use a new batch; existing evidence is retained.' >&2; exit 2; fi
  python3 - "$repo_root" > "$run_root/layout.json" <<'PY'
import json
from pathlib import Path
import runpy
import sys

audit = runpy.run_path(str(Path(sys.argv[1]) / "tools/design/audit-four-sided-core-layout.py"))["audit"]
print(json.dumps(audit("S1-P"), indent=2))
PY
fi
run_godot() {
  stage="$1"
  shift
  status=0
  "$godot_bin" --path "$repo_root/client" --log-file "$run_root/$stage.log" "$@" > "$run_root/$stage-console.log" 2>&1 || status=$?
  tail -n 35 "$run_root/$stage-console.log"
  if [ "$status" -ne 0 ]; then exit "$status"; fi
  if rg -q '^(SCRIPT ERROR|ERROR:)' "$run_root/$stage-console.log" "$run_root/$stage.log"; then exit 1; fi
}
check_script=res://scripts/checks/factory_grid_controls_check.gd
if [ "$mode" = play ]; then
  run_godot "play-$(date +%s)-$$" --script "$check_script" -- "--batch=$batch" --play
else
  if [ "$mode" = state ] || [ "$mode" = storage-state ]; then
    set -- --headless --quit-after 1200
  else
    set --
  fi
  case "$mode" in storage-*)
    run_godot write "$@" --script "$check_script" -- "--batch=$batch" --storage
    test -f "$run_root/expected.json"
    run_godot read "$@" --script "$check_script" -- "--batch=$batch" --storage --read ;;
  *)
    run_godot write "$@" --script "$check_script" -- "--batch=$batch"
    test -f "$run_root/expected.json"
    run_godot read "$@" --script "$check_script" -- "--batch=$batch" --read ;;
  esac
  test -f "$run_root/restore.json"
fi
