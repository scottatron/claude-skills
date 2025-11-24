#!/usr/bin/env bash
# Fetch all review threads for a PR with unresolved status
# Usage: ./fetch-review-threads.sh [PR_NUMBER] [--all]
#   PR_NUMBER: The pull request number (optional, defaults to current PR)
#   --all: Include resolved threads (optional, defaults to unresolved only)

set -euo pipefail

PR_NUMBER="${1:-}"
INCLUDE_RESOLVED="${2:-}"

# Get PR number if not provided
if [ -z "$PR_NUMBER" ]; then
  PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null || echo "")
  if [ -z "$PR_NUMBER" ]; then
    echo "Error: No PR number provided and not in a PR context" >&2
    echo "Usage: $0 [PR_NUMBER] [--all]" >&2
    exit 1
  fi
fi

# Get repo info
REPO_INFO=$(gh repo view --json owner,name)
OWNER=$(echo "$REPO_INFO" | jq -r .owner.login)
REPO=$(echo "$REPO_INFO" | jq -r .name)

# Fetch all review threads using GraphQL
RESULT=$(gh api graphql -f query="
  query(\$owner: String!, \$repo: String!, \$pr: Int!) {
    repository(owner: \$owner, name: \$repo) {
      pullRequest(number: \$pr) {
        number
        title
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            isOutdated
            path
            line
            originalLine
            diffSide
            comments(first: 100) {
              nodes {
                id
                databaseId
                body
                createdAt
                author {
                  login
                }
                isMinimized
              }
            }
          }
        }
      }
    }
  }
" -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER")

# Filter and format the results
if [ "$INCLUDE_RESOLVED" = "--all" ]; then
  echo "$RESULT" | jq '.data.repository.pullRequest.reviewThreads.nodes'
else
  # Only show unresolved threads
  echo "$RESULT" | jq '.data.repository.pullRequest.reviewThreads.nodes | map(select(.isResolved == false))'
fi
