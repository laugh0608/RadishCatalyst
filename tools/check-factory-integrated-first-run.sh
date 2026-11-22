#!/bin/sh
set -eu
tools_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
godot_bin="${GODOT_EXE:-/Applications/Godot.app/Contents/MacOS/Godot}"
exec "${PYTHON:-python3}" "$tools_dir/check-factory-integrated-first-run.py" --godot "$godot_bin" "$@"
