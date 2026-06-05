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

for ((i=0; i<repo_count; i++)); do

    repo_name=$(echo "$github_repos" | jq -r ".[$i].name")
    repo_private=$(echo "$github_repos" | jq -r ".[$i].private")

    echo
    echo "================================="
    echo "Processing repository: $repo_name"
    echo "================================="

    exists_in_codeberg=$(
        echo "$codeberg_repos" |
        jq -r --arg name "$repo_name" \
        '.[] | select(.name == $name) | .name' |
        head -n1
    )

    if [[ -z "$exists_in_codeberg" ]]; then

        echo "Repository not found on Codeberg. Creating..."

        # curl -s \
        #     -X POST \
        #     -H "Authorization: token $CODEBERG_TOKEN" \
        #     -H "Content-Type: application/json" \
        #     https://codeberg.org/api/v1/user/repos \
        #     -d "$(jq -n \
        #         --arg name "$repo_name" \
        #         --argjson private "$repo_private" \
        #         '{
        #             name: $name,
        #             private: $private
        #         }')"

        # echo
        # echo "Repository created successfully."

    else

        echo "Repository already exists on Codeberg."

    fi

    mirror_path="$WORKDIR/${repo_name}.git"

    echo "Cloning mirror from GitHub..."

    git clone --quiet --mirror \
        "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${repo_name}.git" \
        "$mirror_path"

    cd "$mirror_path"

    # git remote add codeberg \
    #     "https://${CODEBERG_USER}:${CODEBERG_TOKEN}@codeberg.org/${CODEBERG_USER}/${repo_name}.git"

    echo "Pushing mirror to Codeberg..."

    # git push --mirror codeberg

    echo "Repository synchronized successfully."
done

echo
echo "Mirror synchronization completed successfully."
