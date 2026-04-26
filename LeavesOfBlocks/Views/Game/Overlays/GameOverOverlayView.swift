import SwiftUI

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    @ObservedObject var gameState: GameState
    let onViewSummary: () -> Void
    let onNewGame: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("game_over".localized)
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(GameTheme.Colors.accent)
                .overlay(
                    Rectangle()
                        .frame(height: 2.5)
                        .foregroundColor(.black),
                    alignment: .bottom
                )

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
            .padding(GameTheme.Layout.largePadding)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .stroke(Color.black, lineWidth: 2.5)
        )
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
