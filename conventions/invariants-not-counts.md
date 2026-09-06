# State the invariant, not the count

**Documentation says what is always true, not what happened to be true the
afternoon it was written.**

A count rots. Worse than going quietly stale, a wrong count makes a document
read as **incorrect while the rule it describes is still being followed** — so
readers learn to distrust the document rather than to trust the rule. That is a
worse outcome than having written nothing.

## Wrong

```markdown
`LeavesOfBlocksTests/` has fully converted — all 26 test files import `Testing`.
The codebase has 13 files using `@MainActor`.
This array contains 21 predefined shapes.
The project is Swift 6.
```

## Right

```markdown
`LeavesOfBlocksTests/` has fully converted: every unit test file imports
`Testing`, and none import `XCTest`.
Most of the app is main-actor isolated.
This array contains the predefined shapes used by `BlockGenerator`.
Swift 5 language mode — read `SWIFT_VERSION` rather than assuming.
```

An invariant survives the codebase growing. A count is a measurement, and
nothing re-measures it.

## The test

**Would this number become wrong through ordinary work that nobody intended to
change it?** Adding a test file, adding a block shape, extracting a helper. If
yes, write the invariant instead.

A second tell: if the number cannot be checked without counting something
yourself, a reader cannot tell whether it is still true. "13 files using
`@MainActor`" never said whether tests were included — unfalsifiable as well as
drift-prone.

## Version numbers are the same problem

`SWIFT_VERSION` is `5.0`, and a command file asserted the project was Swift 6.
Where a version must appear, it belongs in exactly one place that something
reads — `.xcode-version`, `IPHONEOS_DEPLOYMENT_TARGET` — and prose should point
at that rather than restate it. See [one rule, one definition](shared-rule-single-source.md).

## Where numbers are still fine

This is not a rule against numbers, and reading it that way would make it
useless:

- **Product facts that define behavior** — the 8×8 grid, the 7-day phased
  rollout, a 4+ age rating. Decisions, not measurements of the code.
- **Historical statements about one moment** — a commit message or PR body
  saying "9 suites pass" describes that run and is never maintained afterwards.
- **Anything a check verifies**, because it cannot then rot silently.

## Where this came from

The cases that prompted it, one of which was live in the source:

- `BlockModels.swift` said "21 predefined shapes" while the array held 22. The
  website said 22. A shape was added and the comment stayed behind.
- `testing.md` said "all 26 test files", corrected in #92.
- The Claude review commands said "13 files using `@MainActor`" and "five of
  those", corrected in #106 — written hours after the `testing.md` correction,
  by the same author, who had just written that correction.

That last one is the case for having a written rule rather than an intention.

## Enforcement

Review. A linter for numbers in prose would flag the 8×8 grid and the 7-day
rollout alongside the real cases, and a check that cries wolf gets ignored.

The one exception is the deployment target, which is stated across several
documents and is therefore worth machine-checking:
[`scripts/check-docs-versions.sh`](../scripts/check-docs-versions.sh) reads it
from `project.pbxproj` and fails on any document that disagrees.
