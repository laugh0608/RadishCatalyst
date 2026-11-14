#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
mode="${1:-state}"
batch="${2:-$mode-$(date +%s)-$$}"
case "$mode" in state|window) ;; *) echo 'Usage: sh tools/check-factory-integrated-first-run.sh [state|window] [batch]' >&2; exit 2 ;; esac
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Invalid batch name' >&2; exit 2 ;; esac
run_root="$repo_root/tools/runtime-intake/check-runs/factory-integrated-first-run-v1/$batch"
mkdir -p "$(dirname "$run_root")"
if ! mkdir "$run_root"; then echo 'Use a new batch; existing evidence is retained.' >&2; exit 2; fi
python3 - "$repo_root" > "$run_root/layout.json" <<'PY'
import json
from pathlib import Path
import runpy
import sys

root = Path(sys.argv[1])
audit = runpy.run_path(str(root / "tools/design/audit-four-sided-core-layout.py"))["audit"]
print(json.dumps(audit("S1-P"), indent=2))
PY
run_godot() {
  stage="$1"
  shift
  status=0
  "$godot_bin" --path "$repo_root/client" --log-file "$run_root/$stage.log" "$@" > "$run_root/$stage-console.log" 2>&1 || status=$?
  tail -n 38 "$run_root/$stage-console.log"
  if [ "$status" -ne 0 ]; then exit "$status"; fi
  if rg -q '^(SCRIPT ERROR|ERROR:)' "$run_root/$stage-console.log" "$run_root/$stage.log"; then exit 1; fi
}
check_script=res://scripts/checks/factory_integrated_first_run.gd
if [ "$mode" = state ]; then
  run_godot write --headless --quit-after 900 --script "$check_script" -- "--batch=$batch"
else
  run_godot write --script "$check_script" -- "--batch=$batch"
fi
test -f "$run_root/first-run.json"
if [ "$mode" = state ]; then
  run_godot read --headless --quit-after 900 --script "$check_script" -- "--batch=$batch" --read
else
  run_godot read --script "$check_script" -- "--batch=$batch" --read
fi
test -f "$run_root/restore-result.json"
