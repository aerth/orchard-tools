#!/bin/bash
# Description: search our networked movie library, by title
# Param: pattern - short SIMPLE query such as vampire or space without quotes or symbols [string] [required]
# Param: full - leave blank or use 'full' for more data [string] [optional]

#toolenvfile=$(realpath "$(dirname "$(readlink -f "$0")")/../../.env")
toolenvfile="${ORCHARD_TOOLS:-.}/.env"
source $toolenvfile || exit 4
server=${ORCHARD_JELLYFIN_SERVER}
token=${ORCHARD_JELLYFIN_TOKEN}
user_id=${ORCHARD_JELLYFIN_USER}
jellyfin_items() {
	local search_terms="${@}"
	# Fail if no query supplied
	[[ ${#search_terms[@]} -eq 0 ]] && {
		echo "usage: jellyfin_items [-l N] [-s N] <search words…>" >&2
		return 1
	}

	local search_term="${search_terms[*]}"
	gum log -l debug "searching for ${search_term@Q}"
	# Default values (if the globals were empty)
	: "${limit:=800}"
	: "${start_index:=0}"

	# ---------- Build the URL ---------------------------------
	# JSON‑urlencode
	local base="${server}/Items?userId=${user_id}&isMissing=false&limit=${limit}&recursive=true"
	base+="&searchTerm=${search_term// /+}"
	base+="&startIndex=${start_index}"
	base+="&imageTypeLimit=0&enableTotalRecordCount=false"

	# Fields (each appears twice in the original request)
	local fields=(Overview Genres Tags Tagslines MediaSources)
	for f in "${fields[@]}"; do
		base+="&fields=${f}"
	done

	# includeItemTypes – order doesn’t matter but keep it the same
	local types=(Movie Series Episode Playlist MusicAlbum Audio TvChannel PhotoAlbum Photo AudioBook Book BoxSet)
	for t in "${types[@]}"; do
		base+="&includeItemTypes=${t}"
	done

	# ---------- Get a token ------------------------------------
	#	if [[ -z "$token" ]]; then
	#		token="${JELLYFIN_TOKEN:-}"
	#	fi
	if [[ -z "$token" ]]; then
		if [[ -f ~/.jellyfin_token ]]; then
			token=$(<~/.jellyfin_token)
		else
			echo "❌ No Jellyfin token found.  Export JELLYFIN_TOKEN or store it in ~/.jellyfin_token." >&2
			return 1
		fi
	fi

	# ---------- Perform the request -----------------------------
	curl -sS \
		"$base" \
		-H "Accept: application/json, text/plain, */*" \
		-H "Authorization: MediaBrowser Token=${token}"
}
jellyfin_keyword_search() {
	gum log -l info "searching keyword $query"
	query="$1"
	if [ -z "$query" ]; then
		echo Missing query for keyword search
		return 3
	fi
	local base="${server}/Items?userId=${user_id}&isMissing=false&limit=${limit}&recursive=true"
	base+="&tags=${query// /+}"
	base+="&startIndex=${start_index}"
	base+="&imageTypeLimit=0&enableTotalRecordCount=false"
	local fields=(Overview Genres Tags Tagslines MediaSources)
	for f in "${fields[@]}"; do
		base+="&fields=${f}"
	done
	curl -sS "$base" -H "Accept: application/json, text/plain, */*" -H "Authorization: MediaBrowser Token=${token}"
}

jellyfin_collection() {
	local collection_id="$1"

	if [[ -z "$collection_id" ]]; then
		echo "usage: jellyfin_collection <collection_id>" >&2
		return 1
	fi
	#gum log -l info "fetching collection info: ${collection_id@Q}" 1>&2

	# Fallback default values
	: "${limit:=800}"
	: "${start_index:=0}"

	# Build the URL using parentId instead of searchTerm
	local base="${server}/Items?userId=${user_id}&parentId=${collection_id}&isMissing=false&limit=${limit}&recursive=true"
	base+="&startIndex=${start_index}"
	base+="&imageTypeLimit=0&enableTotalRecordCount=false"

	local fields=(Overview Genres Tags Taglines)
	for f in "${fields[@]}"; do
		base+="&fields=${f}"
	done

	# Fetch Token
	if [[ -z "$token" ]]; then token="${JELLYFIN_TOKEN:-}"; fi
	if [[ -z "$token" && -f ~/.jellyfin_token ]]; then token=$(<~/.jellyfin_token); fi

	curl -sS "$base" -H "Accept: application/json" -H "Authorization: MediaBrowser Token=${token}" #| tee -a /dev/stderr
}

main() {
	raw_items=$(jellyfin_items "${1}" | jq -c '.Items')
	raw_keywords=$(jellyfin_keyword_search "${1}" | jq -c '.Items')
	echo 1>&2
	gum log -l info "Found $(echo "$raw_items" | jq -c .[] | wc -l) matches by name"
	gum log -l info "Found $(echo "$raw_keywords" | jq -c .[] | wc -l) matches by keyword"
	mapfile -t boxsets < <(
		jq -s -r 'add | .[] | select(.Type == "BoxSet") | .Id' \
			<(echo "${raw_items:-[]}") \
			<(echo "${raw_keywords:-[]}") |
			sort -u
	)
	# Capture all individual outputs into a single variable block
	local unique_results
	unique_results=$(jq -s -c 'add | unique_by(.Id)' <(echo "${raw_items:-[]}") <(echo "${raw_keywords:-[]}"))

	local all_outputs
	all_outputs=$(
		# Look through collections
		for boxset in "${boxsets[@]}"; do
			jellyfin_collection "${boxset}" | jq -c '.Items[]'
		done
		# Look through main results
		echo "$unique_results" | jq -c '.[]'
	)

	# Convert the stream of raw single lines back into a JSON array, unique them, and sort them
	#	echo "$all_outputs" | jq -s -c 'unique_by(.Id) | sort_by(.ProductionYear? // 0, .CommunityRating? // 0)[] | {Name, Overview, ProductionYear, CommunityRating, Type, Genres, Tags, Taglines, Id, Width: .MediaSources[0].MediaStreams[0].Width, Height: .MediaSources[0].MediaStreams[0].Height, FileName: (.MediaSources[0].Path | split("/") | last)}'
	if [ "$2" == "json" ]; then
		echo "$all_outputs" | jq -c .
		exit $?
	fi
	echo "$all_outputs" | jq -s -c 'unique_by(.Id) | sort_by(.ProductionYear? // 0, .CommunityRating? // 0)[] | {Name, Overview, ProductionYear, CommunityRating, Type, Genres, Tags, Taglines, Id, Width: (.MediaSources[0].MediaStreams[0].Width? // null), Height: (.MediaSources[0].MediaStreams[0].Height? // null), FileName: (.MediaSources[0].Path | if type == "string" then split("/") | last else "Unknown" end)}'
	num_results=$(echo "$all_outputs" | jq -s -c 'unique_by(.Id) | sort_by(.ProductionYear? // 0, .CommunityRating? // 0)[] | {Name, Overview, ProductionYear, CommunityRating, Type, Genres, Tags, Taglines, Id, Height, Width}' | wc -l)
	echo "Total Results: $num_results"

}

main "${@}"
