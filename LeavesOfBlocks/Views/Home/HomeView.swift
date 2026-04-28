import SwiftUI

// MARK: - Game Home View

struct HomeView: View {
    var gameState: GameState
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

                    GoldHeaderCard(title: "ready_to_play".localized) {
                        DifficultySelectionView(
                            onStartGame: onStartGame
                        )
                    }
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
