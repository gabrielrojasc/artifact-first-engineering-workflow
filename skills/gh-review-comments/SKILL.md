---
name: gh-review-comments
description: fetch GitHub PR review comments for one or more PRs, assess whether each unresolved item should be fixed or dismissed, and produce an approval proposal before editing code or replying.
---

# GitHub Review Comment Triage

## Overview

Fetch review feedback from one or more GitHub pull requests, inspect the relevant code or diff, and propose how to handle each unresolved item. The default output is a review-comment proposal the human can approve, revise, or reject.

Use this skill when the user asks to:

- fetch unresolved comments from one PR or multiple PRs
- assess PR review comments
- decide whether comments should be fixed or dismissed
- draft the proposal before applying fixes or posting replies

## Workflow

1. Identify the PRs.
   - Accept explicit PR URLs, PR numbers, `#123`, or `owner/repo#123`.
   - If no PR is provided, use the PR associated with the current branch.
   - For multiple PRs, keep the findings grouped by PR.
2. Fetch comments.
   - Run `scripts/fetch-pr-comments.py <pr> [<pr> ...]` for unresolved inline review threads.
   - Unresolved review threads are the default.
   - Use `--all-threads` only when the user asks to inspect resolved threads too.
   - Use `--include-context` only when top-level PR conversation comments or review bodies are needed. They can be noisy because bot summaries often include large generated reports.
   - Treat top-level PR conversation comments and review bodies as context only. Do not turn review-summary text, bot summaries, or non-threadable nitpicks into reply targets.
3. Inspect the relevant code.
   - Read the cited files, diff hunks, tests, and nearby code before judging a comment.
   - If the local checkout is not the PR branch, prefer `gh pr diff <pr>` and read-only `gh api` lookups over changing branches.
   - Do not make code changes, post comments, resolve threads, or change PR state during assessment.
4. Classify each actionable item.
   - An actionable item is an unresolved review thread returned under `review_threads`.
   - **Fix**: the comment identifies a real defect, missing behavior, contract mismatch, test gap, or maintainability problem worth changing.
   - **Dismiss with reply**: the comment is incorrect, stale, out of scope, or outweighed by existing constraints.
   - **Already addressed**: the diff or code already handles it; propose a short confirming reply only if useful.
   - Every item must get one of these recommendations. If a comment depends on product, ownership, rollout, or style preference, choose the best recommendation from the evidence and make the assumption explicit in the proposal.
5. Produce the proposal and wait.
   - Do not edit code or reply on GitHub until the human approves the proposal or a subset of items.

## Proposal Format

Use sectioned item blocks, not a table. Review comments often need multiline evidence, assumptions, and draft replies; tables make those hard to scan.

Start with a compact rollup:

- `Fix: <count>`
- `Dismiss: <count>`
- `Already addressed: <count>`

Then list each PR and each unresolved item using this shape:

```markdown
## PR <number>: <title>

Verdict: Fix <count>, dismiss <count>, already addressed <count>.

### <item-number>. <Fix | Dismiss with reply | Already addressed> -- `<path>:<line>`

Thread: <review-thread comment URL>
Reviewer: <author>

Reviewer concern:
<one-sentence summary of the comment, not a pasted wall of reviewer text>

Assessment:
<agent judgment, including any assumptions>

Proposal:
<concrete fix plan or dismissal rationale>

Evidence:
- <file, diff, test, or contract evidence>
- <second evidence point when useful>

Draft thread reply:
<only for Dismiss with reply or Already addressed>
```

For **Fix** items, omit `Draft thread reply` unless the user asked for fix-response text too. Keep replies concise and scoped to the reviewed code. Do not mention private chat context as evidence.

## Approval Rules

- The proposal is read-only.
- Fixes require explicit human approval.
- Dismissal replies require explicit human approval and must target a review thread.
- Resolving review threads requires explicit human approval separate from posting a reply unless the user already asked to resolve them.
- If the human approves only some items, handle only those items.

## Posting Replies After Approval

Use the least broad mutation needed:

- Inline review thread reply: `gh api graphql` with `addPullRequestReviewThreadReply`.
- Resolve a thread only when approved: `gh api graphql` with `resolveReviewThread`.
- Top-level PR comments are out of the default flow. Use `gh pr comment <pr> --body-file <file>` only when the user explicitly asks to post a top-level PR comment, and never as a substitute response for review-summary text or non-threadable nitpicks.

Prefer writing reply bodies to a temporary file and passing `--body-file` or `-F body=@<file>` so shell quoting cannot corrupt the message.

## Rules

- Ground every recommendation in code, diff, test, or PR evidence.
- Do not repeat prior reviewer text as the agent's own assessment.
- Do not pad the proposal with low-confidence findings.
- Push back on weak review comments when evidence shows they are wrong.
- Preserve read-only boundaries until the human approves implementation or replies.
- For multiple PRs, avoid cross-contaminating evidence between PRs unless the same code path is explicitly shared.
- Do not respond top-level on the PR to review-summary nitpicks, bot rollups, or comments that do not have a review thread. If a concern has no threadable comment, mention it as context only.
