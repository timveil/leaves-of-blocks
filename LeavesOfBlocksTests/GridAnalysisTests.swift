//
//  GridAnalysisTests.swift
//  LeavesOfBlocksTests
//
//  Tests for grid analysis metrics and difficulty tier classification.
//

import Testing
@testable import LeavesOfBlocks

// MARK: - Test Helpers

private func makeGrid(filled: [(Int, Int)] = []) -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for (row, col) in filled {
        grid[row][col].isFilled = true
        grid[row][col].color = .blue
    }
    return grid
}

private func makeFullRowGrid(row: Int) -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for col in 0..<8 {
        grid[row][col].isFilled = true
    }
    return grid
}

// MARK: - Density

@Suite("GridAnalysis density")
struct GridAnalysisDensityTests {
    @Test("Empty grid has zero density")
    func empty() {
        let metrics = GridAnalysis.analyzeGrid(makeGrid())
        #expect(metrics.density == 0.0)
    }

    @Test("Half-filled grid has 0.5 density")
    func halfFilled() {
        var grid = GameLogic.createEmptyGrid()
        for row in 0..<8 {
            for col in 0..<4 {
                grid[row][col].isFilled = true
            }
        }
        let metrics = GridAnalysis.analyzeGrid(grid)
        #expect(metrics.density == 0.5)
    }

    @Test("Single-cell grid reports 1/64 density")
    func singleCell() {
        let metrics = GridAnalysis.analyzeGrid(makeGrid(filled: [(0, 0)]))
        #expect(abs(metrics.density - (1.0 / 64.0)) < 0.0001)
    }
}

// MARK: - Efficiency

@Suite("GridAnalysis efficiency")
struct GridAnalysisEfficiencyTests {
    @Test("Empty grid is treated as perfectly efficient")
    func empty() {
        let metrics = GridAnalysis.analyzeGrid(makeGrid())
        #expect(metrics.efficiency == 1.0)
    }

    @Test("Single-cluster placements score higher than scattered ones")
    func clusterBeatsScatter() {
        let cluster = makeGrid(filled: [
            (0, 0), (0, 1), (0, 2), (0, 3)
        ])
        let scattered = makeGrid(filled: [
            (0, 0), (3, 3), (5, 5), (7, 7)
        ])
        let clusterEfficiency = GridAnalysis.analyzeGrid(cluster).efficiency
        let scatteredEfficiency = GridAnalysis.analyzeGrid(scattered).efficiency
        #expect(clusterEfficiency > scatteredEfficiency)
    }
}

// MARK: - Fragmentation

@Suite("GridAnalysis fragmentation")
struct GridAnalysisFragmentationTests {
    @Test("Empty grid has zero fragmentation")
    func empty() {
        let metrics = GridAnalysis.analyzeGrid(makeGrid())
        #expect(metrics.fragmentation == 0.0)
    }

    @Test("Fully isolated cells produce maximum fragmentation")
    func fullyScattered() {
        let grid = makeGrid(filled: [
            (0, 0), (2, 2), (4, 4), (6, 6)
        ])
        let metrics = GridAnalysis.analyzeGrid(grid)
        #expect(metrics.fragmentation == 1.0)
    }

    @Test("A solid cluster has zero fragmentation")
    func solidCluster() {
        let grid = makeGrid(filled: [
            (0, 0), (0, 1), (1, 0), (1, 1)
        ])
        let metrics = GridAnalysis.analyzeGrid(grid)
        #expect(metrics.fragmentation == 0.0)
    }
}

// MARK: - Strategic Potential

@Suite("GridAnalysis strategic potential")
struct GridAnalysisStrategicPotentialTests {
    @Test("Sparse grid has zero strategic potential")
    func sparse() {
        let metrics = GridAnalysis.analyzeGrid(makeGrid(filled: [(0, 0), (3, 3)]))
        #expect(metrics.strategicPotential == 0.0)
    }

    @Test("A near-complete row contributes strategic potential")
    func nearCompleteRow() {
        var grid = makeFullRowGrid(row: 3)
        // Leave one cell empty so the row has 7/8 filled.
        grid[3][7].isFilled = false
        let metrics = GridAnalysis.analyzeGrid(grid)
        #expect(metrics.strategicPotential > 0.0)
    }

    @Test("Strategic potential is bounded at 1.0")
    func bounded() {
        // Fill every row entirely — that's both rows AND columns near-complete.
        var grid = GameLogic.createEmptyGrid()
        for row in 0..<8 {
            for col in 0..<8 {
                grid[row][col].isFilled = true
            }
        }
        let metrics = GridAnalysis.analyzeGrid(grid)
        #expect(metrics.strategicPotential <= 1.0)
    }
}

// MARK: - Quality Score

@Suite("GridStateMetrics.qualityScore")
struct QualityScoreTests {
    @Test("Empty grid yields a high quality score (efficiency dominates)")
    func empty() {
        let metrics = GridAnalysis.analyzeGrid(makeGrid())
        // Empty grid: efficiency = 1.0, fragmentation = 0, strategicPotential = 0,
        // complexity = 0. qualityScore = 1.0 * 0.3 = 0.3, clamped to [0, 1].
        #expect(metrics.qualityScore == 0.3)
    }

    @Test("Quality score is always in [0, 1]")
    func bounded() {
        let grids: [[[GridCell]]] = [
            makeGrid(),
            makeGrid(filled: [(0, 0)]),
            makeGrid(filled: [(0, 0), (2, 2), (4, 4), (6, 6)]),
            makeFullRowGrid(row: 4)
        ]
        for grid in grids {
            let score = GridAnalysis.analyzeGrid(grid).qualityScore
            #expect(score >= 0.0 && score <= 1.0)
        }
    }
}

// MARK: - DifficultyTier

@Suite("DifficultyTier classification")
struct DifficultyTierTests {
    @Test("Score at the top of the range maps to .diverse")
    func diverseTopOfRange() {
        #expect(GridAnalysis.DifficultyTier.fromQualityScore(1.0) == .diverse)
    }

    @Test("0.7 lands in .diverse (inclusive lower bound)")
    func diverseLowerBound() {
        #expect(GridAnalysis.DifficultyTier.fromQualityScore(0.7) == .diverse)
    }

    @Test("0.5 lands in .constrained")
    func constrained() {
        #expect(GridAnalysis.DifficultyTier.fromQualityScore(0.5) == .constrained)
    }

    @Test("0.2 lands in .minimal")
    func minimal() {
        #expect(GridAnalysis.DifficultyTier.fromQualityScore(0.2) == .minimal)
    }

    @Test("Below 0.15 falls into .emergency")
    func emergency() {
        #expect(GridAnalysis.DifficultyTier.fromQualityScore(0.05) == .emergency)
        #expect(GridAnalysis.DifficultyTier.fromQualityScore(0.0) == .emergency)
    }

    @Test("determineDifficultyTier never crashes on any grid state")
    func runsToCompletion() {
        let grids: [[[GridCell]]] = [
            makeGrid(),
            makeGrid(filled: [(0, 0), (1, 1)]),
            makeFullRowGrid(row: 0)
        ]
        for grid in grids {
            _ = GridAnalysis.determineDifficultyTier(for: grid)
        }
    }
}
