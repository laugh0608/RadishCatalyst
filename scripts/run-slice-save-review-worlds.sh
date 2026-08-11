#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
client_root="${repo_root}/client"
review_root="${1:-${repo_root}/tools/runtime-intake/review-worlds/current}"
godot_exe="${GODOT_EXE:-}"

if [[ -z "$godot_exe" && -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  godot_exe="/Applications/Godot.app/Contents/MacOS/Godot"
fi
if [[ -z "$godot_exe" ]]; then
  godot_exe="$(command -v godot4 || command -v godot || true)"
fi
if [[ -z "$godot_exe" || ! -x "$godot_exe" ]]; then
  echo "未找到 Godot；请安装 Godot 4.x 或通过 GODOT_EXE 指定。" >&2
  exit 1
fi
if [[ ! -d "$review_root/worlds" && ! -d "$review_root/trash" ]]; then
  echo "复核目录不存在或尚未生成：$review_root" >&2
  exit 1
fi

exec "$godot_exe" \
  --path "$client_root" \
  --script "$client_root/scripts/tools/slice_save_review_launcher.gd" \
  -- \
  "--review-root=$review_root"
