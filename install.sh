#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_DST="${HOME}/.claude/skills"

# Discover available skills
skills=()
while IFS= read -r d; do
    skills+=("$(basename "$d")")
done < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ ${#skills[@]} -eq 0 ]]; then
    echo "No skills found in $SKILLS_SRC"
    exit 1
fi

echo "Available skills:"
for i in "${!skills[@]}"; do
    name="${skills[$i]}"
    status=""
    if [[ -L "$SKILLS_DST/$name" ]]; then
        status=" (installed)"
    fi
    printf "  %d) %s%s\n" $((i + 1)) "$name" "$status"
done

echo
read -rp "Enter skill numbers to install (e.g. 1 3) or 'all': " selection

selected=()
if [[ "$selection" == "all" ]]; then
    selected=("${skills[@]}")
else
    for num in $selection; do
        idx=$((num - 1))
        if [[ $idx -ge 0 && $idx -lt ${#skills[@]} ]]; then
            selected+=("${skills[$idx]}")
        else
            echo "Skipping invalid selection: $num"
        fi
    done
fi

if [[ ${#selected[@]} -eq 0 ]]; then
    echo "No skills selected."
    exit 0
fi

mkdir -p "$SKILLS_DST"

for name in "${selected[@]}"; do
    target="$SKILLS_SRC/$name"
    link="$SKILLS_DST/$name"
    if [[ -L "$link" ]]; then
        echo "  $name: already installed"
    elif [[ -e "$link" ]]; then
        echo "  $name: skipped ($link already exists and is not a symlink)"
    else
        ln -s "$target" "$link"
        echo "  $name: installed"
    fi
done
