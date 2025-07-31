import SwiftUI

// MARK: - Header and Score Components

struct SimpleAppTitleView: View {
    var body: some View {
        Text("Leaves of Blocks")
            .font(GameTheme.Typography.title)
            .foregroundColor(GameTheme.Colors.primaryText)
            .padding(.vertical, GameTheme.Layout.smallPadding)
    }
}

struct SimpleScoreView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.tinySpacing) {
            HStack {
                // Current Score
                VStack(alignment: .leading, spacing: 2) {
                    Text(gameState.score.formattedScore)
                        .font(GameTheme.Typography.scoreFont)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    Text("Score")
                        .font(GameTheme.Typography.subtitleFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Lines Cleared Counter
                VStack(alignment: .trailing, spacing: 2) {
                    Text(gameState.linesCleared.formattedScore)
                        .font(GameTheme.Typography.scoreFont)
                        .foregroundColor(GameTheme.Colors.accent)
                    Text("Lines")
                        .font(GameTheme.Typography.subtitleFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
        }
        .padding(.vertical, GameTheme.Layout.smallPadding)
    }
}