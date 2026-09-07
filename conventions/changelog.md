# Changelog entries are authored, not derived

**A pull request that changes something a player can observe adds the line
saying so, under `## [Unreleased]` in `CHANGELOG.md`.**

Write it for someone playing the game, not for someone reading the diff.

## Why it cannot be left to the release

`update_changelog_from_commits` will happily fill `[Unreleased]` during a
release. It reads commit **subjects** — which describe the code, to developers —
and `generate_release_notes` renders the result into
`fastlane/metadata/*/release_notes.txt` for every locale, which `deliver`
uploads. All of that happens inside one `deploy`.

So the first time anyone sees the sentence a player reads on the App Store, it
has already been written, committed, localized and uploaded. There is no point
in that chain where a person reads it and says no.

It is also a lossy rendering of the wrong source. Six pull requests added six
languages between v2.0.7 and 2.1.0. No commit subject says "the game is now
playable in seven languages", because no single commit did that — it is a fact
about the release, visible only to someone standing at the end of it. Twenty-six
subjects cannot be assembled into it afterwards.

## Wrong

```markdown
## [Unreleased]

### Added

### Changed

### Fixed
```

Twenty-six commits, six of them adding a language, arrived against exactly this.
Nothing was wrong with any individual commit message.

```markdown
### Added
- Add French, Dutch and Korean localizations (#146)
```

A commit subject with the type filed off. It names a pull request, uses the
imperative voice of a diff, and tells a player nothing they can act on.

## Right

```markdown
## [Unreleased]

### Added
- Play in seven languages — the game and its App Store listing are now
  available in English, Spanish, German, Japanese, French, Dutch and Korean

### Fixed
- Stop the board crashing when the game is played in Spanish
```

## What is player-visible

The app target and the project's build settings — `LeavesOfBlocks/**` and
`LeavesOfBlocks.xcodeproj/**`. Documentation inside the app directory is not.

Build settings are included because of what hides there: #89 changed
`IPHONEOS_DEPLOYMENT_TARGET` and with it who could install the app, touching no
Swift at all.

Scripts, fastlane, workflows, conventions and both test targets are not
player-visible. A change to them needs no entry — though one is welcome when it
genuinely affects players, and the release generator ignores those commit types
entirely, so the manual line is the only way such a change is ever mentioned.

## What enforces it

[`scripts/check-changelog.sh`](../scripts/check-changelog.sh), called by
[`.github/workflows/changelog.yml`](../.github/workflows/changelog.yml) on every
pull request. It decides from changed paths alone whether an entry is required
and whether `CHANGELOG.md` was touched.

Whether the entry is any *good* is a review question, and this check does not
pretend to answer it.

At release time, `preflight` requires `[Unreleased]` to hold real entries rather
than empty headers — it counted lines before, so a block of three empty
subsection headers passed as a five-line section.

## The exception

Label the pull request **`no-changelog`** when the change genuinely cannot be
observed by a player. Refactors with no behavior change, test-only work inside
the app target, and comment or documentation edits qualify.

Use it rather than writing a junk entry to get green. An invented line costs
more than a skipped one: it ends up in the App Store release notes.

## Generation is the backstop, not the author

When `[Unreleased]` holds authored entries, they *are* the release section and
nothing is derived on top of them. Appending generated bullets described the
same work twice — deduplication compares exact strings, so "Play in seven
languages" and "Add French, Dutch and Korean localizations" both survived — and
swept in CI and test commits no player could observe.

Generation still runs when nobody authored anything, so a release is never left
with no notes at all. That path is the safety net. It is not the plan.
