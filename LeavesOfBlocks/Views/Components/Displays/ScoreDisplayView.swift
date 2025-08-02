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
        title: String = "best_score".localized,
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
                .accessibilityIdentifier("history_button")
            } else {
                scoreContent
            }
        }
    }
    
    private var scoreContent: some View {
        VStack(spacing: 0) {
            // Header with gradient background (like Statistics widget)
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(maxWidth: .infinity)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .background(GameTheme.Colors.accent)
            
            // Content area with brown background
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                if showIcon, let iconName = iconName {
                    Image(systemName: iconName)
                        .font(GameTheme.Typography.fontSmall)
                        .foregroundColor(GameTheme.Colors.accent)
                        .padding(.top, GameTheme.Layout.mediumPadding)
                }
                
                Text(score.formattedScore)
                    .font(GameTheme.Typography.fontXXLarge)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, showIcon ? 0 : GameTheme.Layout.mediumPadding)
                
                if let lastScore = lastScore {
                    Text("last_score_format".localized(with: lastScore.formattedScore))
                        .gameCaptionStyle()
                }
                
                if showHistoryHint {
                    Text("tap_for_history".localized)
                        .gameCaptionStyle(color: GameTheme.Colors.accent.opacity(0.7))
                        .padding(.bottom, GameTheme.Layout.mediumPadding)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.bottom, GameTheme.Layout.largePadding)
            .background(GameTheme.Colors.cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .stroke(
                    GameTheme.Gradients.cardBorder,
                    lineWidth: 1
                )
        )
        .shadow(
            color: GameTheme.Colors.cardShadow.opacity(0.15),
            radius: 12,
            x: 0,
            y: 6
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
