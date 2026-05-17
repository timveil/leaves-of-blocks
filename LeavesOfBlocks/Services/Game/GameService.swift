import Foundation
import UIKit

// MARK: - Game Service

/// Handles game-related services like timing, persistence, and haptic feedback.
@MainActor
@Observable
final class GameService {

    // MARK: - Properties

    var currentGameTime: TimeInterval = 0
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var gameStartTime: Date = Date()
    @ObservationIgnored private var isTimerActive: Bool = false

    private let coreDataManager: CoreDataManager

    // MARK: - Initialization

    /// Creates a `GameService`.
    ///
    /// - Parameter coreDataManager: Storage backend for high scores and game
    ///   history. Pass `nil` (the default) to use the production singleton;
    ///   tests can pass `CoreDataManager.makeInMemoryForTests()` for isolation.
    ///   The `nil` default + `?? .shared` resolution sidesteps a Swift 6
    ///   warning: a default expression of `.shared` would be evaluated in a
    ///   nonisolated caller context, but `.shared` is `@MainActor`-isolated.
    ///   Resolving inside the init body inherits the class's `@MainActor`
    ///   isolation and stays Swift 6-compliant.
    init(coreDataManager: CoreDataManager? = nil) {
        self.coreDataManager = coreDataManager ?? .shared
    }

    deinit {
        timerTask?.cancel()
    }

    // MARK: - Timer Management

    /// Starts the game timer to track elapsed time.
    ///
    /// - Parameter elapsed: Seconds already accumulated for this run, when resuming
    ///   a saved game. Defaults to `0` (fresh game).
    func startGameTimer(resumingFromElapsed elapsed: TimeInterval = 0) {
        guard !isTimerActive else { return }

        gameStartTime = Date().addingTimeInterval(-elapsed)
        currentGameTime = elapsed
        isTimerActive = true

        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, self.isTimerActive else { break }
                self.currentGameTime = Date().timeIntervalSince(self.gameStartTime)
            }
        }
    }

    /// Stops the game timer
    func stopGameTimer() {
        timerTask?.cancel()
        timerTask = nil
        isTimerActive = false
    }

    /// Resets the game timer.
    ///
    /// - Parameter elapsed: Seconds already accumulated for this run, when resuming
    ///   a saved game. Defaults to `0` (fresh game).
    func resetGameTimer(resumingFromElapsed elapsed: TimeInterval = 0) {
        stopGameTimer()
        currentGameTime = elapsed
        gameStartTime = Date().addingTimeInterval(-elapsed)
        startGameTimer(resumingFromElapsed: elapsed)
    }
    
    // MARK: - Game Time Utilities
    
    /// Returns the current game time
    var gameTime: TimeInterval {
        return currentGameTime
    }
    
    /// Formats game time as a readable string
    func formattedGameTime() -> String {
        currentGameTime.formattedAsClock
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
    
    /// Saves a game record to persistent storage.
    ///
    /// Throws if Core Data fails to persist the record. The Game Center
    /// submission is intentionally still attempted only on a successful local
    /// save — Game Center is the secondary store, not the source of truth.
    func saveGameRecord(
        score: Int,
        linesCleared: Int,
        blocksPlaced: Int,
        gameTime: TimeInterval,
        difficulty: DifficultyMode,
        longestCombo: Int,
        sessionMetrics: PlayerBehaviorTracker.SessionMetrics? = nil
    ) throws {
        try coreDataManager.saveGameRecord(
            score: score,
            difficulty: difficulty,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            longestCombo: longestCombo,
            gameTime: gameTime,
            sessionMetrics: sessionMetrics
        )

        // Submit to Game Center if the user has opted in. The service is a
        // no-op when the preference is off or the player isn't authenticated.
        GameCenterService.shared.submitFinalScore(
            score: score,
            sessionMetrics: sessionMetrics,
            longestCombo: longestCombo
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
    
    /// Starts a new game session.
    ///
    /// - Parameters:
    ///   - difficulty: The difficulty mode for the session.
    ///   - resumingFromElapsed: Seconds already accumulated for this run, when
    ///     resuming a saved game. Defaults to `0` (fresh game).
    func startGameSession(difficulty: DifficultyMode, resumingFromElapsed elapsed: TimeInterval = 0) {
        resetGameTimer(resumingFromElapsed: elapsed)
        // Any other session initialization logic
    }
    
    /// Ends the current game session
    func endGameSession() {
        stopGameTimer()
        // Any cleanup logic
    }
    
    // MARK: - Data Management
    
    /// Clears all game history from Core Data
    func clearGameHistory() throws {
        try coreDataManager.deleteAllGameRecords()
        BuildConfiguration.log("Game history cleared", level: .debug)
    }

    /// Resets all game data including history and preferences
    func resetAllData() throws {
        try clearGameHistory()

        // Clear any UserDefaults if we add user preferences later
        // For now, high scores are stored in Core Data, so they're already cleared
        BuildConfiguration.log("All game data reset", level: .debug)
    }
    
}