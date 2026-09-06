# Testing

**New unit tests use the [Swift Testing](https://developer.apple.com/documentation/testing)
framework**, with descriptive `@Test` names and a Given-When-Then body.

`LeavesOfBlocksTests/` has fully converted: every unit test file imports
`Testing`, and none import `XCTest`. `LeavesOfBlocksUITests/` remains XCTest,
because UI automation still requires `XCUIApplication`.

## Shape

```swift
@Suite("GameLogic.clearCompletedLines")
struct LineClearingTests {
    @Test("Clearing a completed row empties exactly that row")
    func clearingACompletedRowEmptiesThatRow() {
        // Given a grid with row 3 filled edge to edge
        var grid = GameLogic.createEmptyGrid()
        for col in 0..<8 {
            grid[3][col].isFilled = true
        }

        // When the completed lines are cleared
        let result = GameLogic.clearCompletedLines(in: &grid)

        // Then only that row is reported, and it is now empty
        #expect(result.clearedRows == [3])
        #expect(result.clearedCols.isEmpty)
        #expect(grid[3].allSatisfy { !$0.isFilled })
    }
}
```

Group related tests in a `@Suite` named for the thing under test. The `@Test`
string is a sentence about behavior and the function name mirrors it — the
existing tests do not write literal `// Given` markers, so treat the three-part
structure as a shape to follow rather than a comment template to fill in.

A good name tells you what broke from the failure line alone:
`clearingACompletedRowEmptiesThatRow` does; `testClearLines` does not.

## Where to add coverage

`Logic/Game/GameLogic.swift` is pure — static functions, no state, no
dependencies — which makes it the cheapest place in the codebase to add a
meaningful test. `GameCenterService.evaluateAchievements(...)` is deliberately
`nonisolated static` for the same reason.

## UI tests

Drive real flows, and wait on conditions rather than clocks:

```swift
// Wrong — flaky under CI load
sleep(2)
XCTAssertTrue(app.buttons["play"].exists)

// Right
XCTAssertTrue(app.buttons["play"].waitForExistence(timeout: 5))
```

## Shell and Ruby

Scripts extracted from workflows get a companion `test-*.sh` — see
[workflow scripts](workflow-scripts.md). These are plain bash: no framework,
exit non-zero on failure, runnable directly.

Worth knowing when you write one: it is easy to build a harness that reports
success while silently discarding assertions. After adding tests, break the
thing under test on purpose and confirm the tests actually go red.

## Running

```bash
./scripts/build.sh test         # full suite, parallel
./scripts/build.sh test-unit    # unit only
./scripts/build.sh test-ui      # UI only
```

Swift Testing suites cannot be filtered with `-only-testing:Target/SuiteStruct`
the way XCTest classes can.
