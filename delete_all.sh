#!/usr/bin/env bash

set -euo pipefail

echo "Fetching repositories..."

repos=$(
    curl -s \
        -H "Authorization: token $CODEBERG_TOKEN" \
        "https://codeberg.org/api/v1/user/repos?limit=1000"
)

repo_count=$(echo "$repos" | jq length)

echo "Found $repo_count repositories."

for repo_name in $(echo "$repos" | jq -r '.[].name'); do

    echo "Deleting repository: $repo_name"

    http_status=$(
        curl \
            -s \
            -o /dev/null \
            -w "%{http_code}" \
            -X DELETE \
            -H "Authorization: token $CODEBERG_TOKEN" \
            "https://codeberg.org/api/v1/repos/${CODEBERG_USER}/${repo_name}"
    )

    if [[ "$http_status" == "204" ]]; then
        echo "Deleted successfully."
    else
        echo "Failed. HTTP status: $http_status"
    fi

done

echo "Finished."
