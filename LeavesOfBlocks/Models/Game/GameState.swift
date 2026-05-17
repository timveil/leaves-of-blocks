import Foundation

/// The main game state management class that handles all game logic and UI state.
///
/// `GameState` is an `@Observable` class that manages the current state of the game,
/// including the grid, active blocks, score, and game statistics. It delegates
/// business logic to `GameLogic` and infrastructure concerns to `GameService`.
///
/// ## Usage
/// ```swift
/// let gameState = GameState()
/// gameState.startGame(difficulty: .moderate)
/// ```
@MainActor
@Observable
final class GameState {

    // MARK: - Observable Properties

    /// State writes go through the methods on this type (placeBlock, resetGame,
    /// etc.) so callers can't accidentally bypass `GameLogic` and corrupt
    /// invariants like score monotonicity or grid validity. Tests and
    /// previews that need to inject arbitrary state use the DEBUG-only
    /// `_setTestState(...)` seam.
    private(set) var grid: [[GridCell]]
    private(set) var currentBlocks: [BlockShape]
    private(set) var score: Int = 0
    private(set) var isGameOver: Bool = false
    private(set) var linesCleared: Int = 0
    private(set) var lastClearedCells: [ClearedCell] = []

    // Game Statistics
    private(set) var blocksPlaced: Int = 0
    private(set) var gameStartTime: Date = Date()
    private(set) var longestCombo: Int = 0
    private(set) var currentCombo: Int = 0
    private(set) var isNewHighScore: Bool = false
    private(set) var specialShapesUsed: Int = 0  // Track special shape usage

    // Difficulty mode
    private(set) var currentDifficulty: DifficultyMode = .easy

    // MARK: - Undo State

    /// Whether the once-per-game undo has been consumed. Observed so the UI
    /// can grey out the undo button after a successful `undoLastPlacement()`.
    private(set) var undoUsed: Bool = false

    /// The pre-placement snapshot captured most recently inside `placeBlock`,
    /// or `nil` when no placement has been made (or the slot has already been
    /// consumed). Not observed — `canUndo` exposes the relevant binary signal
    /// to the UI; the snapshot payload itself shouldn't trigger view rerenders.
    @ObservationIgnored private var lastUndoSnapshot: UndoSnapshot?

    /// Whether the player can undo right now. The undo button binds to this.
    var canUndo: Bool {
        !undoUsed && lastUndoSnapshot != nil
    }

    // MARK: - Hint State

    /// Whether the once-per-game hint has been consumed.
    private(set) var hintUsed: Bool = false

    /// Whether the player can request a hint right now. Disabled at game-over
    /// (no useful placement to suggest) or after the hint has already been
    /// used for this run.
    var canHint: Bool {
        !hintUsed && !isGameOver
    }

    // MARK: - Services

    private let gameService: GameService
    private let behaviorTracker: PlayerBehaviorTracker
    private let inProgressStore: any InProgressGameStoring

    // MARK: - Computed Properties

    var currentGameTime: TimeInterval {
        return gameService.currentGameTime
    }

    var highScore: Int {
        return gameService.getHighScore()
    }
    
    var statistics: GameSessionStatistics {
        return GameSessionStatistics.withEfficiencyMetrics(
            from: behaviorTracker,
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            gameTime: currentGameTime,
            longestCombo: longestCombo,
            currentCombo: currentCombo,
            difficulty: currentDifficulty
        )
    }
    
    // MARK: - Initialization

    /// Creates a new game state.
    ///
    /// Service dependencies are injected so tests can pass fakes or capture side effects.
    /// Pass `nil` (the default) to get a freshly constructed production service.
    ///
    /// On launch, if the in-progress store holds a saved snapshot, the game state
    /// is rehydrated from it instead of starting fresh.
    ///
    /// - Parameters:
    ///   - gameService: Timing, persistence, and haptics. `nil` constructs a default `GameService`.
    ///   - behaviorTracker: Per-session efficiency/strategy tracker. `nil` constructs a default `PlayerBehaviorTracker`.
    ///   - inProgressStore: Single-slot store for the active run. `nil` uses the shared instance.
    ///     The parameter is typed as `any InProgressGameStoring` so tests can
    ///     inject an in-memory fake instead of hitting disk.
    init(
        gameService: GameService? = nil,
        behaviorTracker: PlayerBehaviorTracker? = nil,
        inProgressStore: (any InProgressGameStoring)? = nil
    ) {
        self.gameService = gameService ?? GameService()
        self.behaviorTracker = behaviorTracker ?? PlayerBehaviorTracker()
        self.inProgressStore = inProgressStore ?? InProgressGameStore.shared
        grid = GameLogic.createEmptyGrid()
        currentBlocks = []

        // UI tests and screenshot runs always start from a clean state so
        // tests aren't affected by a saved in-progress game from a prior run.
        if AppConfiguration.Runtime.isUITesting {
            self.inProgressStore.clear()
            generateNewBlocks()
        } else if let snapshot = self.inProgressStore.load() {
            apply(snapshot: snapshot)
        } else {
            generateNewBlocks()
        }
    }

    /// Rehydrates this `GameState` from a saved snapshot.
    private func apply(snapshot: InProgressGameSnapshot) {
        grid = snapshot.grid
        currentBlocks = snapshot.currentBlocks
        score = snapshot.score
        linesCleared = snapshot.linesCleared
        blocksPlaced = snapshot.blocksPlaced
        longestCombo = snapshot.longestCombo
        currentCombo = snapshot.currentCombo
        specialShapesUsed = snapshot.specialShapesUsed
        currentDifficulty = snapshot.difficulty
        isGameOver = false
        lastClearedCells = []
        isNewHighScore = false
        gameStartTime = snapshot.savedAt.addingTimeInterval(-snapshot.elapsedGameTime)

        // Behavior tracker starts fresh on resume; analytics reflect post-resume play only.
        // `isInitialSeed: true` populates the rolling averages without counting
        // the just-resumed grid toward `challengeMaintained`.
        behaviorTracker.startSession()
        behaviorTracker.recordGridState(grid, isInitialSeed: true)

        gameService.startGameSession(
            difficulty: snapshot.difficulty,
            resumingFromElapsed: snapshot.elapsedGameTime
        )
    }

    // MARK: - Undo Snapshot

    /// Captures the entire mutable game state for use as an undo target.
    ///
    /// Unlike `snapshot() -> InProgressGameSnapshot` (which is lossy — it omits
    /// behavior-tracker analytics and the game-over flag because resume starts
    /// the tracker fresh), this snapshot is the exact pre-placement state and
    /// is held in memory only.
    func captureSnapshot() -> UndoSnapshot {
        UndoSnapshot(
            grid: grid,
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
            elapsedGameTime: gameService.currentGameTime,
            trackerState: behaviorTracker.captureState(),
            savedRecordID: nil
        )
    }

    /// Returns a suggested placement for one of the held blocks, or `nil` if
    /// no placement is available (which only happens when the game is
    /// effectively over). Consumes the once-per-game hint slot only when a
    /// hint is actually returned — a nil result leaves the slot intact.
    func requestHint() -> GameLogic.Hint? {
        guard canHint else { return nil }
        guard let hint = GameLogic.findHint(blocks: currentBlocks, grid: grid) else { return nil }
        hintUsed = true
        return hint
    }

    /// Reverses the most recent placement, including any line clears, special
    /// block effects, or game-over save it triggered. Consumes the once-per-game
    /// undo slot — subsequent placements cannot be undone until `resetGame()`
    /// runs.
    func undoLastPlacement() {
        guard !undoUsed, let snapshot = lastUndoSnapshot else { return }

        // Delete the just-saved GameRecord if the placement caused game-over.
        // Best-effort: log and continue if the deletion fails (the user still
        // gets the state revert, which is the user-visible outcome).
        if let recordID = snapshot.savedRecordID {
            do {
                try gameService.deleteGameRecord(id: recordID)
            } catch {
                BuildConfiguration.log("Undo: failed to delete saved GameRecord \(recordID): \(error.localizedDescription)", level: .error)
            }
        }

        restore(from: snapshot)
        undoUsed = true
        lastUndoSnapshot = nil

        // Re-sync the in-progress store with the restored state so a background
        // / launch resume sees the pre-placement run, not the post-placement one.
        if hasActiveRun {
            inProgressStore.save(self.snapshot())
        } else {
            inProgressStore.clear()
        }
    }

    /// Used internally by `checkGameOver` to attach the just-saved GameRecord id
    /// to the pending undo snapshot. The snapshot's fields are `let`, so we
    /// rebuild it with the additional id.
    private func attachSavedRecordIDToUndoSnapshot(_ id: UUID) {
        guard let existing = lastUndoSnapshot else { return }
        lastUndoSnapshot = UndoSnapshot(
            grid: existing.grid,
            currentBlocks: existing.currentBlocks,
            score: existing.score,
            isGameOver: existing.isGameOver,
            linesCleared: existing.linesCleared,
            lastClearedCells: existing.lastClearedCells,
            blocksPlaced: existing.blocksPlaced,
            longestCombo: existing.longestCombo,
            currentCombo: existing.currentCombo,
            isNewHighScore: existing.isNewHighScore,
            specialShapesUsed: existing.specialShapesUsed,
            currentDifficulty: existing.currentDifficulty,
            elapsedGameTime: existing.elapsedGameTime,
            trackerState: existing.trackerState,
            savedRecordID: id
        )
    }

    /// Replays a snapshot back into the game state, including tracker history
    /// and elapsed game time. Does not consume the undo slot — `undoLastPlacement()`
    /// owns the slot-consumption side effect.
    func restore(from snapshot: UndoSnapshot) {
        grid = snapshot.grid
        currentBlocks = snapshot.currentBlocks
        score = snapshot.score
        isGameOver = snapshot.isGameOver
        linesCleared = snapshot.linesCleared
        lastClearedCells = snapshot.lastClearedCells
        blocksPlaced = snapshot.blocksPlaced
        longestCombo = snapshot.longestCombo
        currentCombo = snapshot.currentCombo
        isNewHighScore = snapshot.isNewHighScore
        specialShapesUsed = snapshot.specialShapesUsed
        currentDifficulty = snapshot.currentDifficulty
        behaviorTracker.restore(snapshot.trackerState)
        gameService.resetGameTimer(resumingFromElapsed: snapshot.elapsedGameTime)
    }

    /// Captures the current in-flight game state for persistence.
    func snapshot() -> InProgressGameSnapshot {
        InProgressGameSnapshot(
            grid: grid,
            currentBlocks: currentBlocks,
            score: score,
            linesCleared: linesCleared,
            blocksPlaced: blocksPlaced,
            longestCombo: longestCombo,
            currentCombo: currentCombo,
            specialShapesUsed: specialShapesUsed,
            difficulty: currentDifficulty,
            elapsedGameTime: currentGameTime,
            savedAt: Date()
        )
    }

    /// Whether a meaningful run is currently in progress (worth persisting / resuming).
    var hasActiveRun: Bool {
        score > 0 && !isGameOver
    }

    /// Persists the current run to the in-progress store, if there is one to save.
    func persistInProgressGame() {
        guard hasActiveRun else { return }
        inProgressStore.save(snapshot())
    }
    
    // MARK: - Game Actions
    
    /// Generates a new set of blocks for the player to place.
    ///
    /// This method creates 3 new blocks using weighted random generation based on the current
    /// difficulty level. After generating new blocks, it automatically checks if the game is over
    /// by testing if any of the new blocks can be placed on the current grid.
    ///
    /// - Note: This method is called automatically when all current blocks have been placed,
    ///   or when starting/resetting a game.
    func generateNewBlocks() {
        currentBlocks = BlockGenerator.generateTieredBlocks(count: 3, difficulty: currentDifficulty, grid: grid, behaviorTracker: behaviorTracker)
        checkGameOver()
    }
    
    /// Validates whether a block can be placed at the specified grid position.
    ///
    /// This method checks if the given block can be legally placed at the target position
    /// without overlapping existing blocks or extending beyond grid boundaries.
    ///
    /// - Parameters:
    ///   - block: The `BlockShape` to validate for placement
    ///   - gridPosition: The target `GridPosition` where the block would be placed
    /// - Returns: `true` if the block can be placed, `false` otherwise
    ///
    /// ## Example
    /// ```swift
    /// let block = BlockShape.allShapes[0] // Single block
    /// let position = GridPosition(row: 2, col: 3)
    /// if gameState.canPlaceBlock(block, at: position) {
    ///     gameState.placeBlock(block, at: position)
    /// }
    /// ```
    func canPlaceBlock(_ block: BlockShape, at gridPosition: GridPosition) -> Bool {
        return GameLogic.canPlaceBlock(block, at: gridPosition, in: grid)
    }
    
    /// Places a block on the game grid at the specified position.
    ///
    /// This method handles the complete block placement process, including validation,
    /// grid updates, scoring, line clearing, and game state management. It provides
    /// haptic feedback and automatically generates new blocks when needed.
    ///
    /// - Parameters:
    ///   - block: The `BlockShape` to place on the grid
    ///   - gridPosition: The `GridPosition` where the block should be placed
    ///
    /// ## Process Flow
    /// 1. Validates placement using `canPlaceBlock(_:at:)`
    /// 2. Updates the grid with the new block
    /// 3. Calculates and adds score points
    /// 4. Removes the placed block from available blocks
    /// 5. Clears any completed lines and awards bonus points
    /// 6. Generates new blocks if all current blocks are used
    /// 7. Checks for game over conditions
    ///
    /// - Note: If placement is invalid, the method returns early without making changes.
    ///   The method automatically provides haptic feedback and updates all relevant statistics.
    func placeBlock(_ block: BlockShape, at gridPosition: GridPosition) {
        guard canPlaceBlock(block, at: gridPosition) else { return }

        // Capture the pre-placement state for undo. Stashed only when the
        // once-per-game slot hasn't been consumed yet — if it has, every
        // subsequent placement is final and snapshot capture is skipped.
        if !undoUsed {
            lastUndoSnapshot = captureSnapshot()
        }

        BuildConfiguration.log("Placing block with \(block.positions.count) cells at (\(gridPosition.row), \(gridPosition.col))", level: .debug)
        
        // Haptic feedback for block placement
        gameService.blockPlacementFeedback()
        
        // Place the block using GameLogic
        GameLogic.placeBlock(block, at: gridPosition, in: &grid)
        
        // Update statistics
        blocksPlaced += 1
        
        // Track special shape usage
        if block.type != .normal {
            specialShapesUsed += 1
        }
        
        // Add points for placing block
        score += GameLogic.calculateBlockScore(block: block)
        
        // Remove the placed block from current blocks by stable instance id.
        // Matching on shape (positions + color) alone would silently remove a
        // look-alike twin if the generator offered two blocks with the same
        // shape and color — see H7 in the code review.
        if let index = currentBlocks.firstIndex(where: { $0.id == block.id }) {
            currentBlocks.remove(at: index)
        }
        
        // Clear completed lines
        let clearResult = clearCompletedLines()
        lastClearedCells = clearResult.clearedCells
        
        // Generate new blocks if all are used
        if currentBlocks.isEmpty {
            generateNewBlocks()
        }
        
        // Record grid state for behavior tracking after each move
        behaviorTracker.recordGridState(grid)
        
        // Always check for game over after placing a block
        // This ensures immediate detection when no moves are available
        checkGameOver()

        // Auto-save the in-flight game so we can resume after backgrounding or
        // navigating away. On natural game-over `checkGameOver()` already cleared
        // the slot, so skip then.
        if !isGameOver {
            inProgressStore.save(snapshot())
        }
    }
    
    func clearCompletedLines() -> (clearedRows: Set<Int>, clearedCols: Set<Int>, clearedCells: [ClearedCell]) {
        // Use GameLogic to clear completed lines
        let clearResult = GameLogic.clearCompletedLines(in: &grid)
        
        // Add bonus points
        let totalLinesCleared = clearResult.clearedRows.count + clearResult.clearedCols.count
        if totalLinesCleared > 0 {
            // Haptic feedback for line clearing
            gameService.lineClearFeedback()
            
            linesCleared += totalLinesCleared
            score += GameLogic.calculateLineScore(clearedRows: clearResult.clearedRows.count, clearedCols: clearResult.clearedCols.count)
            
            // Update combo tracking
            currentCombo = totalLinesCleared
            if currentCombo > longestCombo {
                longestCombo = currentCombo
            }
        } else {
            currentCombo = 0
        }
        
        return clearResult
    }
    
    func checkGameOver() {
        // If no current blocks, it's not game over (waiting for new blocks)
        guard !currentBlocks.isEmpty else {
            isGameOver = false
            return
        }
        
        // Use GameLogic to check game over state
        let gameOverState = GameLogic.isGameOver(currentBlocks: currentBlocks, grid: grid)

        #if DEBUG
        BuildConfiguration.log("Game Over Check: hasBlocks=\(currentBlocks.count), gameOverState=\(gameOverState), currentGameOver=\(isGameOver)", level: .debug)
        if gameOverState {
            BuildConfiguration.log("No valid moves found for current blocks: \(currentBlocks.map { $0.positions.count })", level: .debug)
        }
        #endif

        if gameOverState && !isGameOver {
            // Game just ended - handle high score
            BuildConfiguration.log("GAME OVER DETECTED! Final score: \(score)", level: .info)
            isGameOver = true
            gameService.endGameSession()
            
            isNewHighScore = gameService.isNewHighScore(score)
            
            if isNewHighScore {
                gameService.newHighScoreFeedback()
            } else {
                gameService.gameOverFeedback()
            }
            
            // Save game record with efficiency metrics
            let sessionMetrics = behaviorTracker.finalizeSession(
                score: score,
                blocksPlaced: blocksPlaced,
                linesCleared: linesCleared,
                longestCombo: longestCombo,
                gameTime: currentGameTime,
                difficulty: currentDifficulty
            )

            do {
                let savedID = try gameService.saveGameRecord(
                    score: score,
                    linesCleared: linesCleared,
                    blocksPlaced: blocksPlaced,
                    gameTime: currentGameTime,
                    difficulty: currentDifficulty,
                    longestCombo: longestCombo,
                    sessionMetrics: sessionMetrics
                )
                // Attach the saved record id to the pending undo snapshot so
                // `undoLastPlacement()` can delete the exact row (no "most recent"
                // race with any future save).
                attachSavedRecordIDToUndoSnapshot(savedID)
            } catch {
                BuildConfiguration.log("Failed to save game record: \(error.localizedDescription)", level: .error)
            }

            // The run is finalized — clear the in-progress slot so the next
            // launch starts fresh.
            inProgressStore.clear()
        } else if !gameOverState {
            // Game is still active
            isGameOver = false
        }
    }
    
    /// Starts a new game with the specified difficulty level.
    ///
    /// This method initializes a fresh game session by setting the difficulty
    /// and calling `resetGame()` to clear all game state.
    ///
    /// - Parameter difficulty: The `DifficultyMode` for the new game session
    ///
    /// ## Available Difficulty Modes
    /// - `.easy`: Favors smaller blocks, more forgiving generation
    /// - `.moderate`: Balanced block distribution
    /// - `.hard`: Increases chance of larger, complex blocks
    func startGame(difficulty: DifficultyMode) {
        currentDifficulty = difficulty
        resetGame()
    }
    
    /// Resets the current game to its initial state.
    ///
    /// This method clears all game progress and reinitializes the game state for a fresh start.
    /// It maintains the current difficulty level but resets all scores, statistics, and the game grid.
    ///
    /// ## Reset Operations
    /// - Clears the 8x8 game grid
    /// - Resets score and statistics to zero
    /// - Generates new starting blocks
    /// - Randomly pre-fills some grid positions
    /// - Starts a new game session with timing
    ///
    /// - Note: This method is called automatically by `startGame(difficulty:)`
    ///   and can be used to restart the current game without changing difficulty.
    func resetGame() {
        // Discard any persisted in-progress game; the new run starts from scratch.
        inProgressStore.clear()

        // Reset assist features: a fresh run gets a fresh undo + hint budget.
        undoUsed = false
        hintUsed = false
        lastUndoSnapshot = nil

        // Reset grid using GameLogic
        grid = GameLogic.createEmptyGrid()

        // Reset game state
        score = 0
        linesCleared = 0
        isGameOver = false
        lastClearedCells = []
        
        // Reset statistics
        blocksPlaced = 0
        gameStartTime = Date()
        longestCombo = 0
        currentCombo = 0
        isNewHighScore = false
        specialShapesUsed = 0
        
        // Start behavior tracking session
        behaviorTracker.startSession()
        
        // Pre-fill the grid with geometric patterns based on difficulty
        GameLogic.randomlyFillGrid(&grid, difficulty: currentDifficulty)
        
        // Record initial grid state for tracking. `isInitialSeed: true` so
        // the pre-fill doesn't skew `challengeMaintained` — the metric is
        // about player choices over the run, not the starting board.
        behaviorTracker.recordGridState(grid, isInitialSeed: true)
        
        generateNewBlocks()
        
        // Start game session with service
        gameService.startGameSession(difficulty: currentDifficulty)
    }
    
    // MARK: - Haptic Feedback
    
    /// Provides haptic feedback when a block is returned to its original position.
    ///
    /// This method triggers light haptic feedback to indicate that a dragged block
    /// has been returned to its starting position without being placed on the grid.
    ///
    /// - Note: This method is typically called by the UI when a drag gesture is cancelled
    ///   or when a block cannot be placed at the attempted position.
    func blockReturnFeedback() {
        gameService.blockReturnFeedback()
    }
    
    // MARK: - Data Management

    /// Clears all persisted game history. Throws if Core Data fails to delete.
    func clearGameHistory() throws {
        try gameService.clearGameHistory()
    }

    /// Clears all persisted data and resets the active game. Throws if the
    /// underlying Core Data deletion fails; the active in-memory run is reset
    /// regardless so the UI doesn't show stale state.
    func resetAllData() throws {
        defer { resetGame() }
        try gameService.resetAllData()
    }

#if DEBUG
    // MARK: - Test / Preview Seam

    /// Injects state directly for tests and previews. Compiled out of release
    /// builds so production code can't accidentally use it to bypass the
    /// `GameLogic`-mediated transitions. Each parameter is optional — passing
    /// `nil` leaves the corresponding field untouched.
    ///
    /// For production state setup, prefer `startGame(difficulty:)` or
    /// rehydrating from an `InProgressGameSnapshot` via the init.
    func _setTestState(
        score: Int? = nil,
        blocksPlaced: Int? = nil,
        linesCleared: Int? = nil,
        longestCombo: Int? = nil,
        currentCombo: Int? = nil,
        specialShapesUsed: Int? = nil,
        isGameOver: Bool? = nil,
        isNewHighScore: Bool? = nil,
        currentDifficulty: DifficultyMode? = nil,
        currentBlocks: [BlockShape]? = nil,
        grid: [[GridCell]]? = nil,
        lastClearedCells: [ClearedCell]? = nil
    ) {
        if let score { self.score = score }
        if let blocksPlaced { self.blocksPlaced = blocksPlaced }
        if let linesCleared { self.linesCleared = linesCleared }
        if let longestCombo { self.longestCombo = longestCombo }
        if let currentCombo { self.currentCombo = currentCombo }
        if let specialShapesUsed { self.specialShapesUsed = specialShapesUsed }
        if let isGameOver { self.isGameOver = isGameOver }
        if let isNewHighScore { self.isNewHighScore = isNewHighScore }
        if let currentDifficulty { self.currentDifficulty = currentDifficulty }
        if let currentBlocks { self.currentBlocks = currentBlocks }
        if let grid { self.grid = grid }
        if let lastClearedCells { self.lastClearedCells = lastClearedCells }
    }

    /// Attaches a `savedRecordID` to the pending undo snapshot. Mirrors the
    /// production path inside `checkGameOver` without requiring a test to
    /// actually trigger a natural game-over.
    func _setTestUndoSavedRecordID(_ id: UUID?) {
        guard let id, lastUndoSnapshot != nil else { return }
        attachSavedRecordIDToUndoSnapshot(id)
    }
#endif
}