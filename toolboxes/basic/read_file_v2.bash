#!/usr/bin/env bash
set -ue
# Description: Read file text (with line numbers, uses bat)
# Param: path - Path to file to read [string] [required]
# Param: line_range - Lines to read ("30:40" or ":40" or "40:") [string] [optional]
if [[ $# -lt 1 || -z "$1" ]]; then
	echo "Error: missing 'path' argument" >&2
	exit 1
fi
rel_path="$1"
line_range="${2:-}"
## check path is ok and then run bat
if [[ "$rel_path" == *.env ]]; then
	echo "Error: env detected" >&2
	exit 11
fi
if [[ "$rel_path" == */.* ]]; then
	echo "Error: dot path detected" >&2
	exit 12
fi
base="$(realpath -m "$PWD")"
target="$(realpath -m "$rel_path")"
mysrcdir="${HOME}/src"
if [[ "$target" == *.env ]]; then
	echo "Error: env detected" >&2
	exit 13
fi
if [[ "$rel_path" == */.* ]]; then
	echo "Error: dot path detected" >&2
	exit 14
fi

# humans can edit this list to adjust path restrictions
okpaths=(
	"$base"     # any paths in ./
	"$mysrcdir" # any paths in ~/src/
	"/tmp/"     # tmp dir
)
allowed=false
for dir in "${okpaths[@]}"; do
	resolved_dir="$(realpath -m "$dir" 2>/dev/null)" || continue
	if [[ "$target" == "$resolved_dir" || "$target" == "$resolved_dir/"* ]]; then
		allowed=true
		break
	fi
done
if [[ "$allowed" != true ]]; then
	echo "Error: Path traversal detected" >&2
	exit 5
fi
echo -n "Contents of file ${rel_path@Q} (with line numbers)"
if [[ -n "$line_range" ]]; then
	args+=(-r "$line_range")
	echo -n " Line range ${line_range@Q}"
	echo
    echo ================
	cat -n "$target" | sed -n "$(echo $line_range | tr ':' ',')p"
    echo ================
else
	echo -n " Showing all lines ($(wc -l "$target" | awk '{print $1}'))"
	echo
    echo ================
	cat -n "$target"
    echo ================
fi
#bat "${args[@]}" "$target"
