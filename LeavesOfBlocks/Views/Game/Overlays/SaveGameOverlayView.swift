import SwiftUI

// MARK: - Save Game Overlay

struct SaveGameOverlayView: View {
    @ObservedObject var gameState: GameState
    let onSaveGame: () -> Void
    let onExitGame: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("save_game_title".localized)
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
                Text("save_game_message".localized)
                    .font(GameTheme.Typography.body)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)

                ScoreDisplayView(
                    title: "current_score".localized,
                    score: gameState.score
                )

                VStack(spacing: GameTheme.Layout.mediumSpacing) {
                    FullWidthActionButton(
                        title: "save_game_button".localized,
                        style: .success,
                        onTap: onSaveGame
                    )

                    FullWidthActionButton(
                        title: "exit_without_saving".localized,
                        style: .danger,
                        onTap: onExitGame
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

        SaveGameOverlayView(
            gameState: {
                let state = GameState()
                state.score = 875
                return state
            }(),
            onSaveGame: {},
            onExitGame: {}
        )
    }
}
