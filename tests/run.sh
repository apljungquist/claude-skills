#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CASE_DIR="$(cd "${1:?Usage: $0 <case-dir>}" && pwd)"
WORKDIR="$(mktemp -d)"

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

"$SCRIPT_DIR/setup.sh" "$CASE_DIR" "$WORKDIR"
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"
BASE="$(basename "$1")"
for i in 1 2 3 4 5; do
    "$SCRIPT_DIR/review.sh" "$WORKDIR" "$RESULTS_DIR/${BASE}-${i}"
done

"$SCRIPT_DIR/tally.sh" "$RESULTS_DIR"
