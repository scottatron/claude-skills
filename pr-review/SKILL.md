---
name: pr-review
description: Systematic workflow for addressing PR review comments. Use when the user wants to work through PR review comments (from Copilot, teammates, or other reviewers). Triggers include phrases like "work through PR comments", "address review feedback", "go through the review on PR #X", or "fix Copilot's suggestions". The workflow presents all issues with options before implementing any changes, ensuring user has full visibility and control.
---

# PR Review Comment Workflow

A systematic approach to addressing PR review comments efficiently: fetch all comments, present options for each issue, collect all decisions upfront, implement fixes in a single commit, and document resolutions.

## Requirements

- GitHub CLI (`gh`) installed and authenticated
- `jq` for JSON processing
- Repository write permissions (for resolving threads)

Run scripts from the `pr-review/` skill directory or use absolute paths.

## Helper Scripts

The skill includes three helper scripts that simplify working with GitHub's GraphQL API for PR review threads:

### fetch-review-threads.sh
Fetches all review threads for a PR with their resolution status.

```bash
./fetch-review-threads.sh [PR_NUMBER]        # Get unresolved threads only
./fetch-review-threads.sh [PR_NUMBER] --all  # Get all threads
```

Returns JSON with thread IDs, resolution status, file paths, line numbers, and comments.

### resolve-thread.sh
Posts a reply to a thread and marks it as resolved in one operation.

```bash
./resolve-thread.sh "THREAD_ID" "Reply message"
```

Automatically handles the two-step process:
1. Posts reply via REST API (using comment database ID)
2. Resolves thread via GraphQL (using thread ID)

### verify-resolution.sh
Checks if all review threads are resolved and lists any outstanding threads.

```bash
./verify-resolution.sh [PR_NUMBER]
```

Outputs a summary with total/unresolved counts and details of unresolved threads.

## Core Workflow

### 1. Discovery

Fetch all unresolved review threads using GraphQL (automatically handles pagination up to 100 threads):

**Option A: Use helper script (recommended)**
```bash
# Fetch unresolved threads only (default)
./fetch-review-threads.sh [PR_NUMBER]

# Fetch all threads including resolved
./fetch-review-threads.sh [PR_NUMBER] --all
```

**Option B: Direct GraphQL query**
```bash
# Get repo info
REPO_INFO=$(gh repo view --json owner,name)
OWNER=$(echo "$REPO_INFO" | jq -r .owner.login)
REPO=$(echo "$REPO_INFO" | jq -r .name)

# Fetch ALL review threads with GraphQL
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        number
        title
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            isOutdated
            path
            line
            comments(first: 100) {
              nodes {
                id
                databaseId
                body
                createdAt
                author { login }
              }
            }
          }
        }
      }
    }
  }
' -F owner="$OWNER" -F repo="$REPO" -F pr=[PR_NUMBER] | \
  jq '.data.repository.pullRequest.reviewThreads.nodes | map(select(.isResolved == false))'
```

**Key data points:**
- `thread.id` - GraphQL thread ID (needed for resolution)
- `thread.isResolved` - Resolution status
- `thread.path` - File path
- `thread.line` - Line number
- `comment.databaseId` - REST API comment ID (for posting replies)

Organize threads by file path, severity (Critical/Medium/Low), and theme (security, bugs, quality, docs).

### 2. Analysis

For each comment group:

1. Understand the issue and its impact
2. Identify 2-4 resolution approaches with trade-offs
3. Recommend best approach based on codebase patterns
4. Read relevant code context (affected files, related patterns, docs)

### 3. Decision Collection

Present ALL issues before implementing ANY fixes.

**Format:**
```
Issue #N: [Brief description]
File: path/to/file.ts:42
Severity: Critical/Medium/Low

Options:
1. [Quick fix] - [Trade-offs]
2. [Thorough fix] - [Trade-offs]
3. [Alternative] - [Trade-offs]

Recommendation: Option X because [reasoning]
```

Use AskUserQuestion to collect decisions:
- Present 1-4 issues per question
- Batch by theme or priority for large sets
- Include skip/defer options when appropriate

**Key Principle:** Never start implementing until user has decided on ALL comments.

### 4. Implementation

After collecting all decisions:

1. Plan file edit order (dependencies first)
2. Make all changes based on user's choices
3. Check for related code needing similar fixes
4. Update affected documentation
5. **Reply to and resolve each thread as it's addressed:**

   **Option A: Use helper script (recommended)**
   ```bash
   ./resolve-thread.sh "[THREAD_ID]" "Fixed in collaboration with Claude Code - [brief description]"
   ```

   **Option B: Manual approach**
   ```bash
   # Step 1: Post reply to the thread (uses REST API with comment databaseId)
   gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments/[COMMENT_DB_ID]/replies \
     --method POST \
     --field body="Fixed in collaboration with Claude Code - [brief description]"

   # Step 2: Resolve the thread (uses GraphQL with thread ID)
   gh api graphql -f query='
     mutation($threadId: ID!) {
       resolveReviewThread(input: {threadId: $threadId}) {
         thread {
           id
           isResolved
         }
       }
     }
   ' -F threadId="[THREAD_ID]"
   ```

   **Important notes:**
   - Use `thread.id` (GraphQL ID) for resolution, not comment ID
   - Use `comment.databaseId` (REST API ID) for posting replies
   - Both IDs are available from the Discovery phase query
   - Reply messages should make collaborative nature clear

6. Run tests

Keep changes focused - only what was discussed, maintain existing style, preserve backward compatibility.

### 5. Commit

Create comprehensive commit message:

```
fix: address [source] PR review comments

[One-sentence summary of scope]

**Critical Fixes:**
- [Security/bug fixes]

**Code Quality:**
- [Refactoring, best practices]

**Documentation:**
- [Examples, guides, comments]

**Changes:**
- path/to/file: [what changed and why]

All [N] review threads addressed.

Relates to #[PR_NUMBER]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Commit and push:
```bash
git add [files]
git commit -m "[message above]"
git push
```

### 6. Verification

After pushing changes, verify all review threads are resolved:

**Option A: Use helper script (recommended)**
```bash
./verify-resolution.sh [PR_NUMBER]
```
This will output a summary and list any unresolved threads.

**Option B: Direct GraphQL query**
```bash
# Get repo info
REPO_INFO=$(gh repo view --json owner,name)
OWNER=$(echo "$REPO_INFO" | jq -r .owner.login)
REPO=$(echo "$REPO_INFO" | jq -r .name)

# Check for unresolved threads
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          totalCount
          nodes {
            id
            isResolved
            path
            line
            comments(first: 1) {
              nodes {
                body
                author { login }
              }
            }
          }
        }
      }
    }
  }
' -F owner="$OWNER" -F repo="$REPO" -F pr=[PR_NUMBER] | \
  jq -r '.data.repository.pullRequest.reviewThreads |
         "Total: \(.totalCount), Unresolved: \([.nodes[] | select(.isResolved == false)] | length)"'
```

If any threads remain unresolved, investigate and address them before considering the work complete.

## Multi-Round Strategy

For PRs with many comments (>10), split into rounds:

- **Round 1:** Critical (security, bugs, breaking changes)
- **Round 2:** Code quality (refactoring, performance, best practices)
- **Round 3:** Polish (docs, examples, style)

Each round follows full workflow: Fetch → Analyze → Decide → Implement → Commit

## Quality Checkpoints

Before committing:
- All user decisions implemented correctly
- No unintended side effects
- Related code updated for consistency
- Documentation reflects changes
- Tests pass
- Commit message is comprehensive

## Common Patterns

**Security:** Always prioritize (Round 1), create issue if complex, document considerations

**Naming/Style:** Check existing patterns, apply consistently, update style guide if new pattern

**Dependencies:** Consider version compatibility, check breaking changes, update lock files

**Documentation:** Fix incorrect examples, update guides/READMEs, add comments for complex changes
