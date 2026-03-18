#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/../skills"

CASE_DIR="$(cd "${1:?Usage: $0 <case-dir> <workdir>}" && pwd)"
WORKDIR="${2:?Usage: $0 <case-dir> <workdir>}"

source "$CASE_DIR/config.sh"

mkdir -p "$WORKDIR"

echo "Cloning $REPO_URL into $WORKDIR ..."
git clone "$REPO_URL" "$WORKDIR"

cd "$WORKDIR"

echo "Resetting to $BASE_COMMIT ..."
git reset --hard "$BASE_COMMIT"

echo "Applying patches ..."
for patch in "$CASE_DIR"/*.patch; do
    [ -f "$patch" ] && git am "$patch"
done

echo "Setting up skills ..."
mkdir -p .claude/skills
for skill in "$SKILLS_SRC"/*/; do
    ln -s "$(cd "$skill" && pwd)" ".claude/skills/$(basename "$skill")"
done

echo "Repo ready at $WORKDIR"
