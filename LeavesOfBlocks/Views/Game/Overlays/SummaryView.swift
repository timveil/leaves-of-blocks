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

    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            ScrollView {
                VStack(spacing: GameTheme.Layout.mediumPadding) {
                    ScoreDisplayView(
                        title: "final_score".localized,
                        score: score,
                        showIcon: isNewHighScore,
                        iconName: "crown.fill"
                    )

                    if let session = historicalSession {
                        Text(session.formattedDate)
                            .font(GameTheme.Typography.caption)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                    }

                    // Stat cards
                    SummaryStatCard(
                        title: "time_played".localized,
                        value: formatTime(gameTime)
                    )
                    SummaryStatCard(
                        title: "blocks_placed".localized,
                        value: blocksPlaced.abbreviatedScore
                    )
                    SummaryStatCard(
                        title: "lines_cleared".localized,
                        value: linesCleared.abbreviatedScore
                    )
                    SummaryStatCard(
                        title: "longest_combo".localized,
                        value: longestCombo.abbreviatedScore
                    )

                    if let effGrade = efficiencyGrade {
                        SummaryStatCard(
                            title: "efficiency".localized,
                            value: effGrade
                        )
                    }

                    if let stratGrade = strategicGrade {
                        SummaryStatCard(
                            title: "strategy".localized,
                            value: stratGrade
                        )
                    }

                    SummaryDifficultyCard(difficulty: difficulty)
                    SummaryStatCard(
                        title: "best_ever".localized,
                        value: gameState.highScore.abbreviatedScore
                    )
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .mask(
                VStack(spacing: 0) {
                    Color.black
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                }
            )
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Summary Difficulty Card

private struct SummaryDifficultyCard: View {
    let difficulty: DifficultyMode

    var body: some View {
        GoldHeaderCard(title: "difficulty".localized) {
            HStack(spacing: 8) {
                ForEach(0..<difficulty.acornCount, id: \.self) { _ in
                    Image("AcornIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 44)
                }
            }
        }
    }
}

// MARK: - Summary Stat Card

private struct SummaryStatCard: View {
    let title: String
    let value: String

    var body: some View {
        GoldHeaderCard(title: title) {
            Text(value)
                .font(GameTheme.Typography.display)
                .foregroundColor(GameTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

#Preview {
    SummaryView(
        gameState: GameState(),
        historicalSession: nil
    )
}
