#!/usr/bin/env bash
# Description: Perform a web search using the Brave Search API and return results.
# Param: query - The search query string [string] [required]
# Param: count - Number of results to return (default: 5) [integer] [optional]

set -euo pipefail

# 1. Validate dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: 'curl' is required but not installed." >&2
    exit 1
fi

# 2. Check required API credentials
if [[ -z "${BRAVE_API_KEY:-}" ]]; then
    echo "Error: BRAVE_API_KEY environment variable is not set. Optional: BRAVE_SEARCH_URL" >&2
    exit 1
fi

# 3. Parse parameters
QUERY="${1:-}"
COUNT="${2:-5}"

[[ -z "$QUERY" ]] && { echo "Usage: $0 <query> [count]" >&2; exit 1; }

# 4. Determine API endpoint URL
API_URL="${BRAVE_SEARCH_URL:-https://api.search.brave.com/res/v1/web/search}"

# 5. Execute request using curl with standard Brave headers
response=$(curl -s -w "\n%{http_code}" -G "$API_URL" \
    -H "Accept: application/json" \
    -H "X-Subscription-Token: ${BRAVE_API_KEY}" \
    --data-urlencode "q=$QUERY" \
    -d "count=$COUNT")

code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d' | jq)

# 6. Handle errors
[[ "$code" -ge 400 ]] && { echo "Error ($code): $body" >&2; exit 1; }

# 7. Output results
echo "$body" | jq .web.results | jq '.[]' | jq '{title, url, description}'
