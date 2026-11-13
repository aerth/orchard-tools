#!/usr/bin/env bash
# Description: Create new file or replace existing.
# Param: path - File path to edit [string] [required]
# Param: new_text - Exact file text [string] [required]

set -u

if [[ $# -ne 2 ]]; then
  echo "Error: expected path, new_text arguments" >&2
  exit 1
fi

rel_path="$1"
new_text="$2"

if [[ -z "$rel_path" ]]; then
  echo "Error: missing 'path' argument" >&2
  exit 1
fi
base="$(pwd -P)" || {
  echo "Error: could not resolve current directory" >&2
  exit 1
}
parent="$(dirname "$base")"

if ! target="$(realpath -e -- "$rel_path")"; then
  echo "Error: file does not exist or cannot be resolved" >&2
  exit 1
fi

case "$(basename "$target")" in
  .env|.env.*|*.env)
    echo "Error: refusing to edit an env file" >&2
    exit 1
    ;;
esac

allowed=false
for dir in "$base" "$parent/orchard" "$parent/orchard-tui" "$parent/otools"; do
  if ! resolved_dir="$(realpath -e -- "$dir" 2>/dev/null)"; then
    continue
  fi

  if [[ "$target" == "$resolved_dir" || "$target" == "$resolved_dir/"* ]]; then
    allowed=true
    break
  fi
done

if [[ "$allowed" != true ]]; then
  echo "Error: path is outside the allowed directories" >&2
  exit 1
fi

if [[ -e "$target" ]] && [[ ! -f "$target" ]]; then
  echo "Error: target must be a regular file" >&2
  exit 1
fi

tmp=''
cleanup() {
  if [[ -n "$tmp" && -e "$tmp" ]]; then
    rm -f -- "$tmp"
  fi
}
trap cleanup EXIT

if ! tmp="$(mktemp -- "${target}.orchard.XXXXXX")"; then
  echo "Error: could not create temporary file" >&2
  exit 1
fi

if ! printf '%s' "$new_text" > "$tmp"; then
  echo "Error: could not write temporary file" >&2
  exit 1
fi

if ! chmod --reference="$target" -- "$tmp"; then
  echo "Error: could not preserve file permissions" >&2
  exit 1
fi

if ! mv -f -- "$tmp" "$target"; then
  echo "Error: could not replace file" >&2
  exit 1
fi

echo "Updated $target"
