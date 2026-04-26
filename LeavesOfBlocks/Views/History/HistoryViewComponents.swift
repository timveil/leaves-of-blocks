import SwiftUI

// MARK: - History Stat Card

struct HistoryStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(GameTheme.Typography.headline)
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(GameTheme.Colors.accent)
                .overlay(
                    Rectangle()
                        .frame(height: 2.5)
                        .foregroundColor(.black),
                    alignment: .bottom
                )

            Text(value)
                .font(GameTheme.Typography.display)
                .foregroundColor(GameTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, GameTheme.Layout.largePadding)
                .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .stroke(Color.black, lineWidth: 2.5)
        )
    }
}

// MARK: - Game Session Row

struct GameSessionRow: View {
    let session: GameSession
    let isHighScore: Bool

    var body: some View {
        VStack(spacing: GameTheme.Layout.mediumSpacing) {
            HStack(spacing: 6) {
                ForEach(0..<session.difficulty.acornCount, id: \.self) { _ in
                    Image("AcornIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)
                }
            }

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
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .stroke(isHighScore ? GameTheme.Colors.accent : Color.black, lineWidth: 2.5)
        )
        .accessibilityIdentifier("game_session_row")
    }
}
