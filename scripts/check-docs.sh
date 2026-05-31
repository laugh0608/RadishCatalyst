#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoLogo -NoProfile -File "${repo_root}/scripts/check-docs.ps1"
fi

python_exe="${PYTHON:-python3}"
if command -v "${python_exe}" >/dev/null 2>&1; then
  exec "${python_exe}" "${repo_root}/scripts/check-docs.py" "${repo_root}"
fi

echo "PowerShell 7 (pwsh) or python3 is required to run documentation budget checks." >&2
exit 1
