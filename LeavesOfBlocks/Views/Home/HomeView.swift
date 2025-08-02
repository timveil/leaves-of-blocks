import SwiftUI

// MARK: - Game Home View

struct HomeView: View {
    @ObservedObject var gameState: GameState
    let onStartGame: (DifficultyMode) -> Void
    let onShowHistory: () -> Void
    
    @State private var selectedDifficulty: DifficultyMode = .moderate
    
    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            VStack(spacing: GameTheme.Layout.extraLargeSpacing) {
                // Invisible accessibility element for UI testing
                Text("")
                    .accessibilityIdentifier("home_screen_identifier")
                    .hidden()
                
                // High Score Display - Now tappable for history
                ScoreDisplayView(
                    score: gameState.highScore,
                    lastScore: gameState.score > 0 ? gameState.score : nil,
                    showHistoryHint: true,
                    action: onShowHistory
                )
                .frame(maxWidth: 280)
                
                Spacer().frame(maxHeight: 10)
                
                // Difficulty Selection
                DifficultySelectionView(
                    selectedDifficulty: $selectedDifficulty,
                    onStartGame: onStartGame
                )
                
                //Spacer(minLength: 100)
            }
            .padding(.horizontal, GameTheme.Layout.extraLargePadding)
            .padding(.bottom, 80)
        }
    }
}

#Preview {
    HomeView(
        gameState: GameState(),
        onStartGame: { _ in },
        onShowHistory: { }
    )
}
