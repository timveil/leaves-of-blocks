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
                Button(action: onShowHistory) {
                    VStack(spacing: GameTheme.Layout.mediumSpacing) {
                        Text("Best Score")
                            .pageTitleStyle(color: GameTheme.Colors.accent)
                        
                        Text("\(gameState.highScore)")
                            .font(GameTheme.Typography.largeScore)
                            .foregroundColor(GameTheme.Colors.primaryText)
                            
                        // Last played info if available
                        if gameState.score > 0 {
                            Text("Last Score: \(gameState.score)")
                                .gameCaptionStyle()
                        }
                        
                        Text("Tap for History")
                            .gameCaptionStyle(color: GameTheme.Colors.accent.opacity(0.7))
                    }
                    .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                    .padding(.vertical, GameTheme.Layout.extraLargePadding)
                    .gameGradientCardStyle(
                        gradient: LinearGradient(
                            colors: [GameTheme.Colors.accent.opacity(0.3), GameTheme.Colors.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        borderWidth: 2
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer(minLength: 10)
                
                // Difficulty Selection
                DifficultySelectionView(
                    selectedDifficulty: $selectedDifficulty,
                    onStartGame: onStartGame
                )
                
                Spacer(minLength: 120)
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
