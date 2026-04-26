import SwiftUI

// MARK: - Game Summary View

struct SummaryView: View {
    @ObservedObject var gameState: GameState
    let historicalSession: GameSession?
    
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
    
    // Efficiency metrics
    private var efficiencyGrade: String? {
        historicalSession?.efficiencyGrade ?? gameState.statistics.efficiencyGrade
    }
    
    private var strategicGrade: String? {
        historicalSession?.strategicGrade ?? gameState.statistics.strategicGrade
    }
    
    private var fallbackActivations: Int? {
        historicalSession?.fallbackActivations ?? gameState.statistics.fallbackActivations
    }
    
    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            GeometryReader { geometry in
                
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text(historicalSession != nil ? "past_game_summary".localized : "game_summary".localized)
                            .font(GameTheme.Typography.title)
                            .foregroundColor(GameTheme.Colors.primaryText)
                            .tracking(1)
                        
                        VStack(spacing: GameTheme.Layout.mediumSpacing) {
                            // Show date for historical sessions
                            if let session = historicalSession {
                                Text(session.formattedDate)
                                    .font(GameTheme.Typography.caption)
                                    .foregroundColor(GameTheme.Colors.secondaryText)
                            }
                        }
                    }
                    .padding(.top, GameTheme.Layout.mediumPadding)
                    
                    Spacer().frame(maxHeight: 20)
                    
                    // Final Score - centered and prominent
                    ScoreDisplayView(
                        title: "final_score".localized,
                        score: score,
                        showIcon: isNewHighScore,
                        iconName: "crown.fill"
                    ).frame(maxWidth: 280)
                    
                    Spacer().frame(maxHeight: 20)
                    
                    // Statistics Cards - 2x4 grid to accommodate efficiency metrics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: GameTheme.Layout.largeSpacing) {
                        
                        StatisticCard(
                            title: "time_played".localized,
                            value: formatTime(gameTime),
                            icon: "clock.fill",
                            color: GameTheme.Colors.blockBlue,
                            isCondensed: true
                        )
                        
                        StatisticCard(
                            title: "blocks_placed".localized,
                            value: blocksPlaced.formattedScore,
                            icon: "square.grid.3x3.fill",
                            color: GameTheme.Colors.blockGreen,
                            isCondensed: true
                        )
                        
                        StatisticCard(
                            title: "lines_cleared".localized,
                            value: linesCleared.formattedScore,
                            icon: "line.horizontal.3",
                            color: GameTheme.Colors.blockRed,
                            isCondensed: true
                        )
                        
                        StatisticCard(
                            title: "longest_combo".localized,
                            value: longestCombo.formattedScore,
                            icon: "flame.fill",
                            color: GameTheme.Colors.blockOrange,
                            isCondensed: true
                        )
                        
                        // Efficiency Grade (if available)
                        if let effGrade = efficiencyGrade {
                            StatisticCard(
                                title: "efficiency".localized,
                                value: effGrade,
                                icon: "speedometer",
                                color: gradeColor(for: effGrade),
                                isCondensed: true
                            )
                        } else {
                            StatisticCard(
                                title: "difficulty".localized,
                                value: difficulty.displayName,
                                icon: "target",
                                color: difficulty.color,
                                isCondensed: true
                            )
                        }
                        
                        // Strategic Grade (if available)
                        if let stratGrade = strategicGrade {
                            StatisticCard(
                                title: "strategy".localized,
                                value: stratGrade,
                                icon: "brain.head.profile",
                                color: strategicGradeColor(for: stratGrade),
                                isCondensed: true
                            )
                        } else {
                            StatisticCard(
                                title: "best_ever".localized,
                                value: gameState.highScore.formattedScore,
                                icon: "crown.fill",
                                color: GameTheme.Colors.accent,
                                isCondensed: true
                            )
                        }
                        
                        // Show difficulty and best ever if efficiency metrics aren't available
                        if efficiencyGrade != nil && strategicGrade != nil {
                            StatisticCard(
                                title: "difficulty".localized,
                                value: difficulty.displayName,
                                icon: "target",
                                color: difficulty.color,
                                isCondensed: true
                            )
                            
                            StatisticCard(
                                title: "best_ever".localized,
                                value: gameState.highScore.formattedScore,
                                icon: "crown.fill",
                                color: GameTheme.Colors.accent,
                                isCondensed: true
                            )
                        }
                    }
                    .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                    
                    
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
    
    // MARK: - Helper Functions
    
    /// Returns color based on efficiency grade
    private func gradeColor(for grade: String) -> Color {
        switch grade {
        case "A+", "A":
            return GameTheme.Colors.blockGreen
        case "B+", "B":
            return GameTheme.Colors.blockBlue
        case "C+", "C":
            return GameTheme.Colors.blockOrange
        default:
            return GameTheme.Colors.blockRed
        }
    }
    
    /// Returns color based on strategic grade
    private func strategicGradeColor(for grade: String) -> Color {
        switch grade {
        case "Master":
            return GameTheme.Colors.blockPurple
        case "Expert":
            return GameTheme.Colors.blockGreen
        case "Skilled":
            return GameTheme.Colors.blockBlue
        case "Learning":
            return GameTheme.Colors.blockOrange
        default:
            return GameTheme.Colors.blockRed
        }
    }
}

// MARK: - Statistic Card Component

private struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isCondensed: Bool = false
    
    var body: some View {
        VStack(spacing: isCondensed ? GameTheme.Layout.tinySpacing : GameTheme.Layout.smallSpacing) {
            Image(systemName: icon)
                .font(isCondensed ? GameTheme.Typography.body : GameTheme.Typography.headline)
                .foregroundColor(color)
            
            Text(value)
                .font(isCondensed ? GameTheme.Typography.headline : GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(GameTheme.Typography.caption)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(isCondensed ? 1 : 2)
        }
        .padding(isCondensed ? GameTheme.Layout.mediumPadding : GameTheme.Layout.largePadding)
        .frame(maxWidth: .infinity, minHeight: isCondensed ? 80 : 110, maxHeight: isCondensed ? 80 : 110)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: GameTheme.Colors.cardShadow, radius: isCondensed ? 4 : 6, x: 0, y: isCondensed ? 2 : 3)
    }
}

#Preview {
    SummaryView(
        gameState: GameState(),
        historicalSession: nil
    )
}
