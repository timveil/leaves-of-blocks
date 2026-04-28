import SwiftUI

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    var gameState: GameState
    let onViewSummary: () -> Void
    let onNewGame: () -> Void

    var body: some View {
        GoldHeaderCard(title: "game_over".localized) {
            VStack(spacing: GameTheme.Layout.largePadding) {
                Text("game_over_quote".localized)
                    .font(GameTheme.Typography.body.italic())
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)

                Text(gameState.score.abbreviatedScore)
                    .font(GameTheme.Typography.display)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: GameTheme.Layout.extraLargeSpacing) {
                    CircularIconButton(
                        icon: "play.fill",
                        accessibilityLabel: "new_game".localized,
                        color: GameTheme.Colors.success,
                        action: onNewGame
                    )

                    CircularIconButton(
                        icon: "list.bullet",
                        accessibilityLabel: "view_summary".localized,
                        color: GameTheme.Colors.accent,
                        action: onViewSummary
                    )
                }
            }
        }
        .padding(.horizontal, GameTheme.Layout.extraLargePadding)
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        GameTheme.Gradients.background
            .ignoresSafeArea()

        GameOverOverlayView(
            gameState: {
                let state = GameState()
                state.score = 100250
                state.isNewHighScore = true
                return state
            }(),
            onViewSummary: {},
            onNewGame: {}
        )
    }
}
