import SwiftUI

struct GameStatsRowView: View {
    @ObservedObject var gameState: GameState
    let gameWidth: CGFloat
    
    // Helper function to format game time
    private func formatGameTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack {
            Spacer()
            HStack(alignment: .center, spacing: GameTheme.Layout.mediumSpacing) {
                // Blocks Placed Counter
                HStack(spacing: 10) {
                    Image(systemName: "cube.fill")
                        .font(GameTheme.Typography.body)
                        .foregroundColor(GameTheme.Colors.blockYellow)
                    Text(gameState.blocksPlaced.formattedScore)
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                // Separator
                Text("•")
                    .font(GameTheme.Typography.caption)
                    .foregroundColor(GameTheme.Colors.accent.opacity(0.8))
                
                // Timer
                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                        .font(GameTheme.Typography.body)
                        .foregroundColor(GameTheme.Colors.blockBlue)
                    Text(formatGameTime(gameState.currentGameTime))
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                // Separator
                Text("•")
                    .font(GameTheme.Typography.caption)
                    .foregroundColor(GameTheme.Colors.accent.opacity(0.8))
                
                // Difficulty Level
                HStack(spacing: 10) {
                    Image(systemName: gameState.currentDifficulty.icon)
                        .font(GameTheme.Typography.body)
                        .foregroundColor(gameState.currentDifficulty.color)
                    Text(gameState.currentDifficulty.rawValue)
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
            .frame(width: gameWidth)
            Spacer()
        }
        .padding(.vertical, GameTheme.Layout.smallPadding)
    }
}

#Preview {
    let mockGameState: GameState = {
        let state = GameState()
        state.blocksPlaced = 42
        state.currentDifficulty = .moderate
        return state
    }()
    
    return GameStatsRowView(
        gameState: mockGameState,
        gameWidth: 350
    )
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}
