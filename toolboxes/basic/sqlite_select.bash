#!/usr/bin/env bash
# Description: Run a read-only SQL SELECT query against an SQLite database.
# Param: db_path - Path to the SQLite database file [string] [required]
# Param: query - The SQL SELECT query to execute [string] [required]

sqlite3 -readonly -safe -ifexists -noinit -bail -markdown "$1" "$2"

