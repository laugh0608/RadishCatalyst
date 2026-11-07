#!/bin/sh
set -eu
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/../.." && pwd)"
godot_exe="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "${godot_exe}" ]; then
  echo "Set GODOT_EXE to an installed Godot 4 executable." >&2
  exit 2
fi
session="review-$(date '+%Y%m%d-%H%M%S')-$$"
topic=factory-core-outline-v1
if [ "$#" -eq 1 ] && [ "$1" = "--materials" ]; then
  topic=factory-material-study-v1
elif [ "$#" -ne 0 ]; then
  echo "Usage: core-study.sh [--materials]" >&2
  exit 2
fi
logs="${repo_root}/tools/runtime-intake/check-runs/${topic}/${session}"
mkdir -p "${logs}"
exec "${godot_exe}" --path "${repo_root}/client" --log-file "${logs}/godot.log" --script "${script_dir}/core-study.gd" -- "${session}" "$@"
