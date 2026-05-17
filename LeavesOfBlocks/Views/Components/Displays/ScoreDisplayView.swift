import SwiftUI

// MARK: - Score Display View

/// A reusable component for displaying score information with optional last score and history navigation
struct ScoreDisplayView: View {
    let title: String
    let score: Int
    let subtitle: String?
    let lastScore: Int?
    let showHistoryHint: Bool
    let showIcon: Bool
    let iconName: String?
    let action: (() -> Void)?

    init(
        title: String = "best_score".localized,
        score: Int,
        subtitle: String? = nil,
        lastScore: Int? = nil,
        showHistoryHint: Bool = false,
        showIcon: Bool = false,
        iconName: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.score = score
        self.subtitle = subtitle
        self.lastScore = lastScore
        self.showHistoryHint = showHistoryHint
        self.showIcon = showIcon
        self.iconName = iconName
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: {
                    HapticFeedback.tap()
                    action()
                }) {
                    scoreContent
                }
                .buttonStyle(.pressDarken)
                .accessibilityIdentifier("history_button")
            } else {
                scoreContent
            }
        }
    }
    
    private var scoreContent: some View {
        VStack(spacing: 0) {
            // Header
            Text(title)
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.primaryText)
                .frame(maxWidth: .infinity)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            .background(GameTheme.Colors.headerBand)
            .overlay(
                Rectangle()
                    .frame(height: GameTheme.Layout.dividerHeight)
                    .foregroundColor(GameTheme.Colors.outline),
                alignment: .bottom
            )

            // Content area
            VStack(spacing: GameTheme.Layout.mediumSpacing) {
                if showIcon, let iconName = iconName {
                    Image(systemName: iconName)
                        .font(GameTheme.Typography.body)
                        .foregroundColor(GameTheme.Colors.accent)
                        .padding(.top, GameTheme.Layout.mediumPadding)
                        // Decorative — the high-score achievement is already
                        // conveyed by the surrounding score text and haptic.
                        // VoiceOver would otherwise announce a bare "crown".
                        .accessibilityHidden(true)
                }
                
                Text(score.abbreviatedScore)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, showIcon ? 0 : GameTheme.Layout.mediumPadding)
                    .font(GameTheme.Typography.display)
                    .foregroundColor(GameTheme.Colors.primaryText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .gameCaptionStyle()
                        .padding(.bottom, GameTheme.Layout.mediumPadding)
                }

                if let lastScore = lastScore {
                    Text("last_score_format".localized(with: lastScore.formattedScore))
                        .gameCaptionStyle()
                }
                
                if showHistoryHint {
                    Text("tap_for_history".localized)
                        .gameCaptionStyle(color: GameTheme.Colors.primaryText.opacity(0.6))
                        .padding(.bottom, GameTheme.Layout.mediumPadding)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.bottom, GameTheme.Layout.largePadding)
            .background(Color.white)
        }
        .folkArtCard()
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
            title: "final_score".localized,
            score: 54321
        )
        
        ScoreDisplayView(
            title: "final_score".localized,
            score: 99999,
            showIcon: true,
            iconName: "crown.fill"
        )
    }
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}
