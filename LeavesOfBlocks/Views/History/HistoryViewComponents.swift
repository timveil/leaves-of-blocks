import SwiftUI

// MARK: - Game Session Row

struct GameSessionRow: View {
    let session: GameSession
    let isHighScore: Bool

    var body: some View {
        HStack(alignment: .center, spacing: GameTheme.Layout.mediumSpacing) {
            VStack(alignment: .leading, spacing: GameTheme.Layout.smallSpacing) {
                Text(session.score.abbreviatedScore)
                    .font(GameTheme.Typography.title)
                    .foregroundColor(isHighScore ? GameTheme.Colors.accent : GameTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(session.formattedDate)
                    .font(GameTheme.Typography.caption)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: GameTheme.Layout.mediumSpacing)

            AcornCountView(count: session.difficulty.acornCount, height: 28, spacing: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, GameTheme.Layout.mediumPadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(Color.white)
        .folkArtCard(borderColor: isHighScore ? GameTheme.Colors.accent : .black)
        .accessibilityIdentifier("game_session_row")
    }
}

#Preview("Game Session Row") {
    VStack(spacing: 12) {
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
                strategicGrade: nil
            ),
            isHighScore: true
        )
        GameSessionRow(
            session: GameSession(
                date: Date().addingTimeInterval(-86_400),
                score: 1240,
                blocksPlaced: 28,
                linesCleared: 6,
                difficulty: .easy,
                gameTime: 120,
                averageGridEfficiency: nil,
                averageFragmentation: nil,
                strategicPlayRating: nil,
                challengeMaintained: nil,
                fallbackActivations: nil,
                efficiencyGrade: nil,
                strategicGrade: nil
            ),
            isHighScore: false
        )
    }
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}
