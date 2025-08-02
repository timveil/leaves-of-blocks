import SwiftUI

// MARK: - Header and Score Components

struct SimpleAppTitleView: View {
    var body: some View {
        Text("app_title".localized)
            .font(GameTheme.Typography.fontXLarge)
            .foregroundColor(GameTheme.Colors.primaryText)
            .padding(.vertical, GameTheme.Layout.smallPadding)
            .accessibilityIdentifier("leaves_of_blocks_title")
    }
}

struct SimpleScoreView: View {
    @ObservedObject var gameState: GameState
    
    private var displayScore: Int {
        // Show demo score in screenshot mode
        if ProcessInfo.processInfo.arguments.contains("-screenshot-mode") {
            return 941
        }
        return gameState.score
    }
    
    private var displayLinesCleared: Int {
        // Show demo lines cleared in screenshot mode
        if ProcessInfo.processInfo.arguments.contains("-screenshot-mode") {
            return 13
        }
        return gameState.linesCleared
    }
    
    var body: some View {
        VStack(spacing: GameTheme.Layout.tinySpacing) {
            HStack {
                // Current Score
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayScore.formattedScore)
                        .font(GameTheme.Typography.fontMediumLarge)
                        .foregroundColor(GameTheme.Colors.primaryText)
                        .accessibilityIdentifier("score_display")
                    Text("score".localized)
                        .font(GameTheme.Typography.fontXXSmall)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Lines Cleared Counter
                VStack(alignment: .trailing, spacing: 2) {
                    Text(displayLinesCleared.formattedScore)
                        .font(GameTheme.Typography.fontMediumLarge)
                        .foregroundColor(GameTheme.Colors.accent)
                    Text("lines".localized)
                        .font(GameTheme.Typography.fontXXSmall)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
        }
        .padding(.vertical, GameTheme.Layout.smallPadding)
    }
}