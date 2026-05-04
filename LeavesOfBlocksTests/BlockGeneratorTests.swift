//
//  BlockGeneratorTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the tier-based block generator. The generator is non-deterministic
//  — it samples weighted distributions and applies solvability fallbacks — so
//  these tests assert structural invariants rather than exact shape sequences.
//

import Testing
@testable import LeavesOfBlocks

// MARK: - Test Helpers

private func emptyGrid() -> [[GridCell]] {
    GameLogic.createEmptyGrid()
}

private func gridWith(filled: [(Int, Int)]) -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for (row, col) in filled {
        grid[row][col].isFilled = true
    }
    return grid
}

private func gridFilled(rows: Range<Int>) -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for row in rows {
        for col in 0..<8 {
            grid[row][col].isFilled = true
        }
    }
    return grid
}

// MARK: - Output Shape

@Suite("BlockGenerator.generateTieredBlocks output shape")
struct GenerateTieredBlocksOutputTests {
    @Test("Returns the requested count by default")
    func defaultCount() {
        let blocks = BlockGenerator.generateTieredBlocks(grid: emptyGrid())
        #expect(blocks.count == 3)
    }

    @Test("Honors a custom count")
    func customCount() {
        let blocks = BlockGenerator.generateTieredBlocks(count: 5, grid: emptyGrid())
        #expect(blocks.count == 5)
    }

    @Test("Honors count = 1")
    func single() {
        let blocks = BlockGenerator.generateTieredBlocks(count: 1, grid: emptyGrid())
        #expect(blocks.count == 1)
    }
}

// MARK: - Block Validity

@Suite("Generated blocks are well-formed")
struct GeneratedBlockValidityTests {
    @Test("Every generated block has at least one position")
    func nonEmptyPositions() {
        for difficulty in DifficultyMode.allCases {
            let blocks = BlockGenerator.generateTieredBlocks(
                count: 3,
                difficulty: difficulty,
                grid: emptyGrid()
            )
            for block in blocks {
                #expect(!block.positions.isEmpty)
            }
        }
    }

    @Test("Generated blocks have one of the known BlockTypes")
    func validTypes() {
        let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: emptyGrid())
        for block in blocks {
            switch block.type {
            case .normal, .horizontalClear, .verticalClear, .areaClear:
                break
            }
        }
    }

    @Test("All shapes fit within the 8x8 grid bounds")
    func fitsInGrid() {
        // Run the generator multiple times to exercise the random space.
        for _ in 0..<20 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: emptyGrid())
            for block in blocks {
                let bounds = block.getBounds()
                #expect(bounds.width <= 8)
                #expect(bounds.height <= 8)
            }
        }
    }
}

// MARK: - Solvability

@Suite("Generated blocks are solvable on the current grid")
struct GeneratedBlockSolvabilityTests {
    @Test("Generated set can be placed somewhere on an empty grid")
    func emptyGridIsSolvable() {
        for _ in 0..<10 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: emptyGrid())
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: emptyGrid()))
        }
    }

    @Test("Generated set can be placed when the grid is partially filled")
    func partialGridIsSolvable() {
        let grid = gridWith(filled: [
            (0, 0), (0, 1), (0, 2),
            (1, 0), (1, 1)
        ])
        for _ in 0..<10 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
        }
    }
}

// MARK: - Difficulty Influence

@Suite("Difficulty bias")
struct GeneratedBlockDifficultyTests {
    @Test("Easy difficulty produces blocks no larger than hard difficulty on average")
    func easyAverageBlockSize() {
        // Sampling-based: with enough trials easy should bias smaller. We assert
        // the weak invariant that the easy mean is ≤ the hard mean.
        let trials = 30
        var easyTotalCells = 0
        var hardTotalCells = 0
        for _ in 0..<trials {
            for block in BlockGenerator.generateTieredBlocks(count: 3, difficulty: .easy, grid: emptyGrid()) {
                easyTotalCells += block.positions.count
            }
            for block in BlockGenerator.generateTieredBlocks(count: 3, difficulty: .hard, grid: emptyGrid()) {
                hardTotalCells += block.positions.count
            }
        }
        #expect(easyTotalCells <= hardTotalCells)
    }

    @Test("All difficulty modes produce valid solvable blocks on an empty grid",
          arguments: DifficultyMode.allCases)
    func everyDifficultyIsViable(difficulty: DifficultyMode) {
        // Drives the easy / moderate / hard weight tables (getEasyWeight /
        // getModerateWeight / getHardWeight) which were previously only
        // reached for the default `.easy` arg in many tests.
        for _ in 0..<5 {
            let blocks = BlockGenerator.generateTieredBlocks(
                count: 3,
                difficulty: difficulty,
                grid: emptyGrid()
            )
            #expect(blocks.count == 3)
            #expect(blocks.allSatisfy { !$0.positions.isEmpty })
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: emptyGrid()))
        }
    }
}

// MARK: - Legacy Public API

@Suite("BlockGenerator.generateWeightedBlocks (legacy entry point)")
struct GenerateWeightedBlocksTests {
    @Test("Returns the requested count, well-formed blocks, and a solvable set")
    func basicInvariants() {
        for difficulty in DifficultyMode.allCases {
            let blocks = BlockGenerator.generateWeightedBlocks(
                count: 4,
                difficulty: difficulty,
                grid: emptyGrid()
            )
            #expect(blocks.count == 4)
            #expect(blocks.allSatisfy { !$0.positions.isEmpty })
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: emptyGrid()))
        }
    }

    @Test("Default arguments yield 3 easy blocks")
    func defaultArguments() {
        let blocks = BlockGenerator.generateWeightedBlocks(grid: emptyGrid())
        #expect(blocks.count == 3)
    }
}

// MARK: - Tier-driven Generation

/// Each tier in `GridAnalysis.DifficultyTier` selects a different
/// `TierConfiguration` (diverse / constrained / minimal / emergency), and
/// each configuration drives a different branch through generateBlocksForTier.
/// We construct grids with clearly different fill levels so we can assert
/// the generator still returns a valid + solvable set in each regime.
@Suite("Generator behaves on grids across difficulty tiers")
struct TierDrivenGenerationTests {
    @Test("Empty grid (typically diverse tier) produces 3 solvable blocks")
    func diverseTier() {
        let grid = emptyGrid()
        let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
        #expect(blocks.count == 3)
        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
    }

    @Test("Half-filled grid (typically constrained/minimal tier) still produces a solvable set")
    func constrainedTier() {
        let grid = gridFilled(rows: 0..<4)
        for _ in 0..<5 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
            #expect(blocks.count == 3)
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
        }
    }

    @Test("Near-full grid still produces a solvable set under tier downgrade")
    func nearFullGrid() {
        // 6 of 8 rows filled — bottom 2 rows have 16 empty cells. Pushes
        // GridAnalysis toward minimal/emergency tiers, exercising the smaller
        // TierConfigurations and the ensureTieredSolvability path. We don't
        // assert which tier we land in (quality score is sensitive to several
        // grid metrics) — just that the generator handles tight grids.
        //
        // Note: the generator's fallback validates each block individually,
        // not the set as a whole. With one row of free cells the generator
        // can emit blocks that fit individually but not together — see
        // ultimateFallbackPath for the case that does force single-cell
        // emission. Two free rows give enough headroom for set placement.
        let grid = gridFilled(rows: 0..<6)
        for _ in 0..<5 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
            #expect(blocks.count == 3)
            #expect(blocks.allSatisfy { !$0.positions.isEmpty })
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
        }
    }

    @Test("Grid with only scattered single empty cells forces guaranteed-solvable singles")
    func ultimateFallbackPath() {
        // Fill everything except a few isolated single cells. No multi-cell
        // shape can fit; the generator must end up emitting single-cell
        // blocks via the generateSmallerBlockForTier / generateMinimumViableChallenge
        // fallback chain (each multi-cell candidate has zero valid positions,
        // so adjustBlocksForTier degrades each block down to size 1).
        var grid = GameLogic.createEmptyGrid()
        for row in 0..<8 {
            for col in 0..<8 {
                grid[row][col].isFilled = true
            }
        }
        // Punch out 3 isolated holes (no two adjacent).
        grid[0][0].isFilled = false
        grid[3][3].isFilled = false
        grid[7][7].isFilled = false

        let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
        #expect(blocks.count == 3)
        // With only single isolated empty cells, every emitted block must
        // collapse to a 1-cell shape to remain placeable.
        #expect(blocks.allSatisfy { $0.positions.count == 1 })
        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
    }

    @Test("One-row-empty grid: generator degrades to single-cell blocks rather than emitting an unsolvable set")
    func oneRowEmptyForcesSetSolvableFallback() {
        // Regression test. Previously: 7 rows filled (8 cells empty in row 7)
        // + count: 3 could yield three triominoes (9 cells > 8 available).
        // adjustBlocksForTier saw each triomino fits *individually* in row 7
        // and did nothing; the terminal generateMinimumViableChallenge then
        // re-picked size-≤3 blocks without verifying set placement, so the
        // generator handed back an unsolvable set. Fix: the terminal fallback
        // now re-checks GameLogic.canAllBlocksBePlaced and degrades to single
        // cells when the picks oversubscribe the available empty cells.
        let grid = gridFilled(rows: 0..<7)
        for _ in 0..<10 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
            #expect(blocks.count == 3)
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
        }
    }
}

// MARK: - BehaviorTracker Integration

@Suite("Generator accepts and survives a PlayerBehaviorTracker")
struct GenerateWithBehaviorTrackerTests {
    @Test("Passing a tracker on an empty grid is a no-op for output validity")
    func trackerOnEmptyGrid() {
        let tracker = PlayerBehaviorTracker()
        let blocks = BlockGenerator.generateTieredBlocks(
            count: 3,
            difficulty: .moderate,
            grid: emptyGrid(),
            behaviorTracker: tracker
        )
        #expect(blocks.count == 3)
        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: emptyGrid()))
    }

    @Test("Passing a tracker through the fallback path doesn't crash and still yields placeable blocks")
    func trackerThroughFallback() {
        // Same constraint as ultimateFallbackPath — forces fallback execution
        // which is the path that consults the tracker
        // (recordFallbackActivation).
        var grid = GameLogic.createEmptyGrid()
        for row in 0..<8 {
            for col in 0..<8 {
                grid[row][col].isFilled = true
            }
        }
        grid[0][0].isFilled = false
        grid[7][7].isFilled = false

        let tracker = PlayerBehaviorTracker()
        let blocks = BlockGenerator.generateTieredBlocks(
            count: 2,
            difficulty: .hard,
            grid: grid,
            behaviorTracker: tracker
        )
        #expect(blocks.count == 2)
        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
    }
}

// MARK: - Count Edge Cases

@Suite("Count edge cases")
struct CountEdgeCaseTests {
    @Test("count: 0 returns an empty array")
    func zeroCount() {
        let blocks = BlockGenerator.generateTieredBlocks(count: 0, grid: emptyGrid())
        #expect(blocks.isEmpty)
    }

    @Test("Larger count (10) still yields the requested number of well-formed blocks")
    func largeCount() {
        let blocks = BlockGenerator.generateTieredBlocks(count: 10, grid: emptyGrid())
        #expect(blocks.count == 10)
        #expect(blocks.allSatisfy { !$0.positions.isEmpty })
    }
}
