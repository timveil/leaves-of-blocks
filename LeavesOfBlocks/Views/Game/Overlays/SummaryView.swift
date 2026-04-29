import SwiftUI

// MARK: - Game Summary View

struct SummaryView: View {
    var gameState: GameState
    let historicalSession: GameSession?

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

                    LazyVGrid(columns: gridColumns, spacing: GameTheme.Layout.mediumPadding) {
                        SummaryStatTile(
                            title: "time_played".localized,
                            value: gameTime.formattedAsClock
                        )
                        SummaryStatTile(
                            title: "blocks_placed".localized,
                            value: blocksPlaced.abbreviatedScore
                        )
                        SummaryStatTile(
                            title: "lines_cleared".localized,
                            value: linesCleared.abbreviatedScore
                        )
                        SummaryStatTile(
                            title: "longest_combo".localized,
                            value: longestCombo.abbreviatedScore
                        )

                        if let effGrade = efficiencyGrade {
                            SummaryStatTile(
                                title: "efficiency".localized,
                                value: effGrade.localizedGrade
                            )
                        }

                        if let stratGrade = strategicGrade {
                            SummaryStatTile(
                                title: "strategy".localized,
                                value: stratGrade.localizedGrade
                            )
                        }

                        SummaryDifficultyTile(difficulty: difficulty)
                        SummaryStatTile(
                            title: "best_ever".localized,
                            value: gameState.highScore.abbreviatedScore
                        )
                    }
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Compact Stat Tile

/// Compact two-column variant of `GoldHeaderCard` used in the summary grid.
/// Same visual language (gold header, white content, folk-art border) but with
/// reduced fonts and padding so two tiles fit comfortably side-by-side.
private struct CompactGoldHeaderCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(GameTheme.Typography.headline)
                .foregroundColor(GameTheme.Colors.buttonText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, GameTheme.Layout.smallPadding)
                .padding(.vertical, GameTheme.Layout.smallPadding)
                .background(GameTheme.Colors.accent)
                .overlay(
                    Rectangle()
                        .frame(height: GameTheme.Layout.dividerHeight)
                        .foregroundColor(.black),
                    alignment: .bottom
                )

            content()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, GameTheme.Layout.smallPadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(Color.white)
        }
        .folkArtCard()
    }
}

private struct SummaryStatTile: View {
    let title: String
    let value: String

    var body: some View {
        CompactGoldHeaderCard(title: title) {
            Text(value)
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

private struct SummaryDifficultyTile: View {
    let difficulty: DifficultyMode

    var body: some View {
        CompactGoldHeaderCard(title: "difficulty".localized) {
            AcornCountView(count: difficulty.acornCount, height: 24, spacing: 4)
        }
    }
}

#Preview {
    SummaryView(
        gameState: GameState(),
        historicalSession: nil
    )
}
