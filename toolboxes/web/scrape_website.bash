#!/usr/bin/env bash
# Description: Scrapes a website, returns the content.
# Param: url - Target URL to scrape [string] [required]
# Param: format - Output format, e.g. markdown, html, text [string] [optional]
# Param: render_js - Enable JavaScript rendering via headless browser [boolean] [optional]

set -euo pipefail

# Usage: ./scrape_website.bash <url> [format] [render_js]
URL="${1:-}"
[[ -z "$URL" ]] && { echo "Usage: $0 <url> [format] [render_js]" >&2; exit 1; }

[[ -z "$SUPACRAWLER_API_KEY" ]] && {
  echo "This tool is not configured. Edit the .env file for this toolbox"
  exit 2
}
[[ -z "$SUPACRAWLER_URL" ]] && {
  echo "This tool is not configured. Edit the .env file for this toolbox"
  exit 2
}
API_URL="${SUPACRAWLER_URL:-https://api.supacrawler.com/api/v1/scrape}"
response=$(curl -s -w "\n%{http_code}" -G "$API_URL" \
	-H "X-API-KEY: ${SUPACRAWLER_API_KEY}" \
    -d "url=$URL" \
    -d "format=${2:-markdown}" \
    -d "render_js=${3:-false}")

code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

[[ "$code" -ge 400 ]] && { echo "Error ($code): $body" >&2; exit 1; }
echo "$body"
