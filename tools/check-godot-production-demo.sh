#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$godot_bin" ]; then
  echo "Set GODOT_EXE to an installed Godot executable." >&2
  exit 1
fi
if ! command -v node >/dev/null 2>&1; then
  echo "Node is required to replay the existing Web reference; no dependencies are installed by this check." >&2
  exit 1
fi
log_dir="$repo_root/tools/runtime-intake/check-runs/godot-production-line"
mkdir -p "$log_dir"
node "$repo_root/tools/visual-studies/topdown-3d/production/verify-parity.mjs"
"$godot_bin" --headless --path "$repo_root/tools/visual-studies/topdown-3d" \
  --script res://production/verify-model.gd --no-header --log-file "$log_dir/model-check.log"
echo "Model comparison complete. Window review is separate: sh tools/run-topdown-3d-demo.sh --verify-production"
