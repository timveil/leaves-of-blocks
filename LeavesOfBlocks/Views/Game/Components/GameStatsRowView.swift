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
                HStack(spacing: 6) {
                    Image(systemName: "cube.fill")
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.blockYellow)
                    Text(gameState.blocksPlaced.formattedScore)
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.primaryText)
                }

                Text("•")
                    .font(GameTheme.Typography.caption)
                    .foregroundColor(GameTheme.Colors.primaryText.opacity(0.4))

                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.blockBlue)
                    Text(formatGameTime(gameState.currentGameTime))
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.primaryText)
                }

                Text("•")
                    .font(GameTheme.Typography.caption)
                    .foregroundColor(GameTheme.Colors.primaryText.opacity(0.4))

                HStack(spacing: 4) {
                    ForEach(0..<gameState.currentDifficulty.acornCount, id: \.self) { _ in
                        Image("AcornIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 14)
                    }
                    Text(gameState.currentDifficulty.displayName)
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.primaryText)
                }
            }
            .padding(.horizontal, GameTheme.Layout.mediumPadding)
            .padding(.vertical, GameTheme.Layout.smallPadding)
            .background(
                Capsule()
                    .fill(Color.white)
                    .overlay(
                        Capsule()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
            )
            Spacer()
        }
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
