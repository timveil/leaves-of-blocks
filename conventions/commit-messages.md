# Commit messages

**Every commit follows [Conventional Commits](https://www.conventionalcommits.org/).**

```
<type>(<scope>): <description>
```

The rules — the regex, the allowed types, the maximum subject width — live in
[`scripts/check-commit-subject.sh`](../scripts/check-commit-subject.sh) and
nowhere else. Read them there.

## Wrong

```
Update CHANGELOG and CLAUDE docs
Bump CURRENT_PROJECT_VERSION to 19
fix grid bug
```

## Right

```
docs: Update CHANGELOG and CLAUDE docs
chore: Bump CURRENT_PROJECT_VERSION to 19
fix(grid): Resolve block placement bug
feat(game-center): Submit final score on game over
```

## It drives the changelog

The type is not decoration. `update_changelog_from_commits` in
`fastlane/release_helpers.rb` maps types to changelog sections during a release:

| Type | Changelog section |
| --- | --- |
| `feat` | Added |
| `fix` | Fixed |
| `refactor`, `perf`, `style` | Changed |
| `revert` | Removed |
| everything else | not included |

So `chore`, `ci`, `docs`, `build` and `test` produce no changelog entry. That is
usually right — but when such a change *is* worth telling users about, add the
line to `[Unreleased]` in `CHANGELOG.md` by hand. The generator preserves manual
entries and folds them into the release.

## Trailers

`Co-Authored-By` and similar trailers belong in the body, never the subject. The
width limit applies to the subject line alone.

## Enforcement

- **Locally** — [`.githooks/commit-msg`](../.githooks/commit-msg), which needs
  `git config core.hooksPath .githooks` once per clone.
- **In CI** — [`commit-lint.yml`](../.github/workflows/commit-lint.yml), which
  lints every non-merge commit in the PR.

Never bypass the hook with `--no-verify`. CI applies the same script and will
reject the PR anyway; all you save is the walk back.

## See also

- [One rule, one definition](shared-rule-single-source.md)
