//
//  GameSimulationTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the headless game simulator (`GameSimulation.swift`) and the
//  opt-in calibration report that uses it to measure how long bots of
//  different skill survive against the block generator.
//
//  The smoke tests run with the normal suite. The report is slow, so it only
//  runs when `GENERATOR_SIM=1` is set:
//
//      TEST_RUNNER_GENERATOR_SIM=1 ./scripts/build.sh test-unit
//
//  `TEST_RUNNER_` is how xcodebuild forwards an environment variable into the
//  test process. See `conventions/tdd.md` for why the simulator is itself
//  tested: a harness that cannot fail would report confidence it has not earned.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Test Helpers

private func fullGrid() -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for row in 0..<8 {
        for col in 0..<8 {
            grid[row][col].isFilled = true
        }
    }
    return grid
}

/// Row 0 filled except columns 0...2, so a horizontal triple at (0, 0) clears it.
private func rowMissingThreeCells() -> [[GridCell]] {
    var grid = GameLogic.createEmptyGrid()
    for col in 3..<8 {
        grid[0][col].isFilled = true
    }
    return grid
}

private let horizontalTriple = BlockShape(
    positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2)],
    color: .red
)

private let singleCell = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)

private func makeBots() -> [any SimulationBot] {
    [RandomValidBot(), GreedyBot(), LookaheadBot()]
}

private func makeGenerator(seed: UInt64 = 3) -> any RandomNumberGenerator {
    SeededGenerator(seed: seed)
}

// MARK: - Simulator Loop

@Suite("GameSimulator.play")
struct GameSimulatorPlayTests {
    @Test("A dealt set that fits nowhere ends the game before any placement")
    func unplaceableDealEndsImmediately() {
        var bot = GreedyBot()

        let outcome = GameSimulator.play(
            bot: &bot,
            difficulty: .moderate,
            startingGrid: fullGrid(),
            deal: { _ in [horizontalTriple] }
        )

        #expect(outcome.placements == 0)
        #expect(outcome.batchesDealt == 1)
        #expect(!outcome.endedByCap)
    }

    @Test("A game that survives to the batch cap reports endedByCap and never exceeds it")
    func stopsAtBatchCap() {
        var bot = GreedyBot()

        let outcome = GameSimulator.play(bot: &bot, difficulty: .easy, maxBatches: 2)

        #expect(outcome.endedByCap)
        #expect(outcome.placements <= 2 * 3)
        #expect(outcome.placements > 0)
    }

    @Test("Placements never exceed three per batch dealt")
    func placementsBoundedByBatches() {
        var bot = RandomValidBot()

        let outcome = GameSimulator.play(bot: &bot, difficulty: .hard, maxBatches: 50, seed: 7)

        #expect(outcome.placements <= outcome.batchesDealt * 3)
    }
}

// MARK: - Bots

@Suite("SimulationBot legality")
struct SimulationBotLegalityTests {
    @Test("Every bot returns a legal move for a block it was offered")
    func movesAreLegal() throws {
        var generator = makeGenerator()
        var grid = GameLogic.createEmptyGrid()
        GameLogic.randomlyFillGrid(&grid, difficulty: .moderate, using: &generator)
        let blocks = BlockGenerator.generateTieredBlocks(count: 3, difficulty: .moderate, grid: grid, using: &generator)

        for var bot in makeBots() {
            let move = bot.chooseMove(blocks: blocks, grid: grid, using: &generator)
            let chosen = try #require(move, "\(bot.name) returned no move on a playable board")

            #expect(blocks.contains { $0.id == chosen.block.id }, "\(bot.name) chose a block it was not offered")
            #expect(GameLogic.canPlaceBlock(chosen.block, at: chosen.position, in: grid), "\(bot.name) chose an illegal position")
        }
    }

    @Test("Every bot returns nil when nothing can be placed")
    func noMoveOnFullBoard() {
        var generator = makeGenerator()
        for var bot in makeBots() {
            #expect(bot.chooseMove(blocks: [singleCell], grid: fullGrid(), using: &generator) == nil, "\(bot.name) invented a move on a full board")
        }
    }

    @Test("Greedy and lookahead bots complete a line when one is on offer")
    func takesTheLineClear() {
        var generator = makeGenerator()
        let grid = rowMissingThreeCells()

        for var bot in [GreedyBot() as any SimulationBot, LookaheadBot()] {
            let move = bot.chooseMove(blocks: [horizontalTriple, singleCell], grid: grid, using: &generator)

            #expect(move?.block.id == horizontalTriple.id, "\(bot.name) did not pick the line-completing block")
            #expect(move?.position == GridPosition(row: 0, col: 0), "\(bot.name) did not complete the row")
        }
    }
}

// MARK: - Statistics

@Suite("SimulationStatistics")
struct SimulationStatisticsTests {
    @Test("Percentiles use nearest-rank on the sorted sample")
    func percentiles() {
        let sample = [5, 1, 4, 2, 3, 10, 9, 8, 7, 6]

        #expect(SimulationStatistics.percentile(0.5, of: sample) == 5)
        #expect(SimulationStatistics.percentile(0.1, of: sample) == 1)
        #expect(SimulationStatistics.percentile(0.9, of: sample) == 9)
        #expect(SimulationStatistics.percentile(1.0, of: sample) == 10)
    }

    @Test("An empty sample yields zero rather than crashing")
    func emptySample() {
        #expect(SimulationStatistics.percentile(0.5, of: []) == 0)
    }
}

// MARK: - Calibration Report (opt-in)

@Suite("Generator calibration report")
struct GeneratorCalibrationReport {
    private static let enabled = ProcessInfo.processInfo.environment["GENERATOR_SIM"] == "1"

    /// Assumed seconds per placement, used only to turn placements into a
    /// human-scale duration. Replace with the figure measured from real
    /// `GameRecord`s (`elapsedGameTime / blocksPlaced`) once known.
    private static let secondsPerPlacement = Double(
        ProcessInfo.processInfo.environment["GENERATOR_SIM_SECONDS_PER_PLACEMENT"] ?? "5"
    ) ?? 5

    @Test("The table has exactly one correctly-labeled row per difficulty/bot combination", .enabled(if: enabled))
    func report() {
        let games = Int(ProcessInfo.processInfo.environment["GENERATOR_SIM_GAMES"] ?? "100") ?? 100
        let maxBatches = Int(ProcessInfo.processInfo.environment["GENERATOR_SIM_MAX_BATCHES"] ?? "400") ?? 400

        let table = SimulationReport.render(
            games: games,
            maxBatches: maxBatches,
            secondsPerPlacement: Self.secondsPerPlacement
        )

        print(table)
        if let path = ProcessInfo.processInfo.environment["GENERATOR_SIM_REPORT"] {
            try? table.write(toFile: path, atomically: true, encoding: .utf8)
        }

        // `!table.isEmpty` alone would stay green even if the report loop
        // silently dropped a row (a difficulty or a bot), since the header and
        // footer text alone make the string non-empty. Parse each data row's
        // first two columns instead and check the full set of (mode, bot)
        // labels is exactly what's expected — this fails if any row goes
        // missing, is duplicated, or is mislabeled.
        let botNames = ["random", "greedy", "lookahead"]
        let expectedRows = Set(
            DifficultyMode.allCases.flatMap { difficulty in
                botNames.map { "\(difficulty.rawValue.lowercased())|\($0)" }
            }
        )

        let dataLines = table.split(separator: "\n").filter { line in
            DifficultyMode.allCases.contains { line.hasPrefix($0.rawValue.lowercased()) }
        }
        let actualRows = Set(dataLines.compactMap { line -> String? in
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)
            guard columns.count >= 2 else { return nil }
            return "\(columns[0])|\(columns[1])"
        })

        #expect(dataLines.count == expectedRows.count, "expected \(expectedRows.count) data rows, found \(dataLines.count)")
        #expect(actualRows == expectedRows, "row labels don't match: missing \(expectedRows.subtracting(actualRows)), unexpected \(actualRows.subtracting(expectedRows))")
    }
}
