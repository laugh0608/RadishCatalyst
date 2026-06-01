#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd)"

python_exe="${PYTHON:-python3}"
if command -v "${python_exe}" >/dev/null 2>&1; then
  exec "${python_exe}" "${repo_root}/scripts/check-docs.py" "${repo_root}"
fi

echo "python3 is required to run macOS/Linux documentation budget checks." >&2
exit 1
