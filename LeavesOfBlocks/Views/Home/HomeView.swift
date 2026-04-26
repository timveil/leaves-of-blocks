import SwiftUI

// MARK: - Game Home View

struct HomeView: View {
    @ObservedObject var gameState: GameState
    let onStartGame: (DifficultyMode) -> Void
    let onShowHistory: () -> Void

    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            VStack {
                // Invisible accessibility element for UI testing
                Text("")
                    .accessibilityIdentifier("home_screen_identifier")
                    .hidden()

                Spacer()

                VStack(spacing: GameTheme.Layout.largePadding) {
                    ScoreDisplayView(
                        score: gameState.highScore,
                        lastScore: gameState.score > 0 ? gameState.score : nil,
                        showHistoryHint: true,
                        action: onShowHistory
                    )

                    VStack(spacing: 0) {
                        Text("ready_to_play".localized)
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

                        DifficultySelectionView(
                            onStartGame: onStartGame
                        )
                        .padding(.horizontal, GameTheme.Layout.largePadding)
                        .padding(.vertical, GameTheme.Layout.largePadding)
                        .background(Color.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                            .stroke(Color.black, lineWidth: 2.5)
                    )
                }

                Spacer()
            }
            .padding(.horizontal, GameTheme.Layout.largePadding)
        }
    }
}

#Preview {
    HomeView(
        gameState: {
            let state = GameState()
            state.previewHighScore = 10_350
            state.score = 87_200
            return state
        }(),
        onStartGame: { _ in },
        onShowHistory: { }
    )
}
