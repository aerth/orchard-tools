#!/usr/bin/env bash
# Description: Replace one text block in a file, allowing whitespace differences.
# Param: path - Existing file path to edit [string] [required]
# Param: old_text - Text to find; whitespace runs match flexibly [string] [required]
# Param: new_text - Replacement text [string] [required]

set -u

if [[ $# -ne 3 ]]; then
  echo "Error: expected path, old_text, and new_text arguments" >&2
  exit 1
fi

rel_path="$1"
old_text="$2"
new_text="$3"
output_dir=/tmp/opatches/
mkdir -p "$output_dir" || exit 32

if [[ -z "$rel_path" ]]; then
  echo "Error: missing 'path' argument" >&2
  exit 1
fi
if [[ -z "$old_text" ]]; then
  echo "Error: 'old_text' must not be empty" >&2
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

if [[ ! -f "$target" ]]; then
  echo "Error: target must be a regular file" >&2
  exit 1
fi

# Read text without command substitution, which would strip trailing newlines.
original=''
IFS= read -r -d '' original < "$target" || :

# Convert old_text into a Bash regular expression:
# literal characters stay literal; each whitespace run becomes [[:space:]]+.
pattern=''
in_whitespace=false

for ((i = 0; i < ${#old_text}; i++)); do
  char="${old_text:i:1}"

  if [[ "$char" =~ [[:space:]] ]]; then
    if [[ "$in_whitespace" == false ]]; then
      pattern+='[[:space:]]+'
      in_whitespace=true
    fi
    continue
  fi

  in_whitespace=false

  case "$char" in
    '.'|'\'|'+'|'*'|'?'|'('|')'|'['|']'|'{'|'}'|'^'|'$'|'|')
      pattern+='\'
      ;;
  esac
  pattern+="$char"
done

# Count non-overlapping matches and remember the one match, if unique.
remaining="$original"
match_count=0
first_prefix=''
first_match=''

while [[ "$remaining" =~ $pattern ]]; do
  matched="${BASH_REMATCH[0]}"
  prefix="${remaining%%"$matched"*}"

  match_count=$((match_count + 1))
  if (( match_count == 1 )); then
    first_prefix="$prefix"
    first_match="$matched"
  else
    break
  fi

  remaining="${remaining#"$prefix$matched"}"
done

if (( match_count != 1 )); then
  echo "Error: expected one match; found $match_count or more" >&2
  exit 1
fi

suffix="${original#"$first_prefix$first_match"}"
updated="${first_prefix}${new_text}${suffix}"

if [[ "$updated" == "$original" ]]; then
  echo "No change needed"
  exit 0
fi

# Detect a concurrent edit before replacing the file.
latest=''
IFS= read -r -d '' latest < "$target" || :
if [[ "$latest" != "$original" ]]; then
  echo "Error: file changed during edit; refusing to overwrite it" >&2
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

if ! printf '%s' "$updated" > "$tmp"; then
  echo "Error: could not write temporary file" >&2
  exit 1
fi

if ! chmod --reference="$target" -- "$tmp"; then
  echo "Error: could not preserve file permissions" >&2
  exit 1
fi

PATCH_ID=$(uuidgen) || exit 2
diff -u "${target}" "${tmp}" | tee ${output_dir}/${PATCH_ID}.diff
echo Patch file created. The file is still not modified. To proceed, use apply_patch_id to apply it cleanly.
echo PATCH_ID=${PATCH_ID}
#if ! mv -f -- "$tmp" "$target"; then
#  echo "Error: could not replace file" >&2
#  exit 1
#fi

#echo "Updated $target"
