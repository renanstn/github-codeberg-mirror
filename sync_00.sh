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

echo "Fetching Codeberg repositories..."

codeberg_repos=$(
    curl -s \
        -H "Authorization: token $CODEBERG_TOKEN" \
        "https://codeberg.org/api/v1/user/repos?limit=1000"
)

repo_count=$(echo "$github_repos" | jq length)
codeberg_repo_count=$(echo "$codeberg_repos" | jq length)

echo "Found $repo_count GitHub repositories."
echo "Found $codeberg_repo_count Codeberg repositories."
echo "$codeberg_repos" | jq -r '.[].name'
