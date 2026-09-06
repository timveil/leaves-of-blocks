# Review comments are addressed and resolved before merge

**Every review comment — human or Copilot — is addressed and its thread
resolved before the pull request merges.** No open threads at merge time.

## What "addressed" means

One of two things:

1. **Change the code**, then resolve the thread with a reply saying what
   changed.
2. **Explain why not**, then resolve. "This is intentional because X" is a
   complete answer. "We'll handle it in #123" is a complete answer if the issue
   exists.

Silence is not an answer, and neither is resolving without replying. A thread
closed with no response looks identical to one nobody read.

## Disagreeing is fine

A reviewer being wrong is a normal outcome. Say so, say why, resolve the
thread. What is not fine is leaving the disagreement unrecorded — the next
person to read the file gets the reviewer's concern with no rebuttal attached,
and re-raises it.

## Who resolves

The PR author, after acting. It is not the reviewer's job to chase whether
their comment landed, and it is not a bot's job to notice you fixed something.

Resolve only what you actually acted on. Bulk-resolving to clear a red badge
destroys the signal the badge exists to carry.

## Copilot is a reviewer, not noise

Triage its findings like any other reviewer's: some are wrong, some are style
preferences, some are real. Dismissing the category wholesale means missing the
real ones.

A worked example from #72. Copilot flagged `grep -q` where `grep -qF` was more
appropriate — on its face a style nit worth ignoring. It was not. The needle was
`"No non-merge commits to lint."`, and the trailing `.` in default grep mode
matches any character:

```
$ probe="No non-merge commits to lintX"
$ grep -q  "No non-merge commits to lint." <<<"$probe" && echo MATCHED
MATCHED
```

The assertion would have passed on output that was not the message it claimed
to check. A test that cannot fail is worse than no test, because it reports
confidence it has not earned. The nit was a bug.

## Check before merging

The PR page collapses resolved threads, which makes it easy to believe a page
with no visible comments has none outstanding. Verify:

```bash
gh api graphql -f query='
query {
  repository(owner: "timveil", name: "leaves-of-blocks") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 50) {
        nodes { isResolved comments(first: 1) { nodes { path author { login } } } }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
         | select(.isResolved | not)
         | "UNRESOLVED  \(.comments.nodes[0].path)"'
```

Empty output means clear. Do not assume threads resolve themselves when you
push a fix — on #72 one of two Copilot threads had auto-resolved and the other
had not, with no visible difference between them.

To resolve one:

```bash
gh api graphql -f query='
mutation { resolveReviewThread(input: {threadId: "THREAD_ID"}) { thread { isResolved } } }'
```

## Enforcement

Currently manual — `main` has no branch protection, so nothing blocks a merge
with open threads.

GitHub enforces this natively: **Settings → Branches → branch protection rule →
"Require conversation resolution before merging."** Worth enabling.

One caution if protection is added: enable conversation resolution **without**
marking language-specific CodeQL jobs as required status checks. Since
[#69](https://github.com/timveil/leaves-of-blocks/issues/69), `Analyze (swift)`
legitimately does not run on PRs that touch no Swift, and a required check that
never reports would deadlock those PRs permanently.

## See also

- [Workflow scripts](workflow-scripts.md) — the extraction rule the #72 example came from
- [Testing](testing.md) — on harnesses that report success while asserting nothing
