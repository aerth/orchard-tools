#!/usr/bin/env bash
# Description: Deletes a specific telegram message using its message id.
# Param: chat_id - The unique identifier for the chat [integer] [required]
# Param: message_id - The unique identifier for the message to delete [integer] [required]

set -euo pipefail

# Usage: <chat_id> <message_id>
CHAT_ID="${1:-}"
MESSAGE_ID="${2:-}"

[[ -z "$CHAT_ID" ]] && { echo "Error: missing chat_id and message_id parameters" >&2; exit 1; }
[[ -z "$MESSAGE_ID" ]] && { echo "Error: missing message_id parameter" >&2; exit 1; }
[[ -z "$TG_TOKEN" ]] && { echo "Error: missing environment variable TG_TOKEN" >&2; exit 1; }

API_URL="https://api.telegram.org/bot${TG_TOKEN}/deleteMessage"

response=$(curl -s -w "\n%{http_code}" -G "$API_URL" \
        -d "chat_id=${CHAT_ID}" \
        -d "message_id=${MESSAGE_ID}")

code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d' | sed "s|${TG_TOKEN}|xx|g")

[[ "$code" -ge 400 ]] && { echo "Error ($code): $body" >&2; exit 1; }
echo "$body"
