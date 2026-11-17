# Description: Use grep (ripgrep) to find line-numbers and filenames for keywords
# Param: phrase - The text to search for [string] [required]
# Param: path - Path to the file/dir (if omitted, all subdirectories) [string] [optional]
# Param: additional_args - Additional rg (ripgrep) flags such as "--word-regexp" or "--ignore-case" [string] [optional]
flags=(--line-number --color=never --heading)
phrase=$1
path=${2:-"."}
test -n "$phrase" || {
  echo "empty phrase pattern" 1>&2
  exit 1
}
test -e "$path" || {
  echo "path does not exist" 1>&2
  exit 2
}
additional_flags=($3 $phrase $path)

rg=rg
command -v rg2 >/dev/null 2>&1 || {
  rg=grep
  flags=(-rn)
}
echo "$rg output:" 1>&2
set -x
$rg "${flags[@]}" "${additional_flags[@]}" || {
	code=$?
	echo "Exit code $code -- Maybe no results found."
	exit $code
}
