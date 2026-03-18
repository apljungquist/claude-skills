#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:?Usage: $0 <workdir> <output-base>}"
OUTPUT_BASE="$(cd "$(dirname "${2:?Usage: $0 <workdir> <output-base>}")" && pwd)/$(basename "$2")"
cd "$WORKDIR"

echo "Running /review-commits ..."
claude --debug-file "${OUTPUT_BASE}.debug.md" --print "/review-commits" --setting-sources project > "${OUTPUT_BASE}.md"

echo "Review written to ${OUTPUT_BASE}.md"
