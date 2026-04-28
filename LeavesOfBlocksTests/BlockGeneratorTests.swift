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
}
