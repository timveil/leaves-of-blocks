Review the changes on this branch relative to `main`.

## Read the rules first, do not recall them

This project writes its rules down. Read them rather than reviewing from general Swift knowledge, and cite the file when something violates one:

- [`conventions/README.md`](../../conventions/README.md) — index of all project rules
- [`LeavesOfBlocks/Documentation/CodingStandards.md`](../../LeavesOfBlocks/Documentation/CodingStandards.md) — Swift formatting, naming, file organization, DocC
- [`CLAUDE.md`](../../CLAUDE.md) — architecture and release flow

Anything below that repeats a convention is a summary for orientation. The convention file wins.

## What this project is

SwiftUI + SpriteKit, `@Observable`, Core Data, opt-in GameKit. Swift 5 language mode — read `SWIFT_VERSION` rather than assuming. **No UIKit view controllers, no auto layout, no Combine, no networking.** If a review comment is about constraints, `viewDidLoad`, publishers or URL sessions, it is about a different app.

## The invariants worth checking on every change

- **Rules stay out of views.** `GameLogic` is pure static functions; `GameState` owns mutation; the SpriteKit scene observes and never writes back. A rule that moved into a view body is the most damaging change this codebase can absorb, because it becomes untestable. See [`game-logic-boundary.md`](../../conventions/game-logic-boundary.md).
- **Every user-visible string goes through `.localized`** — `Text`, `Button`, `navigationTitle`, accessibility labels, **and previews**. Previews are where this leaks. See [`localization.md`](../../conventions/localization.md).
- **No third-party runtime dependencies.** A new package reference is a blocking comment, not a nit — it invalidates the privacy posture. See [`runtime-dependencies.md`](../../conventions/runtime-dependencies.md).
- **`@MainActor` by default; `nonisolated` deliberately and with a stated reason.** Watch for `nonisolated` or an unstructured `Task` used to silence an actor-isolation warning rather than to express a design. See [`concurrency.md`](../../conventions/concurrency.md).
- **`BuildConfiguration.log`, never `print`** outside `#Preview`. See [`logging.md`](../../conventions/logging.md).
- **Tests came first, and can actually fail.** New behavior without a test, or a test that would pass against broken code, is worth flagging. Watch specifically for assertions that cannot fail. See [`tdd.md`](../../conventions/tdd.md).

## Also look for

- Duplication that is genuinely the same thing, and duplication that only looks alike — see [`shared-rule-single-source.md`](../../conventions/shared-rule-single-source.md) on when *not* to deduplicate
- Force unwrapping, and error paths that are unreachable because an earlier guard swallows them
- Retain cycles in closures captured by `GameState`, the scene bridge, or Core Data observers
- Work on the main actor that does not need to be there, particularly in the game loop

## What not to do

**Do not fix compilation or run the test suite as part of the review.** CI compiles, tests, lints commit subjects and PR titles on every pull request. Editing while reviewing muddies what was found and what was changed — report, then let the author decide.

## Output

Findings ordered by consequence, each with the file, the line, and what breaks. Say plainly when you found nothing in a category rather than padding. If a finding is a judgement call rather than a defect, say which.

## Relationship to `/code-review`

Claude Code ships a built-in `/code-review` with effort levels, and `/security-review`. Use those for general correctness sweeps. Use this command when the question is **"does this follow the conventions this project has written down"** — that is the part the built-in cannot know.
