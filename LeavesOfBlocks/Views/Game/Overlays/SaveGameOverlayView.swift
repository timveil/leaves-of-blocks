import SwiftUI

// MARK: - Save Game Overlay

struct SaveGameOverlayView: View {
    var gameState: GameState
    let onSaveGame: () -> Void
    let onExitGame: () -> Void

    var body: some View {
        GoldHeaderCard(title: "save_game_title".localized) {
            VStack(spacing: GameTheme.Layout.largePadding) {
                Text("save_game_message".localized)
                    .font(GameTheme.Typography.body)
                    .foregroundColor(GameTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)

                HStack(spacing: GameTheme.Layout.extraLargeSpacing) {
                    CircularIconButton(
                        icon: "tray.and.arrow.down.fill",
                        accessibilityLabel: "save_game_button".localized,
                        color: GameTheme.Colors.success,
                        action: onSaveGame
                    )

                    CircularIconButton(
                        icon: "xmark",
                        accessibilityLabel: "exit_without_saving".localized,
                        color: GameTheme.Colors.error,
                        action: onExitGame
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
