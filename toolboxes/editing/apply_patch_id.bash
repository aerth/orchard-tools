#!/usr/bin/env bash
# Description: Apply a patch to a file based on its patch_id.
# Param: path - File path to edit [string] [required]
# Param: patch_id - Exact uuid for patch to apply [string] [required]
set -u

# 1. Capture arguments
filename="$1"
patch_id="$2"

# 2. Configuration - Adjust these paths according to your environment
# Usually, patches are stored relative to the toolboxes directory
BASE_DIR="/tmp/opatches" # Example path
DIFF_FILE="${BASE_DIR}/${patch_id}.diff"

echo "args 1=$filename 2=$patch_id"

# 3. Validation
if [ ! -f "$filename" ]; then
    echo "Error: Target file $filename does not exist."
    exit 2
fi

if [ ! -f "$DIFF_FILE" ]; then
    echo "Error: Patch file $DIFF_FILE not found."
    exit 3
fi

# 4. Apply the patch
# -p1 is standard for patches created from a project root
# -f forces the patch if there are minor conflicts
if patch -p1 "$filename"<"$DIFF_FILE"; then
    echo "Successfully applied patch $patch_id to $filename"
    exit 0
else
    echo "Error: Failed to apply patch."
    exit 4
fi
