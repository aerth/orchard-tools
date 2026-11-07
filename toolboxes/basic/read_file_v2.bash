#!/usr/bin/env bash
# Description: Read file text (with line numbers, uses bat)
# Param: path - Path to file to read [string] [required]
# Param: line_range - Lines to read ("30:40" or ":40" or "40:") [string] [optional]
if [[ $# -lt 1 || -z "$1" ]]; then
  echo "Error: missing 'path' argument" >&2
  exit 1
fi
rel_path="$1"
line_range="$2"
if [[ "$rel_path" == *.env ]]; then
  echo "Error: env detected" >&2
  exit 1
fi
base="$(realpath -m "$PWD")"
target="$(realpath -m "$rel_path")"
parent="$(dirname "$base")"
if [[ "$target" == *.env ]]; then
  echo "Error: env detected" >&2
  exit 1
fi
allowed=false
for dir in "$base" "$parent/orchard" "$parent/orchard-tui" "$parent/otools"; do
  resolved_dir="$(realpath -m "$dir")"
  if [[ "$target" == "$resolved_dir" || "$target" == "$resolved_dir/"* ]]; then
    allowed=true
    break
  fi
done
if [[ "$allowed" != true ]]; then
  echo "Error: Path traversal detected" >&2
  exit 1
fi
args=(
  --color=never
  --style=+header
  --style=+header-filesize
  --style=+numbers
  --style=+changes
  --decorations=always
  --paging=never
  --wrap=never
  --terminal-width=60
)
if [[ -n "$line_range" ]]; then
  args+=(-r "$line_range")
fi
bat "${args[@]}" "$target"
