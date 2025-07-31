import SwiftUI

// MARK: - Game History Components

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
            HStack(spacing: GameTheme.Layout.smallSpacing) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(GameTheme.Colors.buttonText)
                
                Text("Statistics")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(GameTheme.Colors.buttonText)
            }
            .frame(maxWidth: .infinity)
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
                        value: highScore.formattedScore,
                        color: GameTheme.Colors.accent,
                        alignment: .center
                    )
                    
                    Divider()
                        .frame(height: 60)
                        .overlay(GameTheme.Colors.gridBorder.opacity(0.3))
                    
                    StatItemView(
                        icon: "gamecontroller.fill",
                        title: "Games Played",
                        value: totalGames.formattedScore,
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
                        value: averageScore.formattedScore,
                        color: GameTheme.Colors.blockGreen,
                        alignment: .center
                    )
                    
                    Divider()
                        .frame(height: 60)
                        .overlay(GameTheme.Colors.gridBorder.opacity(0.3))
                    
                    StatItemView(
                        icon: "square.stack.3d.up.fill",
                        title: "Total Blocks",
                        value: totalBlocksPlaced.formattedScore,
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

private struct StatItemView: View {
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
                        Text(session.score.formattedScore)
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
                    GameStatChip(title: "Blocks", value: session.blocksPlaced.formattedScore, icon: "cube.fill", color: GameTheme.Colors.blockBlue, style: .compact)
                        .fixedSize(horizontal: true, vertical: false)
                    GameStatChip(title: "Lines", value: session.linesCleared.formattedScore, icon: "square.grid.3x3.fill", color: GameTheme.Colors.blockGreen, style: .compact)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                Spacer()
                
                // Difficulty badge using new badge style
                Text(session.difficulty.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(GameTheme.Colors.primaryBackground)
                    .gameBadgeStyle(
                        backgroundColor: session.difficulty.color,
                        borderColor: session.difficulty.color,
                        borderWidth: 0
                    )
            }
        }
        .padding(GameTheme.Layout.mediumPadding)
        .gameContainerStyle(
            backgroundColor: GameTheme.Colors.blockBackground.opacity(0.8),
            cornerRadius: GameTheme.Layout.mediumRadius,
            borderColor: isHighScore ? GameTheme.Colors.accent.opacity(0.5) : GameTheme.Colors.gridBorder.opacity(0.3),
            borderWidth: isHighScore ? 2 : 1
        )
    }
}

// Note: StatChip has been replaced by the unified GameStatChip component 
// in Views/Components/Displays/StatisticalDisplays.swift