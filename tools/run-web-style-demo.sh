#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "An existing Node.js runtime is required." >&2; exit 1; }
exec node "$repo_root/tools/visual-studies/web-style/server.mjs"
