#!/usr/bin/env bash
# Description: Send a desktop notification to the user and wait for confirmation.
# Param: title - The title of the notification [string] [required]
# Param: message - The message body of the notification [string] [required]

title="${1:-No Title Given}"
message="${2:-No Message Given}"

notify-send "$title" "$message"

echo "Notification sent: title='$title' message='$message'"

