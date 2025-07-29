import SwiftUI

// MARK: - Game Summary View

struct SummaryView: View {
    @ObservedObject var gameState: GameState
    let historicalSession: GameSession?
    @State private var highScoreScale: CGFloat = 1.0
    
    // Computed properties to use either current game or historical session
    private var score: Int {
        historicalSession?.score ?? gameState.score
    }
    
    private var blocksPlaced: Int {
        historicalSession?.blocksPlaced ?? gameState.blocksPlaced
    }
    
    private var linesCleared: Int {
        historicalSession?.linesCleared ?? gameState.linesCleared
    }
    
    private var gameTime: TimeInterval {
        historicalSession?.gameTime ?? gameState.currentGameTime
    }
    
    private var difficulty: DifficultyMode {
        historicalSession?.difficulty ?? gameState.currentDifficulty
    }
    
    private var isNewHighScore: Bool {
        if historicalSession != nil {
            return false // Historical sessions don't show new high score
        }
        return gameState.isNewHighScore
    }
    
    private var longestCombo: Int {
        // For historical sessions, we don't have combo data, so use 0
        historicalSession != nil ? 0 : gameState.longestCombo
    }
    
    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            GeometryReader { geometry in
                
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: GameTheme.Layout.largeSpacing) {
                        if isNewHighScore {
                            Text("🏆 NEW HIGH SCORE! 🏆")
                                .font(GameTheme.Typography.titleFont)
                                .foregroundColor(GameTheme.Colors.accent)
                                .tracking(1.5)
                                .scaleEffect(highScoreScale)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                        highScoreScale = 1.1
                                    }
                                }
                                .onDisappear {
                                    highScoreScale = 1.0
                                }
                        }
                        
                        VStack(spacing: GameTheme.Layout.mediumSpacing) {
                            Text(historicalSession != nil ? "Past Game Summary" : "Game Summary")
                                .font(GameTheme.Typography.title)
                                .foregroundColor(GameTheme.Colors.primaryText)
                                .tracking(1)
                            
                            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                                // Show date for historical sessions
                                if let session = historicalSession {
                                    Text(session.formattedDate)
                                        .font(GameTheme.Typography.captionFont)
                                        .foregroundColor(GameTheme.Colors.secondaryText)
                                }
                            }
                        }
                    }
                    .padding(.top, GameTheme.Layout.mediumPadding)
                    
                    Spacer(minLength: GameTheme.Layout.extraLargeSpacing)
                    
                    // Final Score - centered and prominent
                    VStack(spacing: GameTheme.Layout.smallSpacing) {
                        Text("Final Score")
                            .font(GameTheme.Typography.headlineFont)
                            .foregroundColor(GameTheme.Colors.accent)
                            .tracking(1)
                        
                        Text("\(score)")
                            .font(GameTheme.Typography.largeScore)
                            .foregroundColor(GameTheme.Colors.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    Spacer(minLength: GameTheme.Layout.extraLargeSpacing)
                    
                    // Statistics Cards - 2x3 grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: GameTheme.Layout.mediumSpacing) {
                        
                        StatisticCard(
                            title: "Time Played",
                            value: formatTime(gameTime),
                            icon: "clock.fill",
                            color: GameTheme.Colors.blockBlue
                        )
                        
                        StatisticCard(
                            title: "Blocks Placed",
                            value: "\(blocksPlaced)",
                            icon: "square.grid.3x3.fill",
                            color: GameTheme.Colors.blockGreen
                        )
                        
                        StatisticCard(
                            title: "Lines Cleared",
                            value: "\(linesCleared)",
                            icon: "line.horizontal.3",
                            color: GameTheme.Colors.blockRed
                        )
                        
                        StatisticCard(
                            title: "Longest Combo",
                            value: "\(longestCombo)",
                            icon: "flame.fill",
                            color: GameTheme.Colors.blockOrange
                        )
                        
                        StatisticCard(
                            title: "Difficulty",
                            value: difficulty.rawValue.capitalized,
                            icon: "target",
                            color: difficulty.color
                        )
                        
                        StatisticCard(
                            title: "Best Ever",
                            value: "\(gameState.highScore)",
                            icon: "crown.fill",
                            color: GameTheme.Colors.accent
                        )
                    }
                    .padding(.horizontal, GameTheme.Layout.largePadding)
                    
                    Spacer(minLength: GameTheme.Layout.extraLargeSpacing)
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Statistic Card Component

private struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.smallSpacing) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(GameTheme.Typography.titleFont)
                .foregroundColor(GameTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(GameTheme.Typography.captionFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(GameTheme.Layout.mediumPadding)
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: GameTheme.Colors.cardShadow, radius: 6, x: 0, y: 3)
    }
}

#Preview {
    SummaryView(
        gameState: GameState(),
        historicalSession: nil
    )
}
