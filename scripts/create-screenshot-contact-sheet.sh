#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -lt 3 ]]; then
  echo "用法：$0 <output.png> <input-1.png> <input-2.png> [更多图片...]" >&2
  exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
radish_godot_bin="${RADISH_GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
caller_dir="$PWD"
absolute_arguments=()

for argument in "$@"; do
  if [[ "$argument" = /* ]]; then
    absolute_arguments+=("$argument")
  else
    absolute_arguments+=("$caller_dir/$argument")
  fi
done

if [[ ! -x "$radish_godot_bin" ]]; then
  echo "未找到 Godot：$radish_godot_bin；可通过 RADISH_GODOT_BIN 指定。" >&2
  exit 1
fi

log_file="$(mktemp /tmp/radishcatalyst-contact-sheet.XXXXXX.log)"
godot_log_file="$(mktemp /tmp/radishcatalyst-contact-sheet-godot.XXXXXX.log)"
trap 'rm -f "$log_file" "$godot_log_file"' EXIT

set +e
"$radish_godot_bin" \
  --headless \
  --path "$repo_root/client" \
  --script "$repo_root/scripts/create-screenshot-contact-sheet.gd" \
  --log-file "$godot_log_file" \
  -- "${absolute_arguments[@]}" 2>&1 | tee "$log_file"
godot_status="${PIPESTATUS[0]}"
set -e

if [[ "$godot_status" -ne 0 ]]; then
  exit "$godot_status"
fi

if ! grep -q "Contact sheet saved:" "$log_file"; then
  echo "联系表脚本未输出成功标记；请检查上方 Godot 日志。" >&2
  exit 1
fi
