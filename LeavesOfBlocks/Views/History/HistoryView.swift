import SwiftUI

struct HistoryView: View {
    @ObservedObject var gameState: GameState
    let onSelectSession: (GameSession) -> Void
    @State private var gameHistory: [GameSession] = []
    @State private var statistics = GameStatistics(totalGames: 0, totalScore: 0, averageScore: 0, totalBlocksPlaced: 0, highScore: 0)
    
    private func loadGameHistory() {
        let records = CoreDataManager.shared.fetchGameHistory()
        
        var sessions: [GameSession] = []
        
        // Add current session if there's a score and game is not over
        if gameState.score > 0 && !gameState.isGameOver {
            sessions.append(GameSession(
                date: Date(),
                score: gameState.score,
                blocksPlaced: gameState.blocksPlaced,
                linesCleared: gameState.linesCleared,
                difficulty: gameState.currentDifficulty,
                gameTime: gameState.currentGameTime
            ))
        }
        
        // Add Core Data records
        for record in records {
            if let date = record.date,
               let difficultyString = record.difficulty,
               let difficulty = DifficultyMode(rawValue: difficultyString) {
                sessions.append(GameSession(
                    date: date,
                    score: Int(record.score),
                    blocksPlaced: Int(record.blocksPlaced),
                    linesCleared: Int(record.linesCleared),
                    difficulty: difficulty,
                    gameTime: record.gameTime
                ))
            }
        }
        
        gameHistory = sessions.sorted { $0.date > $1.date }
        statistics = CoreDataManager.shared.calculateStatistics()
    }
    
    var body: some View {
        BaseScreenView {
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                // Header
                Text("game_history".localized)
                    .pageTitleStyle()
                    .padding(.top, GameTheme.Layout.mediumPadding)
                
                // Statistics Summary
                StatsSummaryView(gameHistory: gameHistory, highScore: statistics.highScore)
                
                // History List
                ScrollView {
                    LazyVStack(spacing: GameTheme.Layout.mediumSpacing) {
                        ForEach(gameHistory.indices, id: \.self) { index in
                            Button(action: {
                                onSelectSession(gameHistory[index])
                            }) {
                                GameSessionRow(
                                    session: gameHistory[index],
                                    isHighScore: gameHistory[index].score == statistics.highScore
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, GameTheme.Layout.largePadding)
                    .padding(.bottom, GameTheme.Layout.extraLargePadding)
                }
                .padding(.bottom, 80) // Add bottom padding to prevent covering grass
            }
        }
        .onAppear {
            loadGameHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)) { _ in
            loadGameHistory()
        }
    }
}

/// Represents a completed game session with all relevant statistics.
///
/// `GameSession` captures the key metrics from a finished game, providing
/// a comprehensive snapshot for historical analysis and display.
///
/// ## Usage
/// Used in game history displays, high score tracking, and session comparisons.
/// Created automatically when games end or loaded from Core Data persistence.
struct GameSession: Equatable {
    /// When the game session was completed
    let date: Date
    /// Final score achieved in the session
    let score: Int
    /// Total number of blocks successfully placed
    let blocksPlaced: Int
    /// Total number of lines cleared during the session
    let linesCleared: Int
    /// Difficulty level used for the session
    let difficulty: DifficultyMode
    /// Total time spent playing the session
    let gameTime: TimeInterval
    
    /// Formats the game time as MM:SS for display.
    ///
    /// - Returns: A string in "M:SS" or "MM:SS" format (e.g., "3:45", "12:30")
    var formattedGameTime: String {
        let minutes = Int(gameTime) / 60
        let seconds = Int(gameTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formats the session date for user-friendly display.
    ///
    /// Uses medium date style and short time style for optimal readability
    /// while conserving display space in history lists.
    ///
    /// - Returns: A formatted date string (e.g., "Jan 15, 2025 at 3:30 PM")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var hasLoadedData = false
        
        var body: some View {
            HistoryView(
                gameState: GameState(),
                onSelectSession: { _ in }
            )
            .onAppear {
                guard !hasLoadedData else { return }
                hasLoadedData = true
                
                // Add mock data to CoreData for preview
                let sessions = [
                    (score: 2450, blocks: 45, lines: 12, difficulty: DifficultyMode.hard, combo: 3, time: 180.0, daysAgo: 0),
                    (score: 1890, blocks: 38, lines: 8, difficulty: DifficultyMode.moderate, combo: 2, time: 150.0, daysAgo: 1),
                    (score: 3200, blocks: 52, lines: 15, difficulty: DifficultyMode.hard, combo: 4, time: 220.0, daysAgo: 2),
                    (score: 1240, blocks: 28, lines: 6, difficulty: DifficultyMode.easy, combo: 1, time: 120.0, daysAgo: 3),
                    (score: 2780, blocks: 41, lines: 11, difficulty: DifficultyMode.moderate, combo: 3, time: 165.0, daysAgo: 5)
                ]
                
                for session in sessions {
                    CoreDataManager.shared.saveGameRecord(
                        score: session.score,
                        difficulty: session.difficulty,
                        blocksPlaced: session.blocks,
                        linesCleared: session.lines,
                        longestCombo: session.combo,
                        gameTime: session.time
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}
