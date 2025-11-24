#!/usr/bin/env bash
# Reply to and resolve a review thread
# Usage: ./resolve-thread.sh THREAD_ID "Reply message"

set -euo pipefail

THREAD_ID="${1:-}"
REPLY_MESSAGE="${2:-}"

if [ -z "$THREAD_ID" ] || [ -z "$REPLY_MESSAGE" ]; then
  echo "Error: Missing required arguments" >&2
  echo "Usage: $0 THREAD_ID \"Reply message\"" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 \"RT_kwDOABCD1234\" \"Fixed in collaboration with Claude Code - refactored error handling\"" >&2
  exit 1
fi

# Get the first comment ID in the thread to reply to
# We need to get the thread details first
REPO_INFO=$(gh repo view --json owner,name)
OWNER=$(echo "$REPO_INFO" | jq -r .owner.login)
REPO=$(echo "$REPO_INFO" | jq -r .name)

# Get thread details to find the pull request review ID
THREAD_DATA=$(gh api graphql -f query="
  query {
    node(id: \"$THREAD_ID\") {
      ... on PullRequestReviewThread {
        id
        comments(first: 1) {
          nodes {
            id
            databaseId
            pullRequestReview {
              id
              databaseId
            }
          }
        }
      }
    }
  }
")

# Extract the first comment's database ID for replying via REST API
FIRST_COMMENT_DB_ID=$(echo "$THREAD_DATA" | jq -r '.data.node.comments.nodes[0].databaseId')

if [ -z "$FIRST_COMMENT_DB_ID" ] || [ "$FIRST_COMMENT_DB_ID" = "null" ]; then
  echo "Error: Could not find comment ID in thread" >&2
  exit 1
fi

# Get PR number from current context or thread
PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null || echo "")

if [ -z "$PR_NUMBER" ]; then
  echo "Error: Could not determine PR number. Please run from PR context or specify PR number" >&2
  exit 1
fi

# Reply to the comment using REST API
echo "Posting reply to thread..."
gh api "repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/$FIRST_COMMENT_DB_ID/replies" \
  --method POST \
  --field body="$REPLY_MESSAGE" > /dev/null

echo "Reply posted successfully"

# Resolve the thread using GraphQL
echo "Resolving thread..."
RESOLVE_RESULT=$(gh api graphql -f query="
  mutation(\$threadId: ID!) {
    resolveReviewThread(input: {threadId: \$threadId}) {
      thread {
        id
        isResolved
      }
    }
  }
" -F threadId="$THREAD_ID")

IS_RESOLVED=$(echo "$RESOLVE_RESULT" | jq -r '.data.resolveReviewThread.thread.isResolved')

if [ "$IS_RESOLVED" = "true" ]; then
  echo "Thread resolved successfully"
  exit 0
else
  echo "Warning: Thread may not be resolved. Response: $RESOLVE_RESULT" >&2
  exit 1
fi
