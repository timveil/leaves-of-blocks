# Concurrency

**Default to `@MainActor`. Reach for `nonisolated` deliberately, and say why.**

This is a game whose state drives SwiftUI and a SpriteKit scene. Almost
everything belongs on the main actor; the interesting decisions are the
exceptions.

## The default

`GameState`, `GameService` and `GameCenterService` are `@MainActor` because
they are read by views and mutated in response to user input. Putting them
anywhere else buys nothing and costs a hop on every access.

```swift
@Observable
@MainActor
final class GameState { ... }
```

## When `nonisolated` is right

Three cases, all present in the codebase:

**1. A pure function that wants to be testable.** Isolation is a liability for
logic that touches no actor state — it forces every test into an async,
main-actor context for no reason.

```swift
/// Maps a finished session into the set of achievements that should be
/// reported. Pure function — no GameKit dependency, no side effects.
nonisolated static func evaluateAchievements(
    score: Int,
    sessionMetrics: PlayerBehaviorTracker.SessionMetrics?,
    longestCombo: Int
) -> [PendingAchievement]
```

That signature is why achievement rules have unit tests at all.

**2. A protocol requirement that is not isolated.** `GKGameCenterControllerDelegate`
and SwiftUI's `EnvironmentKey.defaultValue` are declared without isolation, so
conforming members must match.

**3. Failure paths that may arrive off the main actor** — `CoreDataManager`'s
load-failure handler, for instance.

## Say why, at the site

`nonisolated` is a claim that a member touches no isolated state. That claim is
invisible six months later, so record the reason:

```swift
// Wrong — the reader cannot tell whether this is deliberate or a warning fix
nonisolated static func evaluate(...) -> [PendingAchievement]

// Right
/// Pure function — no GameKit dependency, no side effects, so it can be
/// unit-tested without a main-actor context.
nonisolated static func evaluate(...) -> [PendingAchievement]
```

## Do not silence, understand

The failure mode this exists to prevent is reaching for `nonisolated`, or an
unstructured `Task`, to make a Swift 6 isolation warning go away. The warning is
usually correct: it is describing state that would genuinely be touched from two
contexts. Silencing it converts a compile-time complaint into a data race.

If a fix is a warning fix rather than a design decision, say that in the commit
so the next reader knows it was expedient rather than considered.

## Enforcement

The compiler, under Swift 6 language mode — which is why the codebase has
`fix: Resolve Swift 6 actor-isolation and unused-try warnings` in its history.
Whether an escape hatch is *justified* is review's job.
