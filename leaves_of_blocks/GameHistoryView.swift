import SwiftUI

struct GameHistoryView: View {
    @ObservedObject var gameState: GameState
    let onDismiss: () -> Void
    
    // Sample history data - in a real app this would come from persistent storage
    private var gameHistory: [GameSession] {
        // For now, we'll show some sample data along with current session if available
        var sessions: [GameSession] = []
        
        // Add current session if there's a score
        if gameState.score > 0 {
            sessions.append(GameSession(
                date: Date(),
                score: gameState.score,
                blocksPlaced: gameState.blocksPlaced,
                linesCleared: gameState.linesCleared,
                difficulty: gameState.currentDifficulty,
                gameTime: gameState.gameTime
            ))
        }
        
        // Add some sample historical sessions
        let sampleSessions = [
            GameSession(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                score: 2850,
                blocksPlaced: 47,
                linesCleared: 12,
                difficulty: .moderate,
                gameTime: 420
            ),
            GameSession(
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                score: 1920,
                blocksPlaced: 32,
                linesCleared: 8,
                difficulty: .easy,
                gameTime: 280
            ),
            GameSession(
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                score: 4120,
                blocksPlaced: 68,
                linesCleared: 18,
                difficulty: .hard,
                gameTime: 580
            ),
            GameSession(
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                score: 1650,
                blocksPlaced: 28,
                linesCleared: 6,
                difficulty: .moderate,
                gameTime: 210
            )
        ]
        
        sessions.append(contentsOf: sampleSessions)
        return sessions.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            // Background
            GameBackgroundView()
            
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                // Header
                HStack {
                    Text("Game History")
                        .font(GameTheme.Typography.title)
                        .foregroundStyle(GameTheme.Gradients.text)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(GameTheme.Colors.primaryText)
                    }
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.top, GameTheme.Layout.largePadding)
                
                // Statistics Summary
                StatsSummaryView(gameHistory: gameHistory, highScore: gameState.highScoreManager.highScore)
                
                // History List
                ScrollView {
                    LazyVStack(spacing: GameTheme.Layout.mediumSpacing) {
                        ForEach(gameHistory.indices, id: \.self) { index in
                            GameSessionRow(
                                session: gameHistory[index],
                                isHighScore: gameHistory[index].score == gameState.highScoreManager.highScore
                            )
                        }
                    }
                    .padding(.horizontal, GameTheme.Layout.largePadding)
                    .padding(.bottom, GameTheme.Layout.extraLargePadding)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct GameSession {
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
        VStack(spacing: GameTheme.Layout.mediumSpacing) {
            Text("Statistics")
                .font(GameTheme.Typography.headlineFont)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            HStack(spacing: GameTheme.Layout.largeSpacing) {
                StatItemView(title: "High Score", value: "\(highScore)", color: GameTheme.Colors.accent)
                StatItemView(title: "Games Played", value: "\(totalGames)", color: GameTheme.Colors.blockBlue)
                StatItemView(title: "Avg Score", value: "\(averageScore)", color: GameTheme.Colors.blockGreen)
                StatItemView(title: "Total Blocks", value: "\(totalBlocksPlaced)", color: GameTheme.Colors.blockOrange)
            }
        }
        .padding(GameTheme.Layout.largePadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: GameTheme.Colors.cardBorderGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: GameTheme.Colors.cardShadow,
                    radius: GameTheme.Layout.shadowRadius,
                    x: 0,
                    y: GameTheme.Layout.shadowOffset
                )
        )
        .padding(.horizontal, GameTheme.Layout.largePadding)
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.smallSpacing) {
            Text(value)
                .font(GameTheme.Typography.scoreFont)
                .foregroundColor(color)
            
            Text(title)
                .font(GameTheme.Typography.captionFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
}

struct GameSessionRow: View {
    let session: GameSession
    let isHighScore: Bool
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.mediumSpacing) {
            // Date and time
            VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                Text(session.formattedDate)
                    .font(GameTheme.Typography.bodyFont)
                    .foregroundColor(GameTheme.Colors.primaryText)
                
                Text(session.formattedGameTime)
                    .font(GameTheme.Typography.captionFont)
                    .foregroundColor(GameTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            // Game stats
            HStack(spacing: GameTheme.Layout.largeSpacing) {
                VStack {
                    Text("\(session.score)")
                        .font(GameTheme.Typography.scoreFont)
                        .foregroundColor(isHighScore ? GameTheme.Colors.accent : GameTheme.Colors.primaryText)
                    
                    Text("Score")
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                VStack {
                    Text("\(session.blocksPlaced)")
                        .font(GameTheme.Typography.bodyFont)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    
                    Text("Blocks")
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                VStack {
                    Text("\(session.linesCleared)")
                        .font(GameTheme.Typography.bodyFont)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    
                    Text("Lines")
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
            
            // Difficulty badge
            Text(session.difficulty.rawValue)
                .font(GameTheme.Typography.captionFont)
                .foregroundColor(GameTheme.Colors.primaryBackground)
                .padding(.horizontal, GameTheme.Layout.mediumSpacing)
                .padding(.vertical, GameTheme.Layout.smallSpacing)
                .background(
                    Capsule()
                        .fill(session.difficulty.color)
                )
        }
        .padding(GameTheme.Layout.mediumPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.mediumRadius)
                .fill(GameTheme.Colors.blockBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.mediumRadius)
                        .stroke(
                            isHighScore ? GameTheme.Colors.accent.opacity(0.5) : GameTheme.Colors.gridBorder.opacity(0.3),
                            lineWidth: isHighScore ? 2 : 1
                        )
                )
        )
        .overlay(
            // High score crown
            Group {
                if isHighScore {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "crown.fill")
                                .foregroundColor(GameTheme.Colors.accent)
                                .font(.system(size: 16))
                                .offset(x: -8, y: 8)
                        }
                        Spacer()
                    }
                }
            }
        )
    }
}

#Preview {
    GameHistoryView(
        gameState: GameState(),
        onDismiss: {}
    )
}