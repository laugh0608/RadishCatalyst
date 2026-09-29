#!/usr/bin/env bash
set -euo pipefail
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/../.." && pwd)"
godot_exe="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
run_root="${repo_root}/tools/runtime-intake/review-worlds/factory-refinement-v1"
mkdir -p "${run_root}"
exec "${godot_exe}" --path "${repo_root}/client" --script "${script_dir}/refinement-demo.gd" \
  --log-file "${run_root}/demo.log" --no-header
