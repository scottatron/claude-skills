---
name: pr-review
description: Systematic workflow for addressing PR review comments. Use when the user wants to work through PR review comments (from Copilot, teammates, or other reviewers). Triggers include phrases like "work through PR comments", "address review feedback", "go through the review on PR #X", or "fix Copilot's suggestions". The workflow presents all issues with options before implementing any changes, ensuring user has full visibility and control.
---

# PR Review Comment Workflow

A systematic approach to addressing PR review comments efficiently: fetch all comments, present options for each issue, collect all decisions upfront, implement fixes in a single commit, and document resolutions.

## Core Workflow

### 1. Discovery

Fetch all review comments and PR metadata using pagination to ensure ALL unresolved comments are retrieved:

```bash
# Get PR metadata
gh pr view [PR_NUMBER] --json number,title,state,author,baseRefName

# Get repository info
gh repo view --json owner,name

# Fetch ALL comments with pagination (default page size is 30)
# Use --paginate to automatically fetch all pages
gh api repos/OWNER/REPO/pulls/[PR_NUMBER]/comments --paginate

# Alternative: Manual pagination if needed
# gh api repos/OWNER/REPO/pulls/[PR_NUMBER]/comments?page=1&per_page=100
# gh api repos/OWNER/REPO/pulls/[PR_NUMBER]/comments?page=2&per_page=100
```

Filter for unresolved comments only and organize by file path, severity (Critical/Medium/Low), and theme (security, bugs, quality, docs).

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
5. **Reply to each comment as it's addressed:**
   ```bash
   gh api repos/OWNER/REPO/pulls/[PR_NUMBER]/comments/[COMMENT_ID]/replies \
     --method POST \
     --field body="Fixed in collaboration with Claude Code - [brief description of fix]"
   ```
   Make it clear in the reply that the fix was discussed and implemented collaboratively.

6. **Mark each comment as resolved after replying:**
   ```bash
   # Resolve the comment thread
   gh api repos/OWNER/REPO/pulls/[PR_NUMBER]/comments/[COMMENT_ID] \
     --method PATCH \
     --field state="resolved"
   ```

7. Run tests

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

After pushing changes, verify all comments are resolved:

```bash
# Check for any remaining unresolved comments
gh api repos/OWNER/REPO/pulls/[PR_NUMBER]/comments --paginate | \
  jq '[.[] | select(.state != "resolved")]'
```

If any comments remain unresolved, investigate and address them.

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
