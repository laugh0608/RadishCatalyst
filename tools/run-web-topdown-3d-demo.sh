#!/bin/sh
set -eu
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
demo_root="$repo_root/tools/visual-studies/web-topdown-3d"
command -v node >/dev/null 2>&1 || { echo "An existing Node.js runtime is required." >&2; exit 1; }
test -f "$demo_root/node_modules/three/build/three.module.js" || { echo "Install the documented locked local dependency before starting." >&2; exit 1; }
exec node "$demo_root/server.mjs"
