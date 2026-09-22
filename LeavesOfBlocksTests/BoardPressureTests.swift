//
//  BoardPressureTests.swift
//  LeavesOfBlocksTests
//
//  BoardPressure is the pure function `BlockGenerator` consults to decide
//  where on a candidate-set's helpfulness ranking to deal from (issue #177).
//  These are property-style tests — the exact weighting is a tuning knob,
//  so we pin bounds and monotonicity rather than precise values.
//

import Testing
@testable import LeavesOfBlocks

private func emptyGrid() -> [[GridCell]] {
    GameLogic.createEmptyGrid()
}

private func fullGrid() -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for row in 0..<8 {
        for col in 0..<8 {
            grid[row][col].isFilled = true
        }
    }
    return grid
}

/// Every other cell in every other row — dense-ish, and every filled cell is
/// isolated (no filled neighbor), so both `fragmentation` (GridAnalysis) and
/// the dead-empty-cell signal read high without the board being anywhere
/// near full.
private func scatteredGrid() -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for row in stride(from: 0, to: 8, by: 2) {
        for col in stride(from: 0, to: 8, by: 2) {
            grid[row][col].isFilled = true
        }
    }
    return grid
}

@Suite("BoardPressure.calculate")
struct BoardPressureTests {
    @Test("Always returns a value in 0...1", arguments: DifficultyMode.allCases)
    func boundedRange(difficulty: DifficultyMode) {
        for grid in [emptyGrid(), fullGrid(), scatteredGrid()] {
            for blocksPlaced in [0, 10, 500] {
                let pressure = BoardPressure.calculate(grid: grid, blocksPlaced: blocksPlaced, difficulty: difficulty)
                #expect((0.0...1.0).contains(pressure), "difficulty=\(difficulty) blocksPlaced=\(blocksPlaced) pressure=\(pressure) out of range")
            }
        }
    }

    @Test("An empty grid at the start of a game reads near-zero pressure", arguments: DifficultyMode.allCases)
    func emptyBoardIsCalm(difficulty: DifficultyMode) {
        let pressure = BoardPressure.calculate(grid: emptyGrid(), blocksPlaced: 0, difficulty: difficulty)
        #expect(pressure < 0.1, "difficulty=\(difficulty) pressure=\(pressure) should be near zero on a fresh board")
    }

    @Test("A scattered, fragmented board reads higher pressure than an empty board, holding blocksPlaced fixed")
    func fragmentationRaisesPressure() {
        for difficulty in DifficultyMode.allCases {
            let calm = BoardPressure.calculate(grid: emptyGrid(), blocksPlaced: 0, difficulty: difficulty)
            let scattered = BoardPressure.calculate(grid: scatteredGrid(), blocksPlaced: 0, difficulty: difficulty)
            #expect(scattered > calm, "difficulty=\(difficulty): scattered (\(scattered)) should exceed calm (\(calm))")
        }
    }

    @Test("Pressure rises monotonically with blocksPlaced, holding the grid fixed", arguments: DifficultyMode.allCases)
    func progressRaisesPressure(difficulty: DifficultyMode) {
        let grid = emptyGrid()
        var previous = BoardPressure.calculate(grid: grid, blocksPlaced: 0, difficulty: difficulty)
        for blocksPlaced in stride(from: 20, through: 400, by: 20) {
            let current = BoardPressure.calculate(grid: grid, blocksPlaced: blocksPlaced, difficulty: difficulty)
            #expect(current >= previous, "pressure dropped from \(previous) to \(current) as blocksPlaced rose to \(blocksPlaced)")
            previous = current
        }
    }

    @Test("For the same grid and progress, Hard is never gentler than Moderate, and Moderate never gentler than Easy")
    func difficultyOrdersPressure() {
        for grid in [emptyGrid(), scatteredGrid(), fullGrid()] {
            for blocksPlaced in [0, 50, 200] {
                let easy = BoardPressure.calculate(grid: grid, blocksPlaced: blocksPlaced, difficulty: .easy)
                let moderate = BoardPressure.calculate(grid: grid, blocksPlaced: blocksPlaced, difficulty: .moderate)
                let hard = BoardPressure.calculate(grid: grid, blocksPlaced: blocksPlaced, difficulty: .hard)
                #expect(easy <= moderate, "blocksPlaced=\(blocksPlaced): easy \(easy) > moderate \(moderate)")
                #expect(moderate <= hard, "blocksPlaced=\(blocksPlaced): moderate \(moderate) > hard \(hard)")
            }
        }
    }

    @Test("Easy never reaches full pressure even on the worst board after a long game")
    func easyKeepsSlack() {
        let pressure = BoardPressure.calculate(grid: scatteredGrid(), blocksPlaced: 10_000, difficulty: .easy)
        #expect(pressure < 1.0, "Easy pressure=\(pressure) should stay under the ceiling")
    }
}
