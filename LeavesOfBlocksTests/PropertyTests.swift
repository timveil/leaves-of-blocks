//
//  PropertyTests.swift
//  LeavesOfBlocksTests
//
//  Property-style probes — each test asserts an invariant that should hold
//  for *any* valid input, then hammers it with many randomized inputs to
//  surface edge cases. These are not coverage tests; they're trying to find
//  bugs by varying inputs more aggressively than hand-written cases do.
//
//  When a property fails, the test should print enough context (the failing
//  grid / block / iteration) that the problem can be reproduced by hand.
//
//  Iteration counts are tuned to run in ~1s per probe locally. Bump them
//  if you want more aggressive fuzzing.
//

import Testing
@testable import LeavesOfBlocks

// MARK: - Random Input Helpers

/// Build a random grid with the given fill probability per cell.
/// Independent per-cell flip — produces "noisy" patterns rather than
/// realistic gameplay states. That's deliberate: we want adversarial inputs.
private func randomGrid(fillProbability: Double, generator: inout SystemRandomNumberGenerator) -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for row in 0..<8 {
        for col in 0..<8 {
            if Double.random(in: 0..<1, using: &generator) < fillProbability {
                grid[row][col].isFilled = true
                grid[row][col].color = BlockColor.allCases.randomElement(using: &generator)!
            }
        }
    }
    return grid
}

/// Render a grid as an 8-line ASCII string for failure diagnostics.
private func describe(_ grid: [[GridCell]]) -> String {
    grid.map { row in
        row.map { $0.isFilled ? "█" : "·" }.joined()
    }.joined(separator: "\n")
}

// MARK: - BlockGenerator Properties

@Suite("BlockGenerator: set-solvability across random grids")
struct BlockGeneratorPropertyTests {
    @Test("Generated set is placeable when the grid has room for it (emptyCells ≥ count)")
    func setIsPlaceableWhenGridHasRoom() {
        var rng = SystemRandomNumberGenerator()
        // Sweep a range of fill levels — sparse to nearly-full — so we
        // cover every difficulty tier the analyzer may select. Skip
        // degenerate inputs where emptyCells < count: in that regime no
        // count-block set can ever be solvable (even count single-cell
        // blocks need count distinct empty cells), so the generator's
        // best-effort output of `count` single-cell blocks is by design
        // not a solvable set — game-over fires at placement time instead.
        let fillLevels: [Double] = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.98]
        let iterationsPerLevel = 25
        let count = 3

        for fill in fillLevels {
            for difficulty in DifficultyMode.allCases {
                for iter in 0..<iterationsPerLevel {
                    let grid = randomGrid(fillProbability: fill, generator: &rng)
                    let emptyCells = grid.flatMap { $0 }.filter { !$0.isFilled }.count
                    guard emptyCells >= count else { continue }

                    let blocks = BlockGenerator.generateTieredBlocks(
                        count: count,
                        difficulty: difficulty,
                        grid: grid
                    )

                    #expect(
                        blocks.count == count,
                        "fill=\(fill) difficulty=\(difficulty) iter=\(iter): expected \(count) blocks, got \(blocks.count)"
                    )

                    let placeable = GameLogic.canAllBlocksBePlaced(blocks, in: grid)
                    if !placeable {
                        Issue.record("""
                            Generator returned an unsolvable set on a grid with room:
                              fill=\(fill) difficulty=\(difficulty) iter=\(iter)
                              empty cells: \(emptyCells)
                              block sizes: \(blocks.map { $0.positions.count })
                              total block cells: \(blocks.map { $0.positions.count }.reduce(0, +))
                              grid:
                            \(describe(grid))
                            """)
                    }
                }
            }
        }
    }

    @Test("On grids too tight to ever solve (emptyCells < count), generator emits singles as best-effort")
    func degenerateGridsEmitSingles() {
        // Document & verify the generator's contract on degenerate inputs:
        // when there are fewer empty cells than blocks requested, no
        // solvable set exists, so the generator falls back to single-cell
        // blocks (the smallest, individually-most-placeable shape). The
        // game's placement loop is what actually triggers game-over.
        var grid = GameLogic.createEmptyGrid()
        for r in 0..<8 { for c in 0..<8 { grid[r][c].isFilled = true } }
        // Punch out exactly 2 empty cells, request 3 blocks.
        grid[0][0].isFilled = false
        grid[7][7].isFilled = false

        let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
        #expect(blocks.count == 3)
        #expect(blocks.allSatisfy { $0.positions.count == 1 })
        // Set is intentionally NOT placeable in this regime — verify that
        // explicitly so behavior change here would be noticed.
        #expect(!GameLogic.canAllBlocksBePlaced(blocks, in: grid))
    }

    @Test("Every generated block carries a valid BlockColor")
    func colorsAreAlwaysValid() {
        var rng = SystemRandomNumberGenerator()
        let validColors = Set(BlockColor.allCases)
        for _ in 0..<50 {
            let fill = Double.random(in: 0..<1, using: &rng)
            let grid = randomGrid(fillProbability: fill, generator: &rng)
            let blocks = BlockGenerator.generateTieredBlocks(count: 3, grid: grid)
            for block in blocks {
                #expect(validColors.contains(block.color), "got unexpected color: \(block.color)")
            }
        }
    }
}

// MARK: - GameLogic Placement Properties

@Suite("GameLogic: placement and clearing invariants")
struct GameLogicPropertyTests {
    @Test("Every position returned by findValidPositions accepts canPlaceBlock")
    func findValidPositionsAreAllValid() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            let fill = Double.random(in: 0..<0.95, using: &rng)
            let grid = randomGrid(fillProbability: fill, generator: &rng)
            let block = BlockShape.allShapes.randomElement(using: &rng)!

            let validPositions = GameLogic.findValidPositions(for: block, in: grid)
            for pos in validPositions {
                if !GameLogic.canPlaceBlock(block, at: pos, in: grid) {
                    Issue.record("""
                        findValidPositions returned a position canPlaceBlock rejects:
                          block positions: \(block.positions)
                          position: \(pos)
                          grid:
                        \(describe(grid))
                        """)
                }
            }
        }
    }

    @Test("Placing a normal block fills exactly block.positions.count cells")
    func placeBlockChangesExactlyTheRightCells() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            let fill = Double.random(in: 0..<0.7, using: &rng)
            let grid = randomGrid(fillProbability: fill, generator: &rng)
            // Pick a normal-shape block (skip special clears — they remove cells).
            let normalShape = BlockShape.allShapes.randomElement(using: &rng)!
            let coloredBlock = BlockShape(positions: normalShape.positions, color: .red)
            guard coloredBlock.type == .normal else { continue }

            let validPositions = GameLogic.findValidPositions(for: coloredBlock, in: grid)
            guard let position = validPositions.randomElement() else { continue }

            let beforeFilled = grid.flatMap { $0 }.filter { $0.isFilled }.count
            var working = grid
            GameLogic.placeBlock(coloredBlock, at: position, in: &working)
            let afterFilled = working.flatMap { $0 }.filter { $0.isFilled }.count

            #expect(
                afterFilled == beforeFilled + coloredBlock.positions.count,
                "placeBlock added \(afterFilled - beforeFilled) cells, expected \(coloredBlock.positions.count)"
            )
        }
    }

    @Test("After clearCompletedLines, no row or column is fully filled")
    func clearLeavesNoCompletedLinesBehind() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            // Bias toward grids likely to have completed rows/cols.
            let fill = Double.random(in: 0.5..<0.95, using: &rng)
            var grid = randomGrid(fillProbability: fill, generator: &rng)

            _ = GameLogic.clearCompletedLines(in: &grid)

            for row in 0..<8 {
                #expect(
                    !grid[row].allSatisfy { $0.isFilled },
                    "row \(row) is still fully filled after clear:\n\(describe(grid))"
                )
            }
            for col in 0..<8 {
                let colFull = (0..<8).allSatisfy { grid[$0][col].isFilled }
                #expect(
                    !colFull,
                    "col \(col) is still fully filled after clear:\n\(describe(grid))"
                )
            }
        }
    }

    @Test("isGameOver is true iff no current block can be placed anywhere")
    func gameOverEquivalentToNoPlacements() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            let fill = Double.random(in: 0..<1, using: &rng)
            let grid = randomGrid(fillProbability: fill, generator: &rng)
            let blocks = (0..<3).map { _ in
                BlockShape.allShapes.randomElement(using: &rng)!
            }

            let isGameOver = GameLogic.isGameOver(currentBlocks: blocks, grid: grid)
            // Equivalence check: game over iff no block can be placed anywhere.
            let anyPlaceable = blocks.contains { block in
                !GameLogic.findValidPositions(for: block, in: grid).isEmpty
            }
            #expect(
                isGameOver == !anyPlaceable,
                "isGameOver=\(isGameOver) but anyPlaceable=\(anyPlaceable):\n\(describe(grid))"
            )
        }
    }

    @Test("linesThatWouldClear matches what clearCompletedLines actually clears")
    func predictedClearsMatchActual() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<60 {
            let fill = Double.random(in: 0.4..<0.85, using: &rng)
            let grid = randomGrid(fillProbability: fill, generator: &rng)
            let block = BlockShape.allShapes.randomElement(using: &rng)!
            let coloredBlock = BlockShape(positions: block.positions, color: .blue)
            guard coloredBlock.type == .normal else { continue }

            let validPositions = GameLogic.findValidPositions(for: coloredBlock, in: grid)
            guard let position = validPositions.randomElement() else { continue }

            let predicted = GameLogic.linesThatWouldClear(placing: coloredBlock, at: position, in: grid)

            var working = grid
            GameLogic.placeBlock(coloredBlock, at: position, in: &working)
            let actual = GameLogic.clearCompletedLines(in: &working)

            #expect(
                predicted.rows == actual.clearedRows,
                "row prediction mismatch: predicted \(predicted.rows) actual \(actual.clearedRows)"
            )
            #expect(
                predicted.cols == actual.clearedCols,
                "col prediction mismatch: predicted \(predicted.cols) actual \(actual.clearedCols)"
            )
        }
    }
}

// MARK: - GridAnalysis Range Properties

@Suite("GridAnalysis: metric ranges")
struct GridAnalysisPropertyTests {
    @Test("All grid metrics stay within their declared 0...1 range across random grids")
    func metricsStayInRange() {
        var rng = SystemRandomNumberGenerator()
        let fillLevels: [Double] = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]
        for fill in fillLevels {
            for iter in 0..<20 {
                let grid = randomGrid(fillProbability: fill, generator: &rng)
                let m = GridAnalysis.analyzeGrid(grid)

                #expect((0.0...1.0).contains(m.efficiency),         "fill=\(fill) iter=\(iter) efficiency=\(m.efficiency)")
                #expect((0.0...1.0).contains(m.fragmentation),      "fill=\(fill) iter=\(iter) fragmentation=\(m.fragmentation)")
                #expect((0.0...1.0).contains(m.strategicPotential), "fill=\(fill) iter=\(iter) strategicPotential=\(m.strategicPotential)")
                #expect((0.0...1.0).contains(m.complexity),         "fill=\(fill) iter=\(iter) complexity=\(m.complexity)")
                #expect((0.0...1.0).contains(m.density),            "fill=\(fill) iter=\(iter) density=\(m.density)")
                #expect((0.0...1.0).contains(m.qualityScore),       "fill=\(fill) iter=\(iter) qualityScore=\(m.qualityScore)")
            }
        }
    }

    @Test("Density on an empty grid is 0; on a fully-filled grid is 1")
    func densityBoundaries() {
        let empty = GameLogic.createEmptyGrid()
        var full = GameLogic.createEmptyGrid()
        for r in 0..<8 { for c in 0..<8 { full[r][c].isFilled = true } }

        #expect(GridAnalysis.analyzeGrid(empty).density == 0.0)
        #expect(GridAnalysis.analyzeGrid(full).density == 1.0)
    }

    @Test("determineDifficultyTier is deterministic for a given grid")
    func tierDeterministic() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<50 {
            let fill = Double.random(in: 0..<1, using: &rng)
            let grid = randomGrid(fillProbability: fill, generator: &rng)
            let t1 = GridAnalysis.determineDifficultyTier(for: grid)
            let t2 = GridAnalysis.determineDifficultyTier(for: grid)
            let t3 = GridAnalysis.determineDifficultyTier(for: grid)
            #expect(t1 == t2 && t2 == t3, "tier non-deterministic: \(t1) \(t2) \(t3)")
        }
    }
}

// MARK: - Scoring Properties

@Suite("GameLogic scoring: invariants of calculateBlockScore / calculateLineScore")
struct ScoringPropertyTests {
    private let baseBlockScore = GameTheme.GameConfig.baseBlockScore
    private let lineScore = GameTheme.GameConfig.lineScore
    private let comboBonus = GameTheme.GameConfig.comboBonus

    @Test("Normal block score = positions.count × baseBlockScore for every standard shape")
    func normalBlockScoreFormula() {
        for shape in BlockShape.allShapes {
            // allShapes are normal — verify by reconstructing as .normal and scoring.
            let block = BlockShape(positions: shape.positions, color: .red)
            let expected = shape.positions.count * baseBlockScore
            let actual = GameLogic.calculateBlockScore(block: block)
            #expect(actual == expected, "shape with \(shape.positions.count) cells scored \(actual), expected \(expected)")
        }
    }

    @Test("Special block scores use their fixed bonus values")
    func specialBlockScores() {
        let h = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red, type: .horizontalClear)
        let v = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red, type: .verticalClear)
        let a = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red, type: .areaClear)
        #expect(GameLogic.calculateBlockScore(block: h) == lineScore)
        #expect(GameLogic.calculateBlockScore(block: v) == lineScore)
        #expect(GameLogic.calculateBlockScore(block: a) == lineScore * 2)
    }

    @Test("calculateLineScore(0, 0) is exactly 0")
    func zeroLinesIsZeroScore() {
        #expect(GameLogic.calculateLineScore(clearedRows: 0, clearedCols: 0) == 0)
    }

    @Test("Single line clear awards lineScore with no combo bonus")
    func singleLineNoCombo() {
        #expect(GameLogic.calculateLineScore(clearedRows: 1, clearedCols: 0) == lineScore)
        #expect(GameLogic.calculateLineScore(clearedRows: 0, clearedCols: 1) == lineScore)
    }

    @Test("calculateLineScore is symmetric in (rows, cols)")
    func symmetric() {
        for r in 0...8 {
            for c in 0...8 {
                let rc = GameLogic.calculateLineScore(clearedRows: r, clearedCols: c)
                let cr = GameLogic.calculateLineScore(clearedRows: c, clearedCols: r)
                #expect(rc == cr, "asymmetry: score(\(r), \(c))=\(rc) vs score(\(c), \(r))=\(cr)")
            }
        }
    }

    @Test("calculateLineScore is monotonically non-decreasing in each argument")
    func monotonic() {
        for r in 0..<8 {
            for c in 0..<8 {
                let base = GameLogic.calculateLineScore(clearedRows: r, clearedCols: c)
                let r1 = GameLogic.calculateLineScore(clearedRows: r + 1, clearedCols: c)
                let c1 = GameLogic.calculateLineScore(clearedRows: r, clearedCols: c + 1)
                #expect(r1 >= base, "score decreased when rows went \(r)→\(r+1) at cols=\(c)")
                #expect(c1 >= base, "score decreased when cols went \(c)→\(c+1) at rows=\(r)")
            }
        }
    }

    @Test("Combo bonus is awarded only when totalLines ≥ 2")
    func comboKicksInAtTwoLines() {
        // The closed-form formula combines base + combo: totalLines * lineScore
        // + max(0, totalLines - 1) * comboBonus. Verify that the difference
        // between successive totals matches comboBonus (after the first line).
        let s0 = GameLogic.calculateLineScore(clearedRows: 0, clearedCols: 0) // 0
        let s1 = GameLogic.calculateLineScore(clearedRows: 1, clearedCols: 0) // lineScore, no combo
        let s2 = GameLogic.calculateLineScore(clearedRows: 2, clearedCols: 0) // 2*lineScore + 1*combo
        let s3 = GameLogic.calculateLineScore(clearedRows: 3, clearedCols: 0) // 3*lineScore + 2*combo

        #expect(s1 - s0 == lineScore)
        #expect(s2 - s1 == lineScore + comboBonus)
        #expect(s3 - s2 == lineScore + comboBonus)
    }
}

// MARK: - BlockShape Geometry Properties

@Suite("BlockShape geometry invariants")
struct BlockShapeGeometryTests {
    @Test("Every BlockShape.allShapes entry has at least one position")
    func allShapesNonEmpty() {
        for (index, shape) in BlockShape.allShapes.enumerated() {
            #expect(!shape.positions.isEmpty, "allShapes[\(index)] has empty positions")
        }
    }

    @Test("Every shape's positions sit within the bounds it reports")
    func positionsRespectBounds() {
        for (index, shape) in BlockShape.allShapes.enumerated() {
            let b = shape.getBounds()
            for pos in shape.positions {
                #expect(pos.row >= b.minRow && pos.row <= b.maxRow,
                    "allShapes[\(index)]: row \(pos.row) out of bounds [\(b.minRow), \(b.maxRow)]")
                #expect(pos.col >= b.minCol && pos.col <= b.maxCol,
                    "allShapes[\(index)]: col \(pos.col) out of bounds [\(b.minCol), \(b.maxCol)]")
            }
        }
    }

    @Test("Width and height are exactly maxRow-minRow+1 and maxCol-minCol+1")
    func boundsArithmetic() {
        for (index, shape) in BlockShape.allShapes.enumerated() {
            let b = shape.getBounds()
            #expect(b.height == b.maxRow - b.minRow + 1, "allShapes[\(index)] height arithmetic broken")
            #expect(b.width == b.maxCol - b.minCol + 1, "allShapes[\(index)] width arithmetic broken")
        }
    }

    @Test("Every standard shape fits within an 8×8 grid")
    func fitsIn8x8Grid() {
        for (index, shape) in BlockShape.allShapes.enumerated() {
            let b = shape.getBounds()
            #expect(b.width <= 8, "allShapes[\(index)] width \(b.width) > 8")
            #expect(b.height <= 8, "allShapes[\(index)] height \(b.height) > 8")
        }
    }

    @Test("Each shape's positions are distinct (no overlapping cells within one block)")
    func positionsAreDistinct() {
        for (index, shape) in BlockShape.allShapes.enumerated() {
            let unique = Set(shape.positions.map { "\($0.row),\($0.col)" })
            #expect(unique.count == shape.positions.count,
                "allShapes[\(index)] has duplicate positions: \(shape.positions)")
        }
    }

    @Test("All standard shape positions are non-negative")
    func positionsNonNegative() {
        for (index, shape) in BlockShape.allShapes.enumerated() {
            for pos in shape.positions {
                #expect(pos.row >= 0, "allShapes[\(index)] has negative row \(pos.row)")
                #expect(pos.col >= 0, "allShapes[\(index)] has negative col \(pos.col)")
            }
        }
    }

    @Test("getBounds() on an empty-positions shape returns the documented degenerate value")
    func emptyShapeDegenerateBounds() {
        let empty = BlockShape(positions: [], color: .red)
        let b = empty.getBounds()
        #expect(b.minRow == 0 && b.maxRow == 0 && b.minCol == 0 && b.maxCol == 0)
        #expect(b.width == 0 && b.height == 0)
    }
}
