#!/bin/sh
set -eu
review_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
batch="${1:-r2-reactor-$(date +%s)-$$}"
exec sh "$review_dir/r2-core-review.sh" "$batch" reactor
