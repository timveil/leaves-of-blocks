//
//  BlockGeneratorTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the pressure-based block generator. The generator is
//  non-deterministic — it samples weighted distributions and applies
//  solvability fallbacks — so these tests assert structural invariants
//  rather than exact shape sequences.
//

import Foundation
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

    @Test("Over enough draws, all three special-block types appear at least once")
    func specialBlockDistributionCoversAllThreeTypes() {
        // Contract pin (U3): the generator picks special blocks uniformly
        // across `.horizontalClear`, `.verticalClear`, and `.areaClear`.
        // A future refactor to the special-shape pool (the round 2 plan
        // collapses `SpecialBlockType` enum into a `[BlockShape]` literal)
        // shouldn't accidentally drop a case. 400 draws on hard difficulty
        // (2% special-shape chance) gives ~24 specials in expectation —
        // well above the threshold needed to cover three uniform buckets.
        var observed: Set<BlockType> = []
        for _ in 0..<400 {
            let blocks = BlockGenerator.generateTieredBlocks(
                count: 3, difficulty: .hard, grid: emptyGrid()
            )
            for block in blocks where block.type != .normal {
                observed.insert(block.type)
            }
            if observed.count == 3 { break }
        }
        #expect(observed.contains(.horizontalClear))
        #expect(observed.contains(.verticalClear))
        #expect(observed.contains(.areaClear))
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

// MARK: - Generation Across Grid Fill Levels

/// `BlockGenerator` no longer caps block size by a grid-quality tier (see
/// `BoardPressure` and the "Pressure-Based Generation" tests below) — it
/// samples candidate sets from the same unconstrained distribution
/// regardless of how messy the board is, and picks among the solvable ones.
/// These tests construct grids at clearly different fill levels and assert
/// the generator still returns a valid + solvable set at every level, from
/// empty through "nothing but isolated single cells left."
@Suite("Generator behaves across grid fill levels")
struct GeneratorAcrossGridStatesTests {
    @Test("Empty grid produces 3 solvable blocks")
    func emptyGridProducesSolvableSet() {
        let grid = emptyGrid()
        let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
        #expect(blocks.count == 3)
        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
    }

    @Test("Half-filled grid still produces a solvable set")
    func halfFilledGridProducesSolvableSet() {
        let grid = gridFilled(rows: 0..<4)
        for _ in 0..<5 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
            #expect(blocks.count == 3)
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
        }
    }

    @Test("Near-full grid still produces a solvable set")
    func nearFullGrid() {
        // 6 of 8 rows filled — bottom 2 rows have 16 empty cells. We don't
        // assert anything about pressure or which candidates were considered
        // — just that the generator handles tight grids.
        //
        // Note: the generator's constrained fallback validates each block
        // individually before checking the set as a whole. With one row of
        // free cells the generator can emit blocks that fit individually but
        // not together — see ultimateFallbackPath for the case that does
        // force single-cell emission. Two free rows give enough headroom for
        // set placement.
        let grid = gridFilled(rows: 0..<6)
        for _ in 0..<5 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
            #expect(blocks.count == 3)
            #expect(blocks.allSatisfy { !$0.positions.isEmpty })
            #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
        }
    }

    @Test("Grid with only scattered single empty cells still yields a solvable, well-formed set")
    func ultimateFallbackPath() {
        // Fill everything except a few isolated single cells. No multi-cell
        // *normal* shape can fit anywhere, so a normal-only candidate set —
        // even in the constrained fallback — always fails
        // `canAllBlocksBePlaced`, and generation bottoms out at the terminal
        // single-cell guarantee. A drawn special is a legitimate exception:
        // it can clear real room from nothing (see
        // PressureBasedGenerationTests.specialBlockClearsRoomForLaterBlocksInTheSameBatch),
        // so the "must collapse to all 1-cell blocks" half of this test only
        // holds when no special was dealt — the "must be solvable" half
        // holds unconditionally either way.
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
        #expect(GameLogic.canAllBlocksBePlaced(blocks, in: grid))
        if !blocks.contains(where: { $0.type != .normal }) {
            // With only single isolated empty cells and no special in the
            // set, every emitted block must collapse to a 1-cell shape to
            // remain placeable.
            #expect(blocks.allSatisfy { $0.positions.count == 1 })
        }
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

// MARK: - Pressure-Based Generation (#177)

/// The generator used to pick a `TierConfiguration` from grid quality and cap
/// block size by it — the worse the board scored, the smaller everything it
/// dealt got, bottoming out at 1–3 cell blocks (`.emergency`). That rewarded
/// bad play: `GridAnalysis`'s fragmentation term can tank the quality score
/// on a board that's still mostly open (see `fragmentedButRoomyBoardIsNotCappedSmall`),
/// so a player who scattered isolated blocks around got handed nothing but
/// singles even with the rest of the board empty.
///
/// Nothing is off-limits by size now — see `BoardPressure` and
/// `BlockGenerator`'s candidate-set selection. These tests assert the two
/// observable behavior changes from the plan: a messy-but-roomy board isn't
/// capped small, and a messier board is dealt a less generous set than a
/// clean one for the same seed.
@Suite("Pressure-based generation replaces the size-tier cap")
struct PressureBasedGenerationTests {
    @Test("A sparse-but-fragmented board (old-emergency-tier territory) can still deal a block larger than 3 cells")
    func fragmentedButRoomyBoardIsNotCappedSmall() {
        // 4 isolated filled cells, one in column 0 of every other row. Old
        // tier math: GridAnalysis.calculateFragmentation scores every one of
        // those cells as fully isolated (fragmentation = 1.0), which — at a
        // weight of -0.25 in qualityScore — drags the score to 0 even though
        // 94% of the board (60 of 64 cells) is open and empty.
        // GridAnalysis.DifficultyTier.fromQualityScore(0) == .emergency,
        // which used to cap every dealt block at 3 cells
        // (TierConfiguration.emergency.maxBlockSize). The new generator
        // doesn't cap by size, so it should be free to deal something bigger
        // given all the open room.
        var grid = GameLogic.createEmptyGrid()
        for row in stride(from: 0, to: 8, by: 2) {
            grid[row][0].isFilled = true
        }
        #expect(GridAnalysis.determineDifficultyTier(for: grid) == .emergency, "test grid no longer reproduces the old-emergency-tier scenario this test targets")

        var sawLargerThanThree = false
        for _ in 0..<40 {
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
            if blocks.contains(where: { $0.positions.count > 3 }) {
                sawLargerThanThree = true
                break
            }
        }
        #expect(sawLargerThanThree, "generator never dealt a block larger than 3 cells on a 94%-open board across 40 draws")
    }

    @Test("A messier board is dealt a less mobile set than an empty board, for the same seed and blocksPlaced")
    func messierBoardDealsLessMobileSet() {
        func totalMobility(grid: [[GridCell]], seed: UInt64) -> Int {
            var generator: any RandomNumberGenerator = SeededGenerator(seed: seed)
            let blocks = BlockGenerator.generateTieredBlocks(
                count: 3,
                difficulty: .moderate,
                grid: grid,
                blocksPlaced: 0,
                using: &generator
            )
            return blocks.reduce(0) { $0 + GameLogic.findValidPositions(for: $1, in: grid).count }
        }

        let clean = emptyGrid()
        let messy = gridFilled(rows: 0..<6)
        let seed: UInt64 = 42

        #expect(totalMobility(grid: messy, seed: seed) < totalMobility(grid: clean, seed: seed))
    }

    @Test("A special block's clearing effect is reflected in what's drawn alongside it in the same batch")
    func specialBlockClearsRoomForLaterBlocksInTheSameBatch() {
        // Fully filled grid. If a drawn special's clear isn't credited on
        // the scratch grid used to draw the *other* blocks in the same
        // batch, no normal block dealt alongside it can ever find room —
        // scratch would still read as 100% full — and every such draw
        // degrades all the way to the guaranteed single-cell terminal
        // fallback. If the clear *is* credited, drawing a normal block
        // after a special should sometimes land somewhere genuinely
        // larger than 1 cell, reflecting the room the special just opened.
        var grid = GameLogic.createEmptyGrid()
        for row in 0..<8 {
            for col in 0..<8 {
                grid[row][col].isFilled = true
            }
        }

        var sawLargerNormalAlongsideASpecial = false
        for seed: UInt64 in 1...300 {
            var generator: any RandomNumberGenerator = SeededGenerator(seed: seed)
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, difficulty: .hard, grid: grid, using: &generator)
            let hasSpecial = blocks.contains { $0.type != .normal }
            let hasLargerNormal = blocks.contains { $0.type == .normal && $0.positions.count > 1 }
            if hasSpecial && hasLargerNormal {
                sawLargerNormalAlongsideASpecial = true
                break
            }
        }

        #expect(sawLargerNormalAlongsideASpecial, "no draw across 300 seeds paired a special with a >1-cell normal block on a full grid — the special's clear doesn't seem to reach the rest of the batch")
    }

    @Test("Generation stays well under a frame budget, even when every candidate falls back")
    func generationIsFastEnoughForOneFramePerCall() {
        // generateTieredBlocks runs on the main actor (called from
        // GameState), so it must stay well under one frame (16ms,
        // AppConfiguration.Performance.animationFrameRate = 60) on
        // device-class hardware — see the PR #177 plan's verification
        // section. Sampling pressureCandidateCount (10) unconstrained
        // candidates plus, on a hard grid, pressureFallbackCandidateCount
        // (10) more constrained ones is the worst case; a scattered
        // near-full grid forces exactly that path (see
        // fragmentedButRoomyBoardIsNotCappedSmall / the constrained-fallback
        // tests above for why). CI hardware is slower and noisier than a
        // device, so the bound here is generous — this is a regression
        // trip-wire for a catastrophic slowdown, not a precise budget check.
        var grid = GameLogic.createEmptyGrid()
        for row in 0..<8 {
            for col in 0..<8 {
                grid[row][col].isFilled = true
            }
        }
        for row in stride(from: 0, to: 8, by: 2) {
            grid[row][0].isFilled = false
        }

        // The fastest of several short batches, not the mean of one long run.
        // Contention from parallel test workers only ever makes a batch
        // slower, so the minimum is the closest reading of what the code
        // costs; a single mean averaged in every stall and failed at
        // 111-155ms/call on a loaded iOS 27 simulator (#181). A real
        // slowdown still trips it, because it makes every batch slow.
        let batches = 10
        let callsPerBatch = 2
        var perCall = Double.infinity
        for _ in 0..<batches {
            let start = CFAbsoluteTimeGetCurrent()
            for _ in 0..<callsPerBatch {
                _ = BlockGenerator.generateTieredBlocks(count: 3, difficulty: .hard, grid: grid)
            }
            perCall = min(perCall, (CFAbsoluteTimeGetCurrent() - start) / Double(callsPerBatch))
        }

        // Measured ~10ms/call on both this grid and a 6-rows-filled "typical
        // mid-game" grid on development hardware — comfortably under the
        // 16ms budget. The opt-in calibration report (GameSimulationTests.swift)
        // can still run long at large scale, but that's overwhelmingly
        // GreedyBot/LookaheadBot's own search cost across thousands of
        // simulated turns, not this function; see its `.timeLimit` trait.
        #expect(perCall < 0.1, "generateTieredBlocks took \(String(format: "%.4f", perCall))s/call in its fastest of \(batches) batches on a worst-case grid — investigate before this reaches a device")
    }
}
