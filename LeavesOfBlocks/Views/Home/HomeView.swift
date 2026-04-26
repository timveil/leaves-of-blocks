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

                // Single unified card for all home content
                VStack(spacing: GameTheme.Layout.largeSpacing) {
                    // High Score Display - tappable for history
                    ScoreDisplayView(
                        score: gameState.highScore,
                        lastScore: gameState.score > 0 ? gameState.score : nil,
                        showHistoryHint: true,
                        action: onShowHistory
                    )
                    .frame(maxWidth: 280)

                    // Difficulty buttons - each starts the game directly
                    DifficultySelectionView(
                        onStartGame: onStartGame
                    )
                }
                .padding(GameTheme.Layout.extraLargePadding)
                .game3DCardStyle(elevation: 10)

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
