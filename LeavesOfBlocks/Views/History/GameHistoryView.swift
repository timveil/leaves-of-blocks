import SwiftUI

struct GameHistoryView: View {
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
        ZStack {
            // Background
            GameBackgroundView()
            
            // Grass at bottom (lowest z-index)
            VStack {
                Spacer()
                BlockGrassView()
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .zIndex(0)
            
            // Content layer
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                // Header
                Text("Game History")
                    .font(GameTheme.Typography.title)
                    .foregroundColor(GameTheme.Colors.primaryText)
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
            }
            .zIndex(1)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            loadGameHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)) { _ in
            loadGameHistory()
        }
    }
}

struct GameSession: Equatable {
    let date: Date
    let score: Int
    let blocksPlaced: Int
    let linesCleared: Int
    let difficulty: DifficultyMode
    let gameTime: TimeInterval
    
    var formattedGameTime: String {
        let minutes = Int(gameTime) / 60
        let seconds = Int(gameTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    GameHistoryView(
        gameState: GameState(),
        onSelectSession: { _ in }
    )
}
