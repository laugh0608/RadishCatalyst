#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoLogo -NoProfile -File "${repo_root}/scripts/check-text-files.ps1"
fi

echo "PowerShell 7 (pwsh) is required to run repository text checks." >&2
exit 1
