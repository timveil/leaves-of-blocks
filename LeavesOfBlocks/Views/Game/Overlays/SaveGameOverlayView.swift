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

                HStack(spacing: GameTheme.Layout.extraLargeSpacing) {
                    circularButton(
                        icon: "tray.and.arrow.down.fill",
                        accessibilityLabel: "save_game_button".localized,
                        color: GameTheme.Colors.success,
                        action: onSaveGame
                    )

                    circularButton(
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

    private func circularButton(icon: String, accessibilityLabel: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(color)
                )
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
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
