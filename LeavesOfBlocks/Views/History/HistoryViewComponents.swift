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
                    .font(GameTheme.Typography.body)
                    .foregroundColor(GameTheme.Colors.buttonText)
                
                Text("statistics".localized)
                    .font(GameTheme.Typography.headline)
                    .foregroundColor(GameTheme.Colors.buttonText)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .background(GameTheme.Colors.accent)
            
            // Stats Grid
            VStack(spacing: 0) {
                // Top row
                HStack(spacing: 0) {
                    StatItemView(
                        icon: "crown.fill",
                        title: "high_score".localized,
                        value: highScore.formattedScore,
                        color: GameTheme.Colors.accent,
                        alignment: .center
                    )
                    
                    Divider()
                        .frame(height: 60)
                        .overlay(GameTheme.Colors.gridBorder.opacity(0.3))
                    
                    StatItemView(
                        icon: "gamecontroller.fill",
                        title: "games_played".localized,
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
                        title: "average_score".localized,
                        value: averageScore.formattedScore,
                        color: GameTheme.Colors.blockGreen,
                        alignment: .center
                    )
                    
                    Divider()
                        .frame(height: 60)
                        .overlay(GameTheme.Colors.gridBorder.opacity(0.3))
                    
                    StatItemView(
                        icon: "square.stack.3d.up.fill",
                        title: "total_blocks".localized,
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
                    GameTheme.Gradients.cardBorder,
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
                    .font(GameTheme.Typography.body)
                    .foregroundColor(color)
                
                Text(value)
                    .font(GameTheme.Typography.headline)
                    .foregroundColor(GameTheme.Colors.primaryText)
            }
            
            Text(title)
                .font(GameTheme.Typography.caption)
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
                        .font(GameTheme.Typography.body)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    
                    Text(session.formattedGameTime)
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        if isHighScore {
                            Image(systemName: "crown.fill")
                                .foregroundColor(GameTheme.Colors.accent)
                                .font(GameTheme.Typography.caption)
                        }
                        Text(session.score.formattedScore)
                            .font(GameTheme.Typography.title)
                            .foregroundColor(GameTheme.Colors.primaryText)
                    }
                    
                    Text("score".localizedUppercase)
                        .font(GameTheme.Typography.tiny)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
            
            // Stats row - more compact
            HStack {
                HStack(spacing: GameTheme.Layout.mediumSpacing) {
                    GameStatChip(title: "blocks".localized, value: session.blocksPlaced.formattedScore, icon: "cube.fill", color: GameTheme.Colors.blockBlue, style: .compact)
                        .fixedSize(horizontal: true, vertical: false)
                    GameStatChip(title: "lines".localized, value: session.linesCleared.formattedScore, icon: "square.grid.3x3.fill", color: GameTheme.Colors.blockGreen, style: .compact)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                Spacer()
                
                // Difficulty badge using new badge style
                Text(session.difficulty.rawValue.uppercased())
                    .font(GameTheme.Typography.tiny)
                    .foregroundColor(GameTheme.Colors.primaryBackground)
                    .gameBadgeStyle(
                        backgroundColor: session.difficulty.color,
                        borderColor: session.difficulty.color,
                        borderWidth: 0
                    )
            }
            
            // Efficiency metrics row (if available)
            if let efficiencyGrade = session.efficiencyGrade,
               let strategicGrade = session.strategicGrade {
                Divider()
                    .overlay(GameTheme.Colors.gridBorder.opacity(0.2))
                    .padding(.vertical, GameTheme.Layout.smallSpacing)
                
                HStack {
                    HStack(spacing: GameTheme.Layout.mediumSpacing) {
                        GameStatChip(
                            title: "efficiency".localized,
                            value: efficiencyGrade,
                            icon: "speedometer",
                            color: gradeColor(for: efficiencyGrade),
                            style: .compact
                        )
                        .fixedSize(horizontal: true, vertical: false)
                        
                        GameStatChip(
                            title: "strategy".localized,
                            value: strategicGrade,
                            icon: "brain.head.profile",
                            color: strategicGradeColor(for: strategicGrade),
                            style: .compact
                        )
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Spacer()
                    
                    // Fallback count if available
                    if let fallbacks = session.fallbackActivations, fallbacks > 0 {
                        Text("fallbacks".localized(with: fallbacks))
                            .font(GameTheme.Typography.tiny)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .gameBadgeStyle(
                                backgroundColor: GameTheme.Colors.blockBackground.opacity(0.3),
                                borderColor: GameTheme.Colors.gridBorder.opacity(0.3),
                                borderWidth: 1
                            )
                    }
                }
            }
        }
        .padding(GameTheme.Layout.mediumPadding)
        .gameContainerStyle(
            backgroundColor: GameTheme.Colors.blockBackground.opacity(0.8),
            cornerRadius: GameTheme.Layout.mediumRadius,
            borderColor: isHighScore ? GameTheme.Colors.accent.opacity(0.5) : GameTheme.Colors.gridBorder.opacity(0.3),
            borderWidth: isHighScore ? 2 : 1
        )
        .accessibilityIdentifier("game_session_row")
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

// Note: StatChip has been replaced by the unified GameStatChip component 
// in Views/Components/Displays/StatisticalDisplays.swift
