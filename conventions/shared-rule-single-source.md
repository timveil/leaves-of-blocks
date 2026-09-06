# One rule, one definition

**A rule enforced in more than one place is defined once and called from each
place.**

Never re-encode it. Two copies of a regex are two regexes, and they will
diverge — usually silently, usually right when it matters.

## Why

A rule enforced twice has two chances to be right and two chances to drift. The
failure is quiet: the local hook accepts what CI rejects, and the contributor
learns about it only after pushing. Worse is the reverse — the hook rejects what
CI would have allowed, and people start reaching for `--no-verify`.

## Worked example

The commit format is enforced in two places, and defined in neither:

```
scripts/check-commit-subject.sh     ← the rule: regex, allowed types, width
├── .githooks/commit-msg            ← calls it (local)
└── .github/workflows/commit-lint.yml  ← calls it (CI)
```

`CONTRIBUTING.md` and `CLAUDE.md` describe the format for humans, and both
point at the script rather than restating the regex. The script's own header
says it is the single source of truth, so anyone editing it knows what they are
touching.

The same shape applies elsewhere:

- `.xcode-version` holds the minimum Xcode version, read by
  `scripts/xcode-version.sh` — which fastlane's `before_all` and every CI job
  that runs `xcodebuild` both call — rather than a constant in `Constants.rb`
  and a second copy in each workflow.
- `scripts/codeql-languages.sh` holds the path→language mapping, called by the
  workflow rather than duplicated across matrix entries.

## Wrong

```yaml
# .github/workflows/commit-lint.yml
run: echo "$SUBJECT" | grep -qE '^(feat|fix|docs)(\(.+\))?: .+'
```

```bash
# .githooks/commit-msg
grep -qE '^(feat|fix|docs|chore)(\(.+\))?: .+' "$1"   # already drifted
```

## Right

```bash
# both call the same script
./scripts/check-commit-subject.sh "$subject"
```

## The same applies to code

A rule is the clearest case, but the principle is the same for logic. The
release tooling had three identical `build_app` invocations across `build`,
`beta` and `_release_core`; they became `app_store_build_app`. Three copies of
"find the repo root from `Dir.pwd`" became `project_root(marker)` — and the
third copy had already been written wrong, resolving to a path outside the
repository.

That is the tell worth watching for: **the second copy is a warning, the third
is a bug that has already happened.** By the time something is written three
times, one of them is subtly different and nobody knows which.

## When duplication is right

Deduplication is not free, and applied blindly it does more damage than the
repetition it removes. Two pieces of code that *look* alike but **change for
different reasons** must stay apart. Merging them creates a function with a
flag, then two flags, then a function nobody can modify safely because its
callers want opposite things.

Ask what happens next time each copy changes:

- **Same reason, always** — deduplicate. The commit format is one rule; a change
  to it must reach the hook and CI together, and the whole point is that it
  cannot reach only one.
- **Different reasons, or independently** — leave them. Similar-looking test
  fixtures, two validation rules that happen to share a regex today, a
  screenshot device list that resembles a test device list. Their similarity is
  a coincidence of the present.

Three similar lines are cheaper than the wrong abstraction. The wrong
abstraction is paid for by everyone who touches it afterwards, and it is much
harder to reverse than the duplication would have been.

## When a value must appear twice

Sometimes duplication is forced — two systems that cannot import from each
other. `GameCenterIDs` in `Services/Game/GameCenterService.swift` and
`LEADERBOARDS` / `ACHIEVEMENTS` in `fastlane/GameCenterConfig.rb` are the live
example: Swift and Ruby, no shared format.

When that happens, say so at both sites, name the counterpart, and describe what
breaks if they diverge. A comment is a weak guarantee, so prefer a check that
fails loudly — but an explicit, documented pair beats an accidental one.

## See also

- [No inline scripting in GitHub Actions](workflow-scripts.md)
- [Commit messages](commit-messages.md)
