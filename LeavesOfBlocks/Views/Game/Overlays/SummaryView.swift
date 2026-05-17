import SwiftUI

// MARK: - Game Summary View

struct SummaryView: View {
    var gameState: GameState
    let historicalSession: GameSession?
    var gameCenterService: GameCenterService = .shared

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
        if historicalSession != nil { return false }
        return gameState.isNewHighScore
    }

    private var longestCombo: Int {
        historicalSession != nil ? 0 : gameState.longestCombo
    }

    private var efficiencyGrade: String? {
        historicalSession?.efficiencyGrade ?? gameState.statistics.efficiencyGrade
    }

    private var strategicGrade: String? {
        historicalSession?.strategicGrade ?? gameState.statistics.strategicGrade
    }

    private var fallbackActivations: Int? {
        historicalSession?.fallbackActivations ?? gameState.statistics.fallbackActivations
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: GameTheme.Layout.mediumPadding),
        GridItem(.flexible(), spacing: GameTheme.Layout.mediumPadding)
    ]

    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            ScrollView {
                VStack(spacing: GameTheme.Layout.mediumPadding) {
                    ScoreDisplayView(
                        title: "final_score".localized,
                        score: score,
                        subtitle: historicalSession?.formattedDate,
                        showIcon: isNewHighScore,
                        iconName: "crown.fill"
                    )
                    .accessibilityIdentifier("summary_screen")

                    LazyVGrid(columns: gridColumns, spacing: GameTheme.Layout.mediumPadding) {
                        CompactStatCard(
                            title: "time_played".localized,
                            value: gameTime.formattedAsClock
                        )
                        CompactStatCard(
                            title: "blocks_placed".localized,
                            value: blocksPlaced.abbreviatedScore
                        )
                        CompactStatCard(
                            title: "lines_cleared".localized,
                            value: linesCleared.abbreviatedScore
                        )
                        CompactStatCard(
                            title: "longest_combo".localized,
                            value: longestCombo.abbreviatedScore
                        )

                        if let effGrade = efficiencyGrade {
                            CompactStatCard(
                                title: "efficiency".localized,
                                value: effGrade.localizedGrade
                            )
                        }

                        if let stratGrade = strategicGrade {
                            CompactStatCard(
                                title: "strategy".localized,
                                value: stratGrade.localizedGrade
                            )
                        }

                        SummaryDifficultyTile(difficulty: difficulty)
                        CompactStatCard(
                            title: "best_ever".localized,
                            value: gameState.highScore.abbreviatedScore
                        )
                    }

                    if gameCenterService.isAuthenticated {
                        FullWidthActionButton(
                            title: "view_leaderboard".localized,
                            style: .success,
                            accessibilityId: "view_leaderboard_button"
                        ) {
                            gameCenterService.presentDashboard(leaderboardID: GameCenterIDs.Leaderboards.allTimeHigh)
                        }
                        .padding(.top, GameTheme.Layout.mediumPadding)
                    }
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Difficulty Tile

private struct SummaryDifficultyTile: View {
    let difficulty: DifficultyMode

    var body: some View {
        CompactGoldHeaderCard(title: "difficulty".localized) {
            AcornCountView(count: difficulty.acornCount, height: 44, spacing: 6)
        }
    }
}

#Preview("Empty") {
    SummaryView(
        gameState: GameState(),
        historicalSession: nil
    )
}

#Preview("Historical") {
    SummaryView(
        gameState: GameState(),
        historicalSession: GameSession(
            date: Date().addingTimeInterval(-3_600),
            score: 8_750,
            blocksPlaced: 42,
            linesCleared: 12,
            difficulty: .moderate,
            gameTime: 215,
            averageGridEfficiency: 0.72,
            averageFragmentation: 0.34,
            strategicPlayRating: 0.65,
            challengeMaintained: 0.58,
            fallbackActivations: 1,
            efficiencyGrade: "A-",
            strategicGrade: "B+",
            tierUsageDistribution: "diverse:14,constrained:18,minimal:6"
        )
    )
}
