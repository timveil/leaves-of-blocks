import SwiftUI

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    @ObservedObject var gameState: GameState
    let onViewSummary: () -> Void
    let onNewGame: () -> Void

    var body: some View {
        GoldHeaderCard(title: "game_over".localized) {
            VStack(spacing: GameTheme.Layout.largePadding) {
                Text("game_over_quote".localized)
                    .font(GameTheme.Typography.body.italic())
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)

                ScoreDisplayView(
                    title: "final_score".localized,
                    score: gameState.score
                )

                VStack(spacing: GameTheme.Layout.mediumSpacing) {
                    FullWidthActionButton(
                        title: "new_game".localized,
                        style: .success,
                        onTap: onNewGame
                    )

                    FullWidthActionButton(
                        title: "view_summary".localized,
                        style: .secondary,
                        onTap: onViewSummary
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
                state.score = 1250
                state.isNewHighScore = true
                return state
            }(),
            onViewSummary: {},
            onNewGame: {}
        )
    }
}
