import Foundation
import UIKit
import Combine

// MARK: - Game Service

/// Handles game-related services like timing, persistence, and haptic feedback
class GameService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var currentGameTime: TimeInterval = 0
    private var _gameTimer: Timer?
    private var gameStartTime: Date = Date()
    private var isTimerActive: Bool = false
    
    private let coreDataManager = CoreDataManager.shared
    
    // MARK: - Timer Property with Safe Management
    
    private var gameTimer: Timer? {
        get { _gameTimer }
        set {
            _gameTimer?.invalidate()
            _gameTimer = newValue
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Timer will be started lazily when needed
    }
    
    deinit {
        stopGameTimer()
    }
    
    // MARK: - Timer Management
    
    /// Starts the game timer to track elapsed time
    func startGameTimer() {
        guard !isTimerActive else { return } // Prevent duplicate timers
        
        gameStartTime = Date()
        currentGameTime = 0
        isTimerActive = true
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentGameTime = Date().timeIntervalSince(self.gameStartTime)
            }
        }
    }
    
    /// Stops the game timer
    func stopGameTimer() {
        gameTimer = nil // This will automatically invalidate due to our custom setter
        isTimerActive = false
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
    
    /// Checks if the given score is a new high score
    func isNewHighScore(_ score: Int) -> Bool {
        let statistics = coreDataManager.calculateStatistics()
        return score > statistics.highScore
    }
    
    /// Gets the current high score from Core Data
    func getHighScore() -> Int {
        let statistics = coreDataManager.calculateStatistics()
        return statistics.highScore
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
        // High score is automatically tracked in Core Data
        
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