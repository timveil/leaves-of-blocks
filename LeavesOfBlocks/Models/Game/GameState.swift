import Foundation
import SwiftUI

/// The main game state management class that handles all game logic and UI state.
///
/// `GameState` is an `ObservableObject` that manages the current state of the game,
/// including the grid, active blocks, score, and game statistics. It delegates
/// business logic to `GameLogic` and infrastructure concerns to `GameService`.
///
/// ## Usage
/// ```swift
/// let gameState = GameState()
/// gameState.startGame(difficulty: .moderate)
/// ```
class GameState: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var grid: [[GridCell]]
    @Published var currentBlocks: [BlockShape]
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var showSaveGameOverlay: Bool = false
    @Published var linesCleared: Int = 0
    @Published var lastClearedCells: [ClearedCell] = []
    
    // Game Statistics
    @Published var blocksPlaced: Int = 0
    @Published var gameStartTime: Date = Date()
    @Published var longestCombo: Int = 0
    @Published var currentCombo: Int = 0
    @Published var isNewHighScore: Bool = false
    @Published var specialShapesUsed: Int = 0  // Track special shape usage
    
    // Difficulty mode
    @Published var currentDifficulty: DifficultyMode = .easy
    
    // MARK: - Services
    
    private let gameService = GameService()
    private let behaviorTracker = PlayerBehaviorTracker()
    
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
    
    init() {
        grid = GameLogic.createEmptyGrid()
        currentBlocks = []
        generateNewBlocks()
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
        
        #if DEBUG
        print("🧩 Placing block with \(block.positions.count) cells at (\(gridPosition.row), \(gridPosition.col))")
        #endif
        
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
        
        // Remove the placed block from current blocks
        if let index = currentBlocks.firstIndex(where: { $0.positions == block.positions && $0.color == block.color }) {
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
        print("🎮 Game Over Check: hasBlocks=\(currentBlocks.count), gameOverState=\(gameOverState), currentGameOver=\(isGameOver)")
        if gameOverState {
            print("🚫 No valid moves found for current blocks:")
            for (index, block) in currentBlocks.enumerated() {
                print("   Block \(index): \(block.positions.count) cells")
            }
        }
        #endif
        
        if gameOverState && !isGameOver {
            // Game just ended - handle high score
            print("🏁 GAME OVER DETECTED! Final score: \(score)")
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
            
            gameService.saveGameRecord(
                score: score,
                linesCleared: linesCleared,
                blocksPlaced: blocksPlaced,
                gameTime: currentGameTime,
                difficulty: currentDifficulty,
                longestCombo: longestCombo,
                sessionMetrics: sessionMetrics
            )
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
        
        // Record initial grid state for tracking
        behaviorTracker.recordGridState(grid)
        
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
    
    // MARK: - Save Game Actions
    
    /// Shows the save game overlay dialog.
    ///
    /// This method displays a modal overlay that allows the user to choose between
    /// saving the current game or exiting without saving.
    func showSaveGameDialog() {
        showSaveGameOverlay = true
    }
    
    /// Saves the current game and ends the session.
    ///
    /// This method saves the current game state as a completed game record
    /// and ends the current session. The navigation completion should be handled
    /// by the calling view.
    ///
    /// - Parameter onComplete: Callback to execute after save is complete
    func saveAndEndGame(onComplete: @escaping () -> Void = {}) {
        gameService.endGameSession()
        
        // Save game record with current progress
        let sessionMetrics = behaviorTracker.finalizeSession(
            score: score,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: currentGameTime,
            difficulty: currentDifficulty
        )
        
        gameService.saveGameRecord(
            score: score,
            linesCleared: linesCleared,
            blocksPlaced: blocksPlaced,
            gameTime: currentGameTime,
            difficulty: currentDifficulty,
            longestCombo: longestCombo,
            sessionMetrics: sessionMetrics
        )
        
        showSaveGameOverlay = false
        onComplete()
    }
    
    /// Exits the current game without saving.
    ///
    /// This method ends the current game session without creating a game record.
    /// The navigation completion should be handled by the calling view.
    ///
    /// - Parameter onComplete: Callback to execute after exit is complete
    func exitWithoutSaving(onComplete: @escaping () -> Void = {}) {
        gameService.endGameSession()
        showSaveGameOverlay = false
        onComplete()
    }
}