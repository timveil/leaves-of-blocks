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
        VStack(spacing: GameTheme.Layout.smallSpacing) {
            HStack {
                // Current Score
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(gameState.score)")
                        .font(GameTheme.Typography.largeScore)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    Text("Score")
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Lines Cleared Counter
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(gameState.linesCleared)")
                        .font(GameTheme.Typography.largeScore)
                        .foregroundColor(GameTheme.Colors.accent)
                    Text("Lines")
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
        }
        .padding(.vertical, GameTheme.Layout.mediumPadding)
    }
}