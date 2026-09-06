Review the whole project, not a diff. For reviewing changes on a branch, use `/code-review-recent` instead — it covers the per-change rules and this command does not repeat them.

## Read the rules first, do not recall them

- [`conventions/README.md`](../../conventions/README.md) — index of all project rules
- [`LeavesOfBlocks/Documentation/CodingStandards.md`](../../LeavesOfBlocks/Documentation/CodingStandards.md) — Swift formatting, naming, file organization, DocC
- [`CLAUDE.md`](../../CLAUDE.md) — architecture and release flow

## What this project is

SwiftUI + SpriteKit, `@Observable`, Core Data, opt-in GameKit. Swift 5 language mode — read `SWIFT_VERSION` rather than assuming. **No UIKit view controllers, no auto layout, no Combine, no networking.** Deployment target is read from `IPHONEOS_DEPLOYMENT_TARGET`; do not assume it.

## Whole-project questions worth asking

These are the ones a per-change review cannot see, which is the only reason this command exists separately.

**Has the logic boundary eroded?** `GameLogic` should be static and stateless, `GameState` should own mutation, and the SpriteKit scene should never write back. Erosion happens one convenient exception at a time. Check whether rules have accumulated in view bodies, and whether `GameState` has grown logic that could be a pure function and therefore a test.

**Is anything unreachable or unused?** Dead shapes, unreferenced assets, `Localizable.xcstrings` keys with no call site, helpers left behind by a refactor. Unused localized keys are worth naming specifically — they are invisible and they cost translation effort.

**Is the concurrency model coherent, or a collection of local fixes?** Count the `nonisolated` sites and ask whether each is a design decision or a warning that got silenced. Most of the app is main-actor isolated; a scattering of exceptions with no stated reason is the shape of drift.

**Where is behavior untested that could be?** `GameLogic` is pure and therefore cheap to test — anything there without coverage is a gap with no excuse. Conversely, look for tests that cannot fail: fixtures never asserted, assertions vacuously true, suites whose output is discarded. See [`tdd.md`](../../conventions/tdd.md), which lists the ones this codebase has already produced.

**Does the privacy posture still hold end to end?** No third-party runtime dependencies, no network path except opt-in GameKit, and `PrivacyInfo.xcprivacy` consistent with what the code actually does. This is a claim the project makes publicly, so it is worth verifying rather than assuming.

**Is anything in the game loop doing work it should not?** Allocation, string interpolation for logging that release never emits, or repeated work per frame that could be hoisted. See the note in [`logging.md`](../../conventions/logging.md) about interpolation happening before the level guard.

## What not to do

**Do not fix compilation or run the test suite as part of the review.** CI does that on every pull request. Editing while reviewing muddies what was found and what was changed.

Do not restate the conventions back as findings. "The project should localize strings" is not a finding; "`SettingsView.swift:42` has a hardcoded title" is.

## Output

Grouped by consequence:

1. **Defects** — something is wrong now. File, line, what breaks.
2. **Erosion** — a rule the project has written down is being followed less consistently than it was. Cite the convention and the examples.
3. **Opportunities** — worth doing, nothing is broken. Say so plainly rather than inflating it.

Be honest about coverage: say which areas you actually read and which you did not. A whole-project review that implies uniform depth it did not have is worse than one that admits its scope.

## Relationship to `/code-review`

Claude Code ships a built-in `/code-review` and `/security-review`. Those are better at general correctness and vulnerability sweeps. This command is for the project-specific question — whether the architecture and the written conventions still hold across the whole codebase.
