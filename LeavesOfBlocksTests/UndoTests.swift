//
//  UndoTests.swift
//  LeavesOfBlocksTests
//
//  Tests for the player-assist Undo feature: snapshot fidelity, restoration
//  across line clears, special blocks, game-over, and once-per-game gating.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - Helpers

@MainActor
private func makeTrackerState() -> PlayerBehaviorTracker.State {
    let tracker = PlayerBehaviorTracker()
    tracker.startSession()
    tracker.recordGridState(GameLogic.createEmptyGrid(), isInitialSeed: true)
    return tracker.captureState()
}

@MainActor
private func makeSnapshot(
    grid: [[GridCell]]? = nil,
    currentBlocks: [BlockShape] = [],
    score: Int = 0,
    isGameOver: Bool = false,
    linesCleared: Int = 0,
    lastClearedCells: [ClearedCell] = [],
    blocksPlaced: Int = 0,
    longestCombo: Int = 0,
    currentCombo: Int = 0,
    isNewHighScore: Bool = false,
    specialShapesUsed: Int = 0,
    currentDifficulty: DifficultyMode = .easy,
    elapsedGameTime: TimeInterval = 0,
    trackerState: PlayerBehaviorTracker.State? = nil,
    savedRecordID: UUID? = nil
) -> UndoSnapshot {
    UndoSnapshot(
        grid: grid ?? GameLogic.createEmptyGrid(),
        currentBlocks: currentBlocks,
        score: score,
        isGameOver: isGameOver,
        linesCleared: linesCleared,
        lastClearedCells: lastClearedCells,
        blocksPlaced: blocksPlaced,
        longestCombo: longestCombo,
        currentCombo: currentCombo,
        isNewHighScore: isNewHighScore,
        specialShapesUsed: specialShapesUsed,
        currentDifficulty: currentDifficulty,
        elapsedGameTime: elapsedGameTime,
        trackerState: trackerState ?? makeTrackerState(),
        savedRecordID: savedRecordID
    )
}

@MainActor
private func makeFreshGameState() -> (GameState, URL) {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("UndoTests-\(UUID().uuidString).json")
    let store = InProgressGameStore(fileURL: url)
    let state = GameState(inProgressStore: store)
    return (state, url)
}

@MainActor
private func anyPlaceablePosition(for block: BlockShape, on state: GameState) -> GridPosition? {
    GameLogic.findValidPositions(for: block, in: state.grid).first
}

// MARK: - Equality

@Suite("UndoSnapshot equality")
struct UndoSnapshotEqualityTests {
    @Test @MainActor
    func identicalSnapshotsAreEqual() {
        let trackerState = makeTrackerState()
        let snapA = makeSnapshot(trackerState: trackerState)
        let snapB = makeSnapshot(trackerState: trackerState)
        #expect(snapA == snapB)
    }

    @Test @MainActor
    func differingScoreBreaksEquality() {
        let trackerState = makeTrackerState()
        let snapA = makeSnapshot(score: 0, trackerState: trackerState)
        let snapB = makeSnapshot(score: 100, trackerState: trackerState)
        #expect(snapA != snapB)
    }

    @Test @MainActor
    func differingGameOverFlagBreaksEquality() {
        let trackerState = makeTrackerState()
        let snapA = makeSnapshot(isGameOver: false, trackerState: trackerState)
        let snapB = makeSnapshot(isGameOver: true, trackerState: trackerState)
        #expect(snapA != snapB)
    }

    @Test @MainActor
    func differingTrackerStateBreaksEquality() {
        var grid = GameLogic.createEmptyGrid()
        for col in 0..<8 { grid[0][col].isFilled = true }
        let trackerA = PlayerBehaviorTracker()
        trackerA.startSession()
        let trackerB = PlayerBehaviorTracker()
        trackerB.startSession()
        trackerB.recordGridState(grid)
        let snapA = makeSnapshot(trackerState: trackerA.captureState())
        let snapB = makeSnapshot(trackerState: trackerB.captureState())
        #expect(snapA != snapB)
    }

    @Test @MainActor
    func differingElapsedTimeBreaksEquality() {
        let trackerState = makeTrackerState()
        let snapA = makeSnapshot(elapsedGameTime: 0, trackerState: trackerState)
        let snapB = makeSnapshot(elapsedGameTime: 42, trackerState: trackerState)
        #expect(snapA != snapB)
    }
}

// MARK: - GameState Snapshot Plumbing

@Suite("GameState: undo snapshot plumbing")
struct UndoSnapshotPlumbingTests {
    @Test @MainActor
    func canUndoIsFalseOnFreshState() {
        let (state, _) = makeFreshGameState()
        #expect(state.canUndo == false)
        #expect(state.undoUsed == false)
    }

    @Test @MainActor
    func captureRecordsObservedFields() {
        let (state, _) = makeFreshGameState()
        var grid = GameLogic.createEmptyGrid()
        for col in 0..<8 { grid[0][col].isFilled = true }
        state._setTestState(
            score: 1234,
            blocksPlaced: 12,
            linesCleared: 3,
            longestCombo: 4,
            currentCombo: 2,
            specialShapesUsed: 1,
            isGameOver: true,
            isNewHighScore: true,
            currentDifficulty: .moderate,
            grid: grid,
            lastClearedCells: []
        )

        let snap = state.captureSnapshot()
        #expect(snap.score == 1234)
        #expect(snap.blocksPlaced == 12)
        #expect(snap.linesCleared == 3)
        #expect(snap.longestCombo == 4)
        #expect(snap.currentCombo == 2)
        #expect(snap.specialShapesUsed == 1)
        #expect(snap.isGameOver == true)
        #expect(snap.isNewHighScore == true)
        #expect(snap.currentDifficulty == .moderate)
        #expect(snap.grid == grid)
    }

    @Test @MainActor
    func restoreReplacesObservedFields() {
        let (state, _) = makeFreshGameState()
        state._setTestState(
            score: 999,
            blocksPlaced: 9,
            linesCleared: 9,
            longestCombo: 9,
            currentCombo: 9,
            specialShapesUsed: 9,
            isGameOver: true,
            isNewHighScore: true,
            currentDifficulty: .hard
        )
        let captured = state.captureSnapshot()

        // Diverge wildly.
        state._setTestState(
            score: 0,
            blocksPlaced: 0,
            linesCleared: 0,
            longestCombo: 0,
            currentCombo: 0,
            specialShapesUsed: 0,
            isGameOver: false,
            isNewHighScore: false,
            currentDifficulty: .easy
        )

        state.restore(from: captured)
        #expect(state.score == 999)
        #expect(state.blocksPlaced == 9)
        #expect(state.linesCleared == 9)
        #expect(state.longestCombo == 9)
        #expect(state.currentCombo == 9)
        #expect(state.specialShapesUsed == 9)
        #expect(state.isGameOver == true)
        #expect(state.isNewHighScore == true)
        #expect(state.currentDifficulty == .hard)
    }

    @Test @MainActor
    func captureRestoreRoundTripsThroughTrackerState() {
        let (state, _) = makeFreshGameState()
        let captured = state.captureSnapshot()

        // Mutate via a real placement so the tracker history advances.
        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("expected a placeable normal block in fresh state")
            return
        }
        state.placeBlock(block, at: pos)

        let mid = state.captureSnapshot()
        #expect(mid != captured, "placement must have changed the snapshot")

        state.restore(from: captured)
        let after = state.captureSnapshot()
        #expect(after == captured, "restore must reinstate every snapshot field, including tracker state")
    }

    @Test @MainActor
    func restoreReinstatesElapsedTime() {
        let (state, _) = makeFreshGameState()
        state.startGame(difficulty: .easy)
        let captured = state.captureSnapshot()

        // Drift the timer by reseting to a different elapsed.
        state.restore(from: captured)
        // Immediately after restore, currentGameTime should match the captured elapsed.
        let tolerance: TimeInterval = 0.25
        #expect(abs(state.currentGameTime - captured.elapsedGameTime) <= tolerance)
    }
}

// MARK: - Undo wired into placeBlock

@Suite("Undo: after placement")
struct UndoAfterPlacementTests {
    @Test @MainActor
    func successfulPlacementMakesUndoAvailable() {
        let (state, _) = makeFreshGameState()
        #expect(state.canUndo == false, "no undo before any placement")

        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("expected a placeable normal block in fresh state")
            return
        }
        state.placeBlock(block, at: pos)

        #expect(state.canUndo == true)
        #expect(state.undoUsed == false)
    }

    @Test @MainActor
    func undoRevertsScoreAndBlocksPlaced() {
        let (state, _) = makeFreshGameState()
        let scoreBefore = state.score
        let countBefore = state.blocksPlaced

        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("expected a placeable normal block in fresh state")
            return
        }
        state.placeBlock(block, at: pos)
        #expect(state.score > scoreBefore)
        #expect(state.blocksPlaced == countBefore + 1)

        state.undoLastPlacement()
        #expect(state.score == scoreBefore)
        #expect(state.blocksPlaced == countBefore)
        #expect(state.undoUsed == true)
        #expect(state.canUndo == false)
    }

    @Test @MainActor
    func undoRevertsGridAndCurrentBlocks() {
        let (state, _) = makeFreshGameState()
        let gridBefore = state.grid
        let blocksBefore = state.currentBlocks

        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("expected a placeable normal block in fresh state")
            return
        }
        state.placeBlock(block, at: pos)
        state.undoLastPlacement()

        #expect(state.grid == gridBefore)
        #expect(state.currentBlocks == blocksBefore)
    }
}

// MARK: - Undo after line clear

@Suite("Undo: after line clear")
struct UndoAfterLineClearTests {
    @Test @MainActor
    func undoReversesSingleLineClear() {
        let (state, _) = makeFreshGameState()
        var grid = GameLogic.createEmptyGrid()
        // Row 0 cells 1..7 filled — placing 1x1 at (0,0) completes the row.
        for col in 1..<8 { grid[0][col].isFilled = true }
        let oneByOne = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        state._setTestState(currentBlocks: [oneByOne], grid: grid)
        let scoreBefore = state.score
        let linesBefore = state.linesCleared
        let comboBefore = state.currentCombo

        state.placeBlock(oneByOne, at: GridPosition(row: 0, col: 0))
        #expect(state.linesCleared == linesBefore + 1)
        #expect(state.score > scoreBefore)
        #expect(state.currentCombo == 1)

        state.undoLastPlacement()
        #expect(state.grid == grid)
        #expect(state.score == scoreBefore)
        #expect(state.linesCleared == linesBefore)
        #expect(state.currentCombo == comboBefore)
    }
}

// MARK: - Undo after special block

@Suite("Undo: after special block")
struct UndoAfterSpecialBlockTests {
    @Test @MainActor
    func undoReversesHorizontalClearBlock() {
        let (state, _) = makeFreshGameState()
        var grid = GameLogic.createEmptyGrid()
        // Pre-fill some cells in row 4 — horizontal clear should wipe the whole row.
        for col in 0..<5 { grid[4][col].isFilled = true }
        let horizontal = BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .red,
            type: .horizontalClear
        )
        state._setTestState(currentBlocks: [horizontal], grid: grid)
        let scoreBefore = state.score
        let specialBefore = state.specialShapesUsed

        state.placeBlock(horizontal, at: GridPosition(row: 4, col: 0))
        #expect(state.specialShapesUsed == specialBefore + 1)
        #expect(state.score > scoreBefore)

        state.undoLastPlacement()
        #expect(state.grid == grid, "horizontal-clear placement must be fully reversed")
        #expect(state.specialShapesUsed == specialBefore)
        #expect(state.score == scoreBefore)
    }

    @Test @MainActor
    func undoReversesVerticalClearBlock() {
        let (state, _) = makeFreshGameState()
        var grid = GameLogic.createEmptyGrid()
        for row in 0..<5 { grid[row][3].isFilled = true }
        let vertical = BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .red,
            type: .verticalClear
        )
        state._setTestState(currentBlocks: [vertical], grid: grid)
        let scoreBefore = state.score

        state.placeBlock(vertical, at: GridPosition(row: 0, col: 3))
        state.undoLastPlacement()
        #expect(state.grid == grid)
        #expect(state.score == scoreBefore)
    }

    @Test @MainActor
    func undoReversesAreaClearBlock() {
        let (state, _) = makeFreshGameState()
        var grid = GameLogic.createEmptyGrid()
        // Pre-fill a 3x3 region that the area block will clear.
        for r in 3..<6 { for c in 3..<6 { grid[r][c].isFilled = true } }
        let area = BlockShape(
            positions: [GridPosition(row: 0, col: 0)],
            color: .red,
            type: .areaClear
        )
        state._setTestState(currentBlocks: [area], grid: grid)
        let scoreBefore = state.score

        state.placeBlock(area, at: GridPosition(row: 4, col: 4))
        state.undoLastPlacement()
        #expect(state.grid == grid)
        #expect(state.score == scoreBefore)
    }
}

// MARK: - Undo gating

@Suite("Undo: gating")
struct UndoGatingTests {
    @Test @MainActor
    func undoBeforeFirstPlacementIsNoOp() {
        let (state, _) = makeFreshGameState()
        let before = state.captureSnapshot()

        state.undoLastPlacement()
        let after = state.captureSnapshot()
        #expect(after == before)
        #expect(state.undoUsed == false, "no-op undo must not consume the once-per-game flag")
    }

    @Test @MainActor
    func undoCanOnlyHappenOncePerRun() {
        let (state, _) = makeFreshGameState()
        guard let blockA = state.currentBlocks.first(where: { $0.type == .normal }),
              let posA = anyPlaceablePosition(for: blockA, on: state) else {
            Issue.record("expected a placeable normal block"); return
        }
        state.placeBlock(blockA, at: posA)
        state.undoLastPlacement()
        #expect(state.undoUsed == true)
        #expect(state.canUndo == false)

        // Place again and try to undo a second time.
        guard let blockB = state.currentBlocks.first(where: { $0.type == .normal }),
              let posB = anyPlaceablePosition(for: blockB, on: state) else {
            Issue.record("expected a second placeable normal block"); return
        }
        let scoreAfterB = state.score + GameLogic.calculateBlockScore(block: blockB)
        state.placeBlock(blockB, at: posB)
        #expect(state.score >= scoreAfterB)
        #expect(state.canUndo == false, "second placement must not refill the undo slot")

        state.undoLastPlacement()
        #expect(state.score >= scoreAfterB, "second undo must be a no-op")
    }

    @Test @MainActor
    func failedPlacementDoesNotBurnUndoSlot() {
        let (state, _) = makeFreshGameState()
        // Fill grid so the placement is rejected by canPlaceBlock.
        var fullGrid = GameLogic.createEmptyGrid()
        for r in 0..<8 { for c in 0..<8 { fullGrid[r][c].isFilled = true } }
        state._setTestState(grid: fullGrid)

        guard let block = state.currentBlocks.first(where: { $0.type == .normal }) else {
            Issue.record("expected a normal block"); return
        }
        state.placeBlock(block, at: GridPosition(row: 0, col: 0))
        #expect(state.canUndo == false, "rejected placement must not stash an undo snapshot")
    }

    @Test @MainActor
    func resetGameRestoresUndoAvailability() {
        let (state, _) = makeFreshGameState()
        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("expected a placeable normal block"); return
        }
        state.placeBlock(block, at: pos)
        state.undoLastPlacement()
        #expect(state.undoUsed == true)

        state.resetGame()
        #expect(state.undoUsed == false)
        #expect(state.canUndo == false)
    }
}

// MARK: - Undo after game over

@Suite("Undo: after game over")
struct UndoAfterGameOverTests {
    @MainActor
    private func makeStateWithInMemoryStore() -> (GameState, CoreDataManager, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("UndoGameOverTests-\(UUID().uuidString).json")
        let coreData = CoreDataManager.makeInMemoryForTests()
        let mockGameCenter = MockGameCenterService()
        let gameService = GameService(coreDataManager: coreData, gameCenterService: mockGameCenter)
        let inProgressStore = InProgressGameStore(fileURL: url)
        let state = GameState(gameService: gameService, inProgressStore: inProgressStore)
        return (state, coreData, url)
    }

    @Test @MainActor
    func undoFlipsIsGameOverBack() {
        let (state, _, _) = makeStateWithInMemoryStore()
        // Capture a pre-game-over snapshot manually, then mark as game-over, then undo.
        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("expected a placeable normal block"); return
        }
        state.placeBlock(block, at: pos)
        state._setTestState(isGameOver: true)

        state.undoLastPlacement()
        #expect(state.isGameOver == false, "undo must flip isGameOver back to the snapshot's value")
    }

    @Test @MainActor
    func undoDeletesJustSavedGameRecord() {
        let (state, coreData, _) = makeStateWithInMemoryStore()
        // First drive a real placement so the undo slot has a snapshot.
        guard let block = state.currentBlocks.first(where: { $0.type == .normal }),
              let pos = anyPlaceablePosition(for: block, on: state) else {
            Issue.record("expected a placeable normal block"); return
        }
        state.placeBlock(block, at: pos)

        // Simulate the game-over save path: save a record and attach its id to the slot.
        try? coreData.saveGameRecord(
            score: 1234, difficulty: .easy, blocksPlaced: 7, linesCleared: 0,
            longestCombo: 0, gameTime: 30, sessionMetrics: nil
        )
        let preDeleteCount = coreData.fetchGameHistory().count
        #expect(preDeleteCount == 1)
        let savedID = coreData.fetchGameHistory().first?.id
        #expect(savedID != nil)

        state._setTestUndoSavedRecordID(savedID)
        state.undoLastPlacement()
        let postDeleteCount = coreData.fetchGameHistory().count
        #expect(postDeleteCount == 0, "undo must delete the saved GameRecord by id")
    }
}
