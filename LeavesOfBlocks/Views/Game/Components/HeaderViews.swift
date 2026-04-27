import SwiftUI

// MARK: - Header and Score Components

struct SimpleAppTitleView: View {
    var body: some View {
        Text("app_title".localized)
            .font(GameTheme.Typography.title)
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
        VStack(spacing: 0) {
            // Gold header
            Text("score".localized)
                .font(GameTheme.Typography.headline)
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.smallPadding)
                .background(GameTheme.Colors.accent)
                .overlay(
                    Rectangle()
                        .frame(height: GameTheme.Layout.dividerHeight)
                        .foregroundColor(.black),
                    alignment: .bottom
                )

            // Score and lines content
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayScore.formattedScore)
                        .font(GameTheme.Typography.title)
                        .foregroundColor(GameTheme.Colors.primaryText)
                        .accessibilityIdentifier("score_display")
                    Text("points".localized)
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(displayLinesCleared.formattedScore)
                        .font(GameTheme.Typography.title)
                        .foregroundColor(GameTheme.Colors.accent)
                    Text("lines".localized)
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                }
            }
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .background(Color.white)
        }
        .folkArtCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ax_score_format".localized(with: displayScore.formattedScore, displayLinesCleared.formattedScore))
    }
}

// MARK: - Previews

#Preview("Score View") {
    let state: GameState = {
        let s = GameState()
        s.score = 1250
        s.linesCleared = 7
        return s
    }()
    SimpleScoreView(gameState: state)
        .frame(width: 350)
        .padding()
}

#Preview("App Title") {
    SimpleAppTitleView()
        .padding()
}