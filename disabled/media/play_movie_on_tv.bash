#!/bin/bash
# Description: Start playing a movie (casted onto our physical monitor)
# Param: item_id - movie ID (from grep_our_movies tool, looks like "abcde1234abc123" or the string "random") [string] [required]
toolenvfile="${ORCHARD_TOOLS:-.}/.env"
source $toolenvfile || exit 4
server=${ORCHARD_JELLYFIN_SERVER}
token=${ORCHARD_JELLYFIN_TOKEN}
user_id=${ORCHARD_JELLYFIN_USER}
if [[ -z $server ]] || [[ -z $token ]] || [[ -z $user_id ]]; then
	echo "Error: missing env" >&2
	exit 4
fi
get_session() {
	curl -s -H "X-MediaBrowser-Token: ${token}" "${server}/Sessions" | jq -r ".[] | select(.UserId == \"${user_id}\") | .Id" | head -n 1
}
play_jellyfin_item() {
	local item_id="$1"
	if [ -z "$item_id" ]; then
		echo "Error: Missing Item ID." >&2
		return 1
	fi
	local session_id
	session_id=$(get_session) || return 3
	if [ -z "$session_id" ] || [ "$session_id" == "null" ]; then
		echo "Error: No active client session found for user: ${user_id}" >&2
		return 1
	fi
	echo "Sending play command to Session: ${session_id}..."
	curl -s -X POST -H "X-MediaBrowser-Token: ${token}" "${server}/Sessions/${session_id}/Playing?ItemIds=${item_id}&PlayCommand=PlayNow"
}
play_random_jellyfin_movie() {
	local random_movie_url="${server}/Items?userId=${user_id}&recursive=true&includeItemTypes=Movie&sortBy=Random&filters=IsUnplayed&limit=1"
	local item_id
	item_id=$(curl -s -H "X-MediaBrowser-Token: ${token}" "${random_movie_url}" | jq -r ".Items[0].Id") || return 4
	if [ -z "$item_id" ] || [ "$item_id" == "null" ]; then
		echo "Error: No unplayed movies found." >&2
		return 1
	fi
	play_jellyfin_item "$item_id"
}
if [ "$1" == "random" ]; then
	play_random_jellyfin_movie
else
	play_jellyfin_item "${1}"
fi
exit $?
