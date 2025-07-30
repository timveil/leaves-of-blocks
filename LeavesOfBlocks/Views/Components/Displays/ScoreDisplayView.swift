import SwiftUI

// MARK: - Score Display View

/// A reusable component for displaying score information with optional last score and history navigation
struct ScoreDisplayView: View {
    let title: String
    let score: Int
    let lastScore: Int?
    let showHistoryHint: Bool
    let isHighlighted: Bool
    let showIcon: Bool
    let iconName: String?
    let action: (() -> Void)?
    
    init(
        title: String = "Best Score",
        score: Int,
        lastScore: Int? = nil,
        showHistoryHint: Bool = false,
        isHighlighted: Bool = false,
        showIcon: Bool = false,
        iconName: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.score = score
        self.lastScore = lastScore
        self.showHistoryHint = showHistoryHint
        self.isHighlighted = isHighlighted
        self.showIcon = showIcon
        self.iconName = iconName
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    scoreContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                scoreContent
            }
        }
    }
    
    private var scoreContent: some View {
        VStack(spacing: GameTheme.Layout.mediumSpacing) {
            Text(title)
                .font(GameTheme.Typography.headlineFont)
                .foregroundColor(GameTheme.Colors.accent)
                .tracking(1)
            
            if showIcon, let iconName = iconName {
                Image(systemName: iconName)
                    .font(GameTheme.Typography.bodyFont)
                    .foregroundColor(GameTheme.Colors.accent)
            }
            
            Text(score.formattedScore)
                .font(GameTheme.Typography.largeScore)
                .foregroundColor(GameTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            if let lastScore = lastScore {
                Text("Last Score: \(lastScore.formattedScore)")
                    .gameCaptionStyle()
            }
            
            if showHistoryHint {
                Text("Tap for History")
                    .gameCaptionStyle(color: GameTheme.Colors.accent.opacity(0.7))
            }
        }
        .padding(.horizontal, GameTheme.Layout.extraLargePadding)
        .padding(.vertical, GameTheme.Layout.extraLargePadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(
                    LinearGradient(
                        colors: isHighlighted 
                            ? [GameTheme.Colors.accent.opacity(0.4), GameTheme.Colors.accent.opacity(0.2)]
                            : [GameTheme.Colors.accent.opacity(0.3), GameTheme.Colors.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .game3DCardStyle(
            cornerRadius: GameTheme.Layout.cardCornerRadius,
            elevation: isHighlighted ? 10 : 8
        )
    }
}

// MARK: - Preview

#Preview("Score Display Views") {
    VStack(spacing: 20) {
        ScoreDisplayView(
            score: 12345,
            lastScore: 9876,
            showHistoryHint: true,
            action: {}
        )
        
        ScoreDisplayView(
            title: "Final Score",
            score: 54321,
            isHighlighted: true
        )
        
        ScoreDisplayView(
            title: "Final Score",
            score: 99999,
            showIcon: true,
            iconName: "crown.fill"
        )
    }
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}
