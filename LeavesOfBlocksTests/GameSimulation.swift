//
//  GameSimulation.swift
//  LeavesOfBlocksTests
//
//  A headless game loop and three bots of different skill, used to measure how
//  long a player survives against `BlockGenerator`. It drives `GameLogic`
//  directly, so it needs no `GameState`, services or Core Data.
//
//  This is test support, not app code: it exists to calibrate block dealing
//  against a session-length target (issue #177), and lives here so the app
//  ships none of it.
//

import Foundation
@testable import LeavesOfBlocks

// MARK: - Seeded Randomness

/// SplitMix64. Small, fast and fully determined by its seed, so an entire game
/// — grid pre-fill, every dealt batch, and a random bot's choices — can be
/// reproduced from a single number in a bug report.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - Moves and Bots

struct SimulationMove {
    let block: BlockShape
    let position: GridPosition
}

/// Something that can play a turn. `chooseMove` returns `nil` only when none of
/// the offered blocks fits anywhere. `generator` is threaded through so a bot
/// that needs randomness (`RandomValidBot`) draws from the same seeded stream
/// as the rest of the game; deterministic bots simply ignore it.
protocol SimulationBot {
    var name: String { get }
    mutating func chooseMove(blocks: [BlockShape], grid: [[GridCell]], using generator: inout any RandomNumberGenerator) -> SimulationMove?
}

// MARK: - Board Helpers

enum SimulationBoard {
    private static var size: Int { AppConfiguration.GameRules.gridSize }

    static func legalMoves(for blocks: [BlockShape], in grid: [[GridCell]]) -> [SimulationMove] {
        var moves: [SimulationMove] = []
        for block in blocks {
            moves.append(contentsOf: legalMoves(for: block, in: grid))
        }
        return moves
    }

    static func legalMoves(for block: BlockShape, in grid: [[GridCell]]) -> [SimulationMove] {
        var moves: [SimulationMove] = []
        for row in 0..<size {
            for col in 0..<size {
                let position = GridPosition(row: row, col: col)
                if GameLogic.canPlaceBlock(block, at: position, in: grid) {
                    moves.append(SimulationMove(block: block, position: position))
                }
            }
        }
        return moves
    }

    /// Places the block, then clears any completed lines, as `GameState` does.
    static func apply(_ move: SimulationMove, to grid: [[GridCell]]) -> (grid: [[GridCell]], linesCleared: Int) {
        var next = grid
        GameLogic.placeBlock(move.block, at: move.position, in: &next)
        let cleared = GameLogic.clearCompletedLines(in: &next)
        return (next, cleared.clearedRows.count + cleared.clearedCols.count)
    }

    /// A rough measure of how healthy a board is for the player: lines cleared
    /// are good; empty cells nothing but a single can fill, a crowded board and
    /// a ragged surface are bad. Higher is better.
    static func evaluate(_ grid: [[GridCell]], linesCleared: Int) -> Double {
        var filled = 0
        var isolatedEmpty = 0
        var transitions = 0

        for row in 0..<size {
            for col in 0..<size {
                if grid[row][col].isFilled {
                    filled += 1
                } else {
                    let hasEmptyNeighbour = [(-1, 0), (1, 0), (0, -1), (0, 1)].contains { dr, dc in
                        let r = row + dr
                        let c = col + dc
                        return r >= 0 && r < size && c >= 0 && c < size && !grid[r][c].isFilled
                    }
                    if !hasEmptyNeighbour { isolatedEmpty += 1 }
                }
                if col + 1 < size, grid[row][col].isFilled != grid[row][col + 1].isFilled { transitions += 1 }
                if row + 1 < size, grid[row][col].isFilled != grid[row + 1][col].isFilled { transitions += 1 }
            }
        }

        let density = Double(filled) / Double(size * size)
        return 10.0 * Double(linesCleared) - 3.0 * Double(isolatedEmpty) - 8.0 * density - 0.2 * Double(transitions)
    }
}

// MARK: - Bots

/// Plays any legal move. Stands in for careless play.
struct RandomValidBot: SimulationBot {
    let name = "random"

    mutating func chooseMove(blocks: [BlockShape], grid: [[GridCell]], using generator: inout any RandomNumberGenerator) -> SimulationMove? {
        SimulationBoard.legalMoves(for: blocks, in: grid).randomElement(using: &generator)
    }
}

/// Picks the single move that leaves the healthiest board. Stands in for a
/// typical attentive player: sensible each turn, no planning across the batch.
struct GreedyBot: SimulationBot {
    let name = "greedy"

    mutating func chooseMove(blocks: [BlockShape], grid: [[GridCell]], using generator: inout any RandomNumberGenerator) -> SimulationMove? {
        var best: (move: SimulationMove, score: Double)?
        for move in SimulationBoard.legalMoves(for: blocks, in: grid) {
            let result = SimulationBoard.apply(move, to: grid)
            let score = SimulationBoard.evaluate(result.grid, linesCleared: result.linesCleared)
            if best == nil || score > best!.score {
                best = (move, score)
            }
        }
        return best?.move
    }
}

/// Plans the whole batch: tries the blocks in every order, keeping the best few
/// positions per block, and plays the first move of the best sequence. Stands
/// in for an expert.
struct LookaheadBot: SimulationBot {
    let name = "lookahead"
    var beamWidth = 3

    /// Charged per block left with nowhere to go, so a plan that strands a block
    /// loses to any plan that does not.
    private static let strandedPenalty = 100.0

    mutating func chooseMove(blocks: [BlockShape], grid: [[GridCell]], using generator: inout any RandomNumberGenerator) -> SimulationMove? {
        var best: (move: SimulationMove, score: Double)?
        for first in candidates(for: blocks, in: grid) {
            let result = SimulationBoard.apply(first, to: grid)
            let rest = blocks.filter { $0.id != first.block.id }
            let score = bestScore(remaining: rest, grid: result.grid, linesCleared: result.linesCleared)
            if best == nil || score > best!.score {
                best = (first, score)
            }
        }
        return best?.move
    }

    private func bestScore(remaining: [BlockShape], grid: [[GridCell]], linesCleared: Int) -> Double {
        guard !remaining.isEmpty else {
            return SimulationBoard.evaluate(grid, linesCleared: linesCleared)
        }
        let moves = candidates(for: remaining, in: grid)
        guard !moves.isEmpty else {
            return SimulationBoard.evaluate(grid, linesCleared: linesCleared) - Self.strandedPenalty * Double(remaining.count)
        }

        var best = -Double.infinity
        for move in moves {
            let result = SimulationBoard.apply(move, to: grid)
            let rest = remaining.filter { $0.id != move.block.id }
            best = max(best, bestScore(remaining: rest, grid: result.grid, linesCleared: linesCleared + result.linesCleared))
        }
        return best
    }

    /// The `beamWidth` best-scoring positions for each block, in block order.
    private func candidates(for blocks: [BlockShape], in grid: [[GridCell]]) -> [SimulationMove] {
        blocks.flatMap { block -> [SimulationMove] in
            let scored = SimulationBoard.legalMoves(for: block, in: grid).map { move -> (SimulationMove, Double) in
                let result = SimulationBoard.apply(move, to: grid)
                return (move, SimulationBoard.evaluate(result.grid, linesCleared: result.linesCleared))
            }
            // Stable sort: equal scores keep their row-major order, which keeps
            // the bot deterministic.
            let ranked = scored.enumerated()
                .sorted { $0.element.1 != $1.element.1 ? $0.element.1 > $1.element.1 : $0.offset < $1.offset }
            return ranked.prefix(beamWidth).map { $0.element.0 }
        }
    }
}

// MARK: - Simulator

struct SimulationOutcome {
    /// Batches the generator dealt, including the one that ended the game.
    let batchesDealt: Int
    /// Blocks the bot managed to place.
    let placements: Int
    let linesCleared: Int
    /// True when the game was still going at `maxBatches`, so the true length is
    /// at least what was measured.
    let endedByCap: Bool
}

enum GameSimulator {
    /// Plays one game to its end or to `maxBatches`.
    ///
    /// Everything random in the game — the starting grid's pattern fill, each
    /// dealt batch, and a random bot's move choice — draws from one
    /// `SeededGenerator(seed: seed)`, so the whole game is reproducible from
    /// `seed` alone (addresses the review finding that the calibration report
    /// claimed reproducibility it didn't have: only the bot's own draws were
    /// seeded, while dealing and the starting grid still used the system RNG).
    ///
    /// - Parameters:
    ///   - deal: Produces the next batch for a grid. `nil` uses
    ///     `BlockGenerator.generateTieredBlocks` for `difficulty`, seeded; tests
    ///     inject a stub to reach states the generator itself never produces,
    ///     and don't need `seed` for that.
    static func play<Bot: SimulationBot>(
        bot: inout Bot,
        difficulty: DifficultyMode,
        maxBatches: Int = 500,
        seed: UInt64 = 0,
        startingGrid: [[GridCell]]? = nil,
        deal: (([[GridCell]]) -> [BlockShape])? = nil
    ) -> SimulationOutcome {
        var generator: any RandomNumberGenerator = SeededGenerator(seed: seed)

        var grid = startingGrid ?? {
            var fresh = GameLogic.createEmptyGrid()
            GameLogic.randomlyFillGrid(&fresh, difficulty: difficulty, using: &generator)
            return fresh
        }()

        var batchesDealt = 0
        var placements = 0
        var linesCleared = 0

        while batchesDealt < maxBatches {
            var blocks = deal?(grid) ?? BlockGenerator.generateTieredBlocks(count: 3, difficulty: difficulty, grid: grid, blocksPlaced: placements, using: &generator)
            batchesDealt += 1

            while !blocks.isEmpty {
                if GameLogic.isGameOver(currentBlocks: blocks, grid: grid) {
                    return SimulationOutcome(batchesDealt: batchesDealt, placements: placements, linesCleared: linesCleared, endedByCap: false)
                }
                guard let move = bot.chooseMove(blocks: blocks, grid: grid, using: &generator) else {
                    return SimulationOutcome(batchesDealt: batchesDealt, placements: placements, linesCleared: linesCleared, endedByCap: false)
                }

                let result = SimulationBoard.apply(move, to: grid)
                grid = result.grid
                linesCleared += result.linesCleared
                placements += 1
                blocks.removeAll { $0.id == move.block.id }
            }
        }

        return SimulationOutcome(batchesDealt: batchesDealt, placements: placements, linesCleared: linesCleared, endedByCap: true)
    }
}

// MARK: - Statistics and Report

enum SimulationStatistics {
    /// Nearest-rank percentile of `sample`; `0` for an empty sample.
    static func percentile(_ fraction: Double, of sample: [Int]) -> Int {
        guard !sample.isEmpty else { return 0 }
        let sorted = sample.sorted()
        let rank = Int((fraction * Double(sorted.count)).rounded(.up))
        return sorted[min(max(rank, 1), sorted.count) - 1]
    }
}

enum SimulationReport {
    /// Plays `games` games per bot per difficulty and renders a survival table.
    /// Each game index gets its own seed (reused across the three bots at that
    /// index, so they start from the same pre-filled grid), and every random
    /// draw in that game — grid fill, dealing, bot choice — comes from the
    /// resulting `SeededGenerator`, so any row can be re-run from its seed.
    static func render(games: Int, maxBatches: Int, secondsPerPlacement: Double) -> String {
        var lines: [String] = [
            "Generator calibration: \(games) games per row, cap \(maxBatches) batches, \(secondsPerPlacement)s per placement",
            "",
            "mode      bot        median   p10   p90   min  capped   median-min",
            "--------  ---------  ------  ----  ----  ----  ------  -----------"
        ]

        for difficulty in DifficultyMode.allCases {
            for botIndex in 0..<3 {
                var placements: [Int] = []
                var capped = 0

                for game in 0..<games {
                    let seed = UInt64(game) &+ 1
                    let outcome: SimulationOutcome
                    switch botIndex {
                    case 0:
                        var bot = RandomValidBot()
                        outcome = GameSimulator.play(bot: &bot, difficulty: difficulty, maxBatches: maxBatches, seed: seed)
                    case 1:
                        var bot = GreedyBot()
                        outcome = GameSimulator.play(bot: &bot, difficulty: difficulty, maxBatches: maxBatches, seed: seed)
                    default:
                        var bot = LookaheadBot()
                        outcome = GameSimulator.play(bot: &bot, difficulty: difficulty, maxBatches: maxBatches, seed: seed)
                    }
                    placements.append(outcome.placements)
                    if outcome.endedByCap { capped += 1 }
                }

                let botName = ["random", "greedy", "lookahead"][botIndex]
                let median = SimulationStatistics.percentile(0.5, of: placements)
                let minutes = Double(median) * secondsPerPlacement / 60.0
                lines.append(
                    pad(difficulty.rawValue.lowercased(), 8) + "  " + pad(botName, 9) + "  "
                    + pad("\(median)", 6, left: true) + "  "
                    + pad("\(SimulationStatistics.percentile(0.1, of: placements))", 4, left: true) + "  "
                    + pad("\(SimulationStatistics.percentile(0.9, of: placements))", 4, left: true) + "  "
                    + pad("\(placements.min() ?? 0)", 4, left: true) + "  "
                    + pad("\(capped)", 6, left: true) + "  "
                    + pad(String(format: "%.1f", minutes), 11, left: true)
                )
            }
        }

        lines.append("")
        lines.append("Values are blocks placed. `capped` counts games still alive at the cap, so their true length is longer.")
        return lines.joined(separator: "\n")
    }

    private static func pad(_ text: String, _ width: Int, left: Bool = false) -> String {
        let padding = String(repeating: " ", count: max(0, width - text.count))
        return left ? padding + text : text + padding
    }
}
