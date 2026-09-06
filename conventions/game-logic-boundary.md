# Keep the rules out of the view

**Game rules live in `GameLogic` as pure functions. `GameState` owns all
mutation. The SpriteKit scene observes and never writes back.**

That separation is the reason the game's rules are testable at all, and it is
the first thing that erodes under a deadline.

## The three layers

| Layer | Owns | Never |
| --- | --- | --- |
| `Logic/Game/GameLogic` | The rules: placement validity, line clearing, scoring, game-over | Holds state, touches views, reaches for the grid it was not given |
| `Models/Game/GameState` | The live grid, score, current blocks; every mutation | Contains rule logic that could be a pure function |
| `SpriteKit/` | Drawing what state says | Deciding anything, or mutating state |

`GameLogic` is 26 `static` functions with no stored state. Everything it needs
arrives as a parameter and everything it decides comes back as a return value.

The one thing it does besides compute is log — two `BuildConfiguration.log`
calls in the grid-fill path. That is a deliberate tolerance rather than a hole
in the rule: logging cannot change a return value, so it cannot make a test
non-deterministic. Anything that *could* — reading a clock, a random source
without a passed-in generator, `UserDefaults`, the file system — is a parameter,
not a lookup.

## Why it is worth defending

A rule expressed as a pure function can be tested by calling it. The same rule
expressed inside a view body needs a running app, a simulator and a gesture, and
in practice will not be tested at all.

`GameLogic.clearCompletedLines(in:)` is a function call in a test. The same
logic inlined into `BoardView` would need a UI test that drags a block — an
order of magnitude slower, flakier, and unable to check the interesting cases
(a full row *and* column at once, a clear that completes nothing).

## Wrong

```swift
// In a view: the rule is now untestable without a simulator
if grid[row].allSatisfy({ $0.isFilled }) {
    score += 100
    for col in 0..<8 { grid[row][col].isFilled = false }
}
```

## Right

```swift
// GameLogic — the rule, callable from a test
static func clearCompletedLines(in grid: inout [[GridCell]])
    -> (clearedRows: Set<Int>, clearedCols: Set<Int>, clearedCells: [ClearedCell])

// GameState — the mutation, in one place
let result = GameLogic.clearCompletedLines(in: &grid)
score += GameLogic.calculateLineScore(
    clearedRows: result.clearedRows.count,
    clearedCols: result.clearedCols.count
)
```

## The bridge runs one way

`GameSceneBridge` re-registers `withObservationTracking` when `GameState`
changes, so the scene redraws without polling. The direction matters:

```
SwiftUI ──mutates──▶ GameState ──observed by──▶ GameSceneBridge ──▶ SKScene
```

Nothing flows back. A scene that writes to `GameState` creates a loop where the
thing being observed is changed by its own observer, and the symptom — a redraw
storm, or state that changes without a user action — surfaces far from the
cause.

Drag state travels *into* the scene through the bridge (`updatePreview`), which
is the same direction: SwiftUI decides, the scene displays.

## Where to put new rules

In `GameLogic`, as a static function taking what it needs. If it wants to read
`GameState` directly, that is the signal it is holding state it should have been
handed.

`GameCenterService.evaluateAchievements` follows the same shape for a different
subsystem — `nonisolated static`, no GameKit dependency, unit-tested. See
[concurrency](concurrency.md).

## Enforcement

Review. The practical tell is a pull request that changes a rule without
changing a test — if the rule were where it belongs, a test could reach it.
