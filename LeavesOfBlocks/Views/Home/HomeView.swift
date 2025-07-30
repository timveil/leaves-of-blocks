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
                Spacer(minLength: 20)
                
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
                
                Spacer(minLength: 150)
            }
            .padding(.horizontal, GameTheme.Layout.extraLargePadding)
            .padding(.bottom, GameTheme.Layout.extraLargePadding)
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
