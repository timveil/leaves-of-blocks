import SwiftUI

// MARK: - History Stat Card

struct HistoryStatCard: View {
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

// MARK: - Game Session Row

struct GameSessionRow: View {
    let session: GameSession
    let isHighScore: Bool

    var body: some View {
        VStack(spacing: GameTheme.Layout.mediumSpacing) {
            AcornCountView(count: session.difficulty.acornCount, height: 40)

            Text(session.score.abbreviatedScore)
                .font(GameTheme.Typography.display)
                .foregroundColor(isHighScore ? GameTheme.Colors.accent : GameTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(session.formattedDate)
                .font(GameTheme.Typography.caption)
                .foregroundColor(GameTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(GameTheme.Layout.mediumPadding)
        .background(Color.white)
        .folkArtCard(borderColor: isHighScore ? GameTheme.Colors.accent : .black)
        .accessibilityIdentifier("game_session_row")
    }
}

#Preview("History Stat Card") {
    HistoryStatCard(title: "high_score".localized, value: "12,450")
        .frame(width: 300)
        .padding()
}

#Preview("Game Session Row") {
    GameSessionRow(
        session: GameSession(
            date: Date(),
            score: 8750,
            blocksPlaced: 42,
            linesCleared: 12,
            difficulty: .moderate,
            gameTime: 185,
            averageGridEfficiency: nil,
            averageFragmentation: nil,
            strategicPlayRating: nil,
            challengeMaintained: nil,
            fallbackActivations: nil,
            efficiencyGrade: nil,
            strategicGrade: nil,
            tierUsageDistribution: nil
        ),
        isHighScore: true
    )
    .frame(width: 300)
    .padding()
}
