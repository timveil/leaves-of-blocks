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
                gameTime: gameState.gameTime
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
                    .foregroundStyle(GameTheme.Gradients.text)
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

struct StatsSummaryView: View {
    let gameHistory: [GameSession]
    let highScore: Int
    
    private var totalGames: Int {
        gameHistory.count
    }
    
    private var totalScore: Int {
        gameHistory.reduce(0) { $0 + $1.score }
    }
    
    private var averageScore: Int {
        guard totalGames > 0 else { return 0 }
        return totalScore / totalGames
    }
    
    private var totalBlocksPlaced: Int {
        gameHistory.reduce(0) { $0 + $1.blocksPlaced }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient background
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(GameTheme.Colors.buttonText)
                
                Text("Statistics")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(GameTheme.Colors.buttonText)
                
                Spacer()
            }
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .background(
                LinearGradient(
                    colors: [GameTheme.Colors.accent, GameTheme.Colors.accent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Stats Grid
            VStack(spacing: 0) {
                // Top row
                HStack(spacing: 0) {
                    StatItemView(
                        icon: "crown.fill",
                        title: "High Score",
                        value: "\(highScore)",
                        color: GameTheme.Colors.accent,
                        alignment: .center
                    )
                    
                    Divider()
                        .frame(height: 60)
                        .overlay(GameTheme.Colors.gridBorder.opacity(0.3))
                    
                    StatItemView(
                        icon: "gamecontroller.fill",
                        title: "Games Played",
                        value: "\(totalGames)",
                        color: GameTheme.Colors.blockBlue,
                        alignment: .center
                    )
                }
                
                Divider()
                    .overlay(GameTheme.Colors.gridBorder.opacity(0.3))
                
                // Bottom row
                HStack(spacing: 0) {
                    StatItemView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Average Score",
                        value: "\(averageScore)",
                        color: GameTheme.Colors.blockGreen,
                        alignment: .center
                    )
                    
                    Divider()
                        .frame(height: 60)
                        .overlay(GameTheme.Colors.gridBorder.opacity(0.3))
                    
                    StatItemView(
                        icon: "square.stack.3d.up.fill",
                        title: "Total Blocks",
                        value: "\(totalBlocksPlaced)",
                        color: GameTheme.Colors.blockOrange,
                        alignment: .center
                    )
                }
            }
            .background(GameTheme.Colors.cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [GameTheme.Colors.accent.opacity(0.3), GameTheme.Colors.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: GameTheme.Colors.cardShadow.opacity(0.15),
            radius: 12,
            x: 0,
            y: 6
        )
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
    }
}

struct StatItemView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let alignment: HorizontalAlignment
    
    var body: some View {
        VStack(alignment: alignment, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(GameTheme.Colors.primaryText)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GameTheme.Layout.largePadding)
    }
}

struct GameSessionRow: View {
    let session: GameSession
    let isHighScore: Bool
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.smallSpacing) {
            // Header row - Date and Score
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.formattedDate)
                        .font(GameTheme.Typography.bodyFont)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    
                    Text(session.formattedGameTime)
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        if isHighScore {
                            Image(systemName: "crown.fill")
                                .foregroundColor(GameTheme.Colors.accent)
                                .font(.system(size: 12))
                        }
                        Text("\(session.score)")
                            .font(GameTheme.Typography.scoreFont)
                            .foregroundColor(GameTheme.Colors.primaryText)
                    }
                    
                    Text("SCORE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
            
            // Stats row - more compact
            HStack {
                HStack(spacing: GameTheme.Layout.mediumSpacing) {
                    StatChip(label: "Blocks", value: "\(session.blocksPlaced)", color: GameTheme.Colors.blockBlue)
                    StatChip(label: "Lines", value: "\(session.linesCleared)", color: GameTheme.Colors.blockGreen)
                }
                
                Spacer()
                
                // Difficulty badge
                Text(session.difficulty.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(GameTheme.Colors.primaryBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(session.difficulty.color)
                    )
            }
        }
        .padding(GameTheme.Layout.mediumPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.mediumRadius)
                .fill(GameTheme.Colors.blockBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.mediumRadius)
                        .stroke(
                            isHighScore ? GameTheme.Colors.accent.opacity(0.5) : GameTheme.Colors.gridBorder.opacity(0.3),
                            lineWidth: isHighScore ? 2 : 1
                        )
                )
        )
    }
}

struct StatChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(GameTheme.Colors.secondaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    GameHistoryView(
        gameState: GameState(),
        onSelectSession: { _ in }
    )
}
