#!/usr/bin/env bash
# Description: find a file by name. if no exact matches, looks for similar.
# Param: name - the name or partial name [string] [required]
name="${1:-}"
[ -z "$name" ] && echo 'Usage: find_file <name>' "but got ${@@Q}" && exit 1

r=$(find . -type f -name "$name" 2>/dev/null)
if [ -n "$r" ]; then
    echo "Exact matches:"
    echo "$r"
	exit 0
else
    echo "No exact match. Looking for similar..."
    find . -type f -name "*$name*" 2>/dev/null || echo "No matches found."
fi
