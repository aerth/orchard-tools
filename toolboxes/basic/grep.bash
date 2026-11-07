# Description: Use grep (ripgrep) to find line-numbers and filenames for keywords
# Param: phrase - The text to search for [string] [required]
# Param: path - Path to the file (if omitted, all subdirectories) [string] [optional]
# Param: case_insensitive - Add -i flag if we arent sure about spelling. Causes more false positives! [boolean] [optional]
flags=(--line-number --word-regexp)
if [[ "$3" == "true" ]]; then
  flags+=("--ignore-case")
fi
rg "${flags[@]}" "${1}" "${2:-.}"
