import Foundation
import SwiftUI

class GameState: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var grid: [[GridCell]]
    @Published var currentBlocks: [BlockShape]
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var linesCleared: Int = 0
    @Published var lastClearedCells: [ClearedCell] = []
    
    // Game Statistics
    @Published var blocksPlaced: Int = 0
    @Published var gameStartTime: Date = Date()
    @Published var longestCombo: Int = 0
    @Published var currentCombo: Int = 0
    @Published var isNewHighScore: Bool = false
    
    // Difficulty mode
    @Published var currentDifficulty: DifficultyMode = .easy
    
    // MARK: - Services
    
    private let gameService = GameService()
    
    // MARK: - Computed Properties
    
    var currentGameTime: TimeInterval {
        return gameService.currentGameTime
    }
    
    var highScore: Int {
        return gameService.getHighScore()
    }
    
    var statistics: GameSessionStatistics {
        return GameSessionStatistics(
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
    
    func generateNewBlocks() {
        currentBlocks = BlockGenerator.generateWeightedBlocks(count: 3, difficulty: currentDifficulty)
        checkGameOver()
    }
    
    func canPlaceBlock(_ block: BlockShape, at gridPosition: GridPosition) -> Bool {
        return GameLogic.canPlaceBlock(block, at: gridPosition, in: grid)
    }
    
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
        
        // Add points for placing block
        score += GameLogic.calculateBlockScore(blockSize: block.positions.count)
        
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
            
            let oldHighScore = gameService.getHighScore()
            isNewHighScore = gameService.updateHighScore(score)
            
            if isNewHighScore {
                gameService.newHighScoreFeedback()
            } else {
                gameService.gameOverFeedback()
            }
            
            // Save game record
            gameService.saveGameRecord(
                score: score,
                linesCleared: linesCleared,
                blocksPlaced: blocksPlaced,
                gameTime: currentGameTime,
                difficulty: currentDifficulty,
                longestCombo: longestCombo
            )
        } else if !gameOverState {
            // Game is still active
            isGameOver = false
        }
    }
    
    func startGame(difficulty: DifficultyMode) {
        currentDifficulty = difficulty
        resetGame()
    }
    
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
        
        // Randomly pre-fill the grid with shapes
        GameLogic.randomlyFillGrid(&grid)
        
        generateNewBlocks()
        
        // Start game session with service
        gameService.startGameSession(difficulty: currentDifficulty)
    }
}