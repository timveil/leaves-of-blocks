import SwiftUI

// MARK: - Game Home View

struct GameHomeView: View {
    @ObservedObject var gameState: GameState
    let onStartGame: (DifficultyMode) -> Void
    let onShowHistory: () -> Void
    
    @State private var selectedDifficulty: DifficultyMode = .moderate
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GameBackgroundView()
                
                VStack(spacing: 0) {
                    // Main content area
                    VStack(spacing: GameTheme.Layout.extraLargeSpacing) {
                        Spacer(minLength: 60)
                        
                        // High Score Display - Now tappable for history
                        Button(action: onShowHistory) {
                            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                                Text("Best Score")
                                    .font(GameTheme.Typography.titleFont)
                                    .foregroundColor(GameTheme.Colors.accent)
                                
                                Text("\(gameState.highScoreManager.highScore)")
                                    .font(GameTheme.Typography.largeScore)
                                    .foregroundColor(GameTheme.Colors.primaryText)
                                    
                                // Last played info if available
                                if gameState.score > 0 {
                                    Text("Last Score: \(gameState.score)")
                                        .font(GameTheme.Typography.captionFont)
                                        .foregroundColor(GameTheme.Colors.secondaryText)
                                }
                                
                                Text("Tap for History")
                                    .font(GameTheme.Typography.captionFont)
                                    .foregroundColor(GameTheme.Colors.accent.opacity(0.7))
                            }
                            .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                            .padding(.vertical, GameTheme.Layout.extraLargePadding)
                            .background(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                    .fill(GameTheme.Colors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                            .stroke(GameTheme.Colors.accent.opacity(0.3), lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer(minLength: 20)
                        
                        // Difficulty Selection
                        DifficultySelectionView(
                            selectedDifficulty: $selectedDifficulty,
                            onStartGame: onStartGame
                        )
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                    .padding(.top, GameTheme.Layout.extraLargePadding)
                    
                    // Grass always at bottom
                    BlockGrassView()
                        .ignoresSafeArea(.all, edges: .bottom)
                }
                
            }
        }
        .statusBarHidden()
    }
}