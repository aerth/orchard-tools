#!/bin/bash
# Description: play music (mpc) on our speakers
# Param: query - search query or exact song filename to play [string]
toolenvfile="${ORCHARD_TOOLS:-.}/.env"
source "$toolenvfile" || exit 3
export MPD_HOST=$ORCHARD_MPC_HOST
if [ -z "$MPD_HOST" ]; then
  echo "mpc can not be used yet, it needs environmental variable ORCHARD_MPC_HOST"
  exit 1
fi
currently=$(mpc status | head -n 1)
query="$1"
if echo "$currently" | grep "$query"; then
  echo Already playing
  exit 2
fi
if [[ $query = *.mp3 ]] || [[ $query = *.opus ]]; then
	song_file=$query
else
	song_file="$(mpc search filename "$1")"
	first="$(echo "$song_file" | head -n 1)"
	if true || [[ "$first" != "$song_file" ]]; then
		echo "Pick one result (full path)."
		echo "$song_file"
		exit 23
	fi
	if [ -z "$song_file" ]; then
		echo No results for that query, try again.
		exit 2
	fi
	echo Playing "$song_file"
fi
mpc searchplay filename "$song_file"
