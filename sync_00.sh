#!/usr/bin/env bash

set -euo pipefail

WORKDIR="./mirrors"

mkdir -p "$WORKDIR"

echo "Fetching GitHub repositories..."

github_repos="[]"
page=1

while true; do

    current_page=$(
        curl -s \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            "https://api.github.com/user/repos?per_page=100&type=owner&page=$page"
    )

    current_count=$(echo "$current_page" | jq length)

    if [[ "$current_count" -eq 0 ]]; then
        break
    fi

    github_repos=$(
        jq -s 'add' \
            <(echo "$github_repos") \
            <(echo "$current_page")
    )

    echo "Fetched GitHub page $page ($current_count repositories)"

    ((page++))

done

echo "Finished."
