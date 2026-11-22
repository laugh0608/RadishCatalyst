#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
batch="${1:-r2-core-$(date +%s)-$$}"
case "$batch" in *[!a-zA-Z0-9_-]*|'') echo 'Invalid R2 batch name.' >&2; exit 2 ;; esac
run_root="$repo_root/tools/runtime-intake/check-runs/factory-r2-core-v1/$batch"
art_root="$repo_root/assets/art-intake/$(date +%F)-factory-representative-assets/$batch"
mkdir -p "$(dirname "$run_root")" "$(dirname "$art_root")"
if [ -e "$run_root" ] || [ -e "$art_root" ]; then
  echo 'Use a new R2 batch; previous evidence is retained.' >&2
  exit 2
fi
mkdir "$run_root" "$art_root"
python3 - "$repo_root" > "$run_root/layout.json" <<'PY'
import json
from pathlib import Path
import runpy
import sys

repo = Path(sys.argv[1])
audit = runpy.run_path(str(repo / "tools/design/audit-four-sided-core-layout.py"))["audit"]
print(json.dumps(audit("S1-P"), indent=2))
PY
printf '%s\n' "$art_root" > "$run_root/art-path.txt"
runtime_rc=0
"$godot_bin" --path "$repo_root/client" --quit-after 3600 --log-file "$run_root/window.log" \
  --script "$repo_root/tools/factory-content/check-r2-core.gd" -- "--batch=$batch" "--art=$art_root" \
  > "$run_root/window-console.log" 2>&1 || runtime_rc=$?
tail -n 45 "$run_root/window-console.log"
if [ "$runtime_rc" -ne 0 ]; then exit "$runtime_rc"; fi
if rg -q '^(SCRIPT ERROR|ERROR:)' "$run_root/window-console.log" "$run_root/window.log"; then exit 1; fi
test -f "$run_root/result.json"
test -f "$art_root/core-r2.tscn"
