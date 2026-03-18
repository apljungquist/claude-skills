#!/usr/bin/env bash
set -euo pipefail

DIR="${1:?Usage: $0 <results-dir>}"

grep -h '^### ' "$DIR"/*.md --exclude='*.debug.md' 2>/dev/null \
| sed -n 's/^### //p' \
| awk '{ a[$0]++ } END { for (k in a) printf "%3d %s\n", a[k], k }' \
| sort -t'[' -k2,2
