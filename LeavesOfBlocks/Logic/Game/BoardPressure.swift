import Foundation

/// How much trouble the player is currently in, derived from the board and
/// how far into the run they are (#177).
///
/// `BlockGenerator` uses this to decide where on a solvable candidate set's
/// helpfulness ranking to deal from: low pressure deals generously, high
/// pressure deals the least helpful solvable set it found. This replaces the
/// old size-tier cap, which picked a `maxBlockSize` from grid quality alone —
/// a fragmented-but-mostly-empty board could score as badly as a nearly full
/// one, capping every dealt block at 1–3 cells regardless of how much open
/// room was actually left.
///
/// Pure — no stored state, nothing read that isn't a parameter. See
/// `conventions/game-logic-boundary.md`.
enum BoardPressure {
    /// Returns a value in `0...1`. Higher means the player should be dealt a
    /// less helpful set.
    ///
    /// Combines four inputs, weighted to sum to 1.0 before the per-difficulty
    /// ceiling is applied (mirrors `GridStateMetrics.qualityScore`'s style):
    ///
    /// - `density` and `fragmentation`, reused from `GridAnalysis` so the
    ///   same board-quality reading feeds both the player-facing statistics
    ///   and this dealing decision.
    /// - a dead-cell fraction: the share of empty cells with no empty
    ///   orthogonal neighbor. A board can be sparse (low density) and still
    ///   be nearly unplayable if what's left is scattered single-cell holes
    ///   — density and fragmentation alone (which score how scattered the
    ///   *filled* cells are) don't capture that.
    /// - a progress ramp that climbs from 0 toward 1 as `blocksPlaced`
    ///   grows, so pressure isn't purely reactive to the board state — a
    ///   long, carefully-played game still tightens over time. The ramp
    ///   length is scaled per difficulty.
    ///
    /// The weighted sum is then scaled by a per-difficulty ceiling, so Easy
    /// never applies full pressure even on the worst board, and Hard can.
    static func calculate(grid: [[GridCell]], blocksPlaced: Int, difficulty: DifficultyMode) -> Double {
        let metrics = GridAnalysis.analyzeGrid(grid)
        let dead = deadCellFraction(grid)
        let ramp = progressRamp(blocksPlaced: blocksPlaced, difficulty: difficulty)

        let weighted =
            metrics.density * AppConfiguration.Gameplay.pressureWeightDensity +
            metrics.fragmentation * AppConfiguration.Gameplay.pressureWeightFragmentation +
            dead * AppConfiguration.Gameplay.pressureWeightDeadCells +
            ramp * AppConfiguration.Gameplay.pressureWeightProgressRamp

        return max(0.0, min(1.0, weighted)) * ceiling(for: difficulty)
    }

    /// Fraction of empty cells that have no empty orthogonal neighbor — cells
    /// only a 1-cell block could ever occupy. `0` on an empty or fully-filled
    /// grid.
    private static func deadCellFraction(_ grid: [[GridCell]]) -> Double {
        let size = AppConfiguration.GameRules.gridSize
        var emptyCells = 0
        var isolatedEmptyCells = 0

        for row in 0..<size {
            for col in 0..<size {
                guard !grid[row][col].isFilled else { continue }
                emptyCells += 1

                let hasEmptyNeighbor = [(-1, 0), (1, 0), (0, -1), (0, 1)].contains { dr, dc in
                    let r = row + dr, c = col + dc
                    return r >= 0 && r < size && c >= 0 && c < size && !grid[r][c].isFilled
                }
                if !hasEmptyNeighbor {
                    isolatedEmptyCells += 1
                }
            }
        }

        return emptyCells > 0 ? Double(isolatedEmptyCells) / Double(emptyCells) : 0.0
    }

    private static func progressRamp(blocksPlaced: Int, difficulty: DifficultyMode) -> Double {
        let rampBlocks: Int
        switch difficulty {
        case .easy: rampBlocks = AppConfiguration.Gameplay.pressureRampBlocksEasy
        case .moderate: rampBlocks = AppConfiguration.Gameplay.pressureRampBlocksModerate
        case .hard: rampBlocks = AppConfiguration.Gameplay.pressureRampBlocksHard
        }
        guard rampBlocks > 0 else { return 1.0 }
        return max(0.0, min(1.0, Double(blocksPlaced) / Double(rampBlocks)))
    }

    private static func ceiling(for difficulty: DifficultyMode) -> Double {
        switch difficulty {
        case .easy: return AppConfiguration.Gameplay.pressureCeilingEasy
        case .moderate: return AppConfiguration.Gameplay.pressureCeilingModerate
        case .hard: return AppConfiguration.Gameplay.pressureCeilingHard
        }
    }
}
