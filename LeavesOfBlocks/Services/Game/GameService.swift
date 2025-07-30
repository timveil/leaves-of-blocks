import Foundation
import UIKit
import Combine

// MARK: - Game Service

/// Handles game-related services like timing, persistence, and haptic feedback
class GameService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var currentGameTime: TimeInterval = 0
    private var gameTimer: Timer?
    private var gameStartTime: Date = Date()
    
    let highScoreManager = HighScoreManager()
    private let coreDataManager = CoreDataManager.shared
    
    // MARK: - Initialization
    
    init() {
        startGameTimer()
    }
    
    deinit {
        stopGameTimer()
    }
    
    // MARK: - Timer Management
    
    /// Starts the game timer to track elapsed time
    func startGameTimer() {
        gameStartTime = Date()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentGameTime = Date().timeIntervalSince(self.gameStartTime)
            }
        }
    }
    
    /// Stops the game timer
    func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    /// Resets the game timer
    func resetGameTimer() {
        stopGameTimer()
        currentGameTime = 0
        gameStartTime = Date()
        startGameTimer()
    }
    
    // MARK: - Game Time Utilities
    
    /// Returns the current game time
    var gameTime: TimeInterval {
        return currentGameTime
    }
    
    /// Formats game time as a readable string
    func formattedGameTime() -> String {
        let minutes = Int(currentGameTime) / 60
        let seconds = Int(currentGameTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - High Score Management
    
    /// Updates high score if current score is higher
    func updateHighScore(_ score: Int) -> Bool {
        let oldHighScore = highScoreManager.highScore
        highScoreManager.updateHighScore(score)
        return score > oldHighScore
    }
    
    /// Gets the current high score
    func getHighScore() -> Int {
        return highScoreManager.highScore
    }
    
    // MARK: - Game Record Management
    
    /// Saves a game record to persistent storage
    func saveGameRecord(
        score: Int,
        linesCleared: Int,
        blocksPlaced: Int,
        gameTime: TimeInterval,
        difficulty: DifficultyMode,
        longestCombo: Int
    ) {
        // Update high score
        let _ = updateHighScore(score)
        
        // Save to Core Data
        coreDataManager.saveGameRecord(
            score: score,
            difficulty: difficulty,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: gameTime
        )
    }
    
    // MARK: - Haptic Feedback
    
    /// Provides haptic feedback for block placement
    func blockPlacementFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Provides haptic feedback for line clearing
    func lineClearFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Provides haptic feedback for game over
    func gameOverFeedback() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    /// Provides haptic feedback for new high score
    func newHighScoreFeedback() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Provides haptic feedback for block return to holding area
    func blockReturnFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Game Session Management
    
    /// Starts a new game session
    func startGameSession(difficulty: DifficultyMode) {
        resetGameTimer()
        // Any other session initialization logic
    }
    
    /// Ends the current game session
    func endGameSession() {
        stopGameTimer()
        // Any cleanup logic
    }
}