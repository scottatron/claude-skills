#!/usr/bin/env bash
# Verify all review threads are resolved for a PR
# Usage: ./verify-resolution.sh [PR_NUMBER]

set -euo pipefail

PR_NUMBER="${1:-}"

# Get PR number if not provided
if [ -z "$PR_NUMBER" ]; then
  PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null || echo "")
  if [ -z "$PR_NUMBER" ]; then
    echo "Error: No PR number provided and not in a PR context" >&2
    echo "Usage: $0 [PR_NUMBER]" >&2
    exit 1
  fi
fi

# Get repo info
REPO_INFO=$(gh repo view --json owner,name)
OWNER=$(echo "$REPO_INFO" | jq -r .owner.login)
REPO=$(echo "$REPO_INFO" | jq -r .name)

# Fetch all review threads
RESULT=$(gh api graphql --paginate -f query="
  query(\$owner: String!, \$repo: String!, \$pr: Int!, \$endCursor: String) {
    repository(owner: \$owner, name: \$repo) {
      pullRequest(number: \$pr) {
        number
        title
        reviewThreads(first: 100, after: \$endCursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
          totalCount
          nodes {
            id
            isResolved
            path
            line
            comments(first: 1) {
              nodes {
                body
                author {
                  login
                }
              }
            }
          }
        }
      }
    }
  }
" -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER")

# Combine results from all pages
ALL_NODES=$(echo "$RESULT" | jq -s 'map(.data.repository.pullRequest.reviewThreads.nodes) | add')

# Extract stats
TOTAL_THREADS=$(echo "$ALL_NODES" | jq 'length')
UNRESOLVED_THREADS=$(echo "$ALL_NODES" | jq '[.[] | select(.isResolved == false)] | length')

echo "PR #$PR_NUMBER Review Thread Status"
echo "====================================="
echo "Total threads: $TOTAL_THREADS"
echo "Unresolved threads: $UNRESOLVED_THREADS"
echo ""

if [ "$UNRESOLVED_THREADS" -eq 0 ]; then
  echo "✓ All review threads are resolved!"
  exit 0
else
  echo "✗ Unresolved threads found:"
  echo ""
  echo "$ALL_NODES" | jq -r '.[] | select(.isResolved == false) | "  • \(.path // "General comment"):\(.line // "N/A") - \(.comments.nodes[0].body[0:80])..."'
  exit 1
fi
