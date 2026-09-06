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

- `fastlane/Constants.rb` holds `XCODE_VERSION`, read by every lane, rather than
  a version string per lane.
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
