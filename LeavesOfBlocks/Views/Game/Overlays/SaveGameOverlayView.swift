import SwiftUI

// MARK: - Save Game Overlay

struct SaveGameOverlayView: View {
    @ObservedObject var gameState: GameState
    let onSaveGame: () -> Void
    let onExitGame: () -> Void

    var body: some View {
        GoldHeaderCard(title: "save_game_title".localized) {
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
        }
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
