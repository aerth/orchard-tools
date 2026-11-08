#!/usr/bin/env bash
# Description: Execute an SQL query on a SQLite database and return formatted results.
# Param: db_path - Path to the SQLite database file [string] [required]
# Param: query - The SQL query to execute [string] [required]

set -euo pipefail

# 1. Validate dependencies
if ! command -v sqlite3 &> /dev/null; then
    echo "Error: 'sqlite3' CLI is required but not installed." >&2
    exit 1
fi

# 2. Parse and validate arguments
DB_PATH="${1:-}"
QUERY="${2:-}"

if [[ -z "$DB_PATH" || -z "$QUERY" ]]; then
    echo "Usage: $0 <db_path> \"<query>\"" >&2
    exit 1
fi

if [[ ! -f "$DB_PATH" ]]; then
    echo "Error: Database file '$DB_PATH' not found." >&2
    exit 1
fi

# 3. Execute the query
# Using -header and -column flags so the output renders as an easy-to-read table for the LLM
sqlite3 -header -column "$DB_PATH" "$QUERY"
