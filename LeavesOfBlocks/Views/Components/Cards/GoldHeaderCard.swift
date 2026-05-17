import SwiftUI

// MARK: - Gold Header Card

/// Folk-art card with a gold header band and white content area.
///
/// `.standard` is the default look used for large title cards (high-score
/// display, game-over banner). `.compact` is a tight variant designed to
/// fit two-to-three cards across a row in a grid (CompactStatCard,
/// difficulty tile on the summary screen). Both styles share the same
/// header skeleton via `GoldHeaderBand` so a future tweak to the band
/// affects every site at once.
struct GoldHeaderCard<Content: View>: View {

    enum Style {
        /// Standard title font with generous padding. Stand-alone cards.
        case standard
        /// Small heavy uppercased title with letter tracking. Grid tiles.
        case compact
    }

    let title: String
    var style: Style = .standard
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            band

            content()
                .frame(maxWidth: .infinity, maxHeight: contentMaxHeight)
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.vertical, contentVerticalPadding)
                .background(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: contentMaxHeight)
        .folkArtCard()
    }

    private var band: GoldHeaderBand {
        switch style {
        case .standard:
            return GoldHeaderBand(title: title)
        case .compact:
            return GoldHeaderBand(
                title: title,
                titleFont: .system(size: 13, weight: .heavy, design: .default),
                letterTracking: 1.0,
                horizontalPadding: GameTheme.Layout.smallPadding,
                verticalPadding: GameTheme.Layout.smallPadding,
                uppercaseTitle: true,
                lineLimit: 2
            )
        }
    }

    private var contentHorizontalPadding: CGFloat {
        style == .compact ? GameTheme.Layout.smallPadding : GameTheme.Layout.largePadding
    }

    private var contentVerticalPadding: CGFloat {
        style == .compact ? GameTheme.Layout.mediumPadding : GameTheme.Layout.largePadding
    }

    private var contentMaxHeight: CGFloat? {
        // Compact cards stretch to fill grid row height; standard cards size to content.
        style == .compact ? .infinity : nil
    }
}

#Preview("Standard") {
    VStack(spacing: 16) {
        GoldHeaderCard(title: "high_score".localized) {
            Text("12,450")
                .font(GameTheme.Typography.display)
                .foregroundColor(GameTheme.Colors.primaryText)
        }

        GoldHeaderCard(title: "game_over".localized) {
            VStack(spacing: 12) {
                Text("Well played!")
                    .font(GameTheme.Typography.body)
                Text("1,250")
                    .font(GameTheme.Typography.display)
            }
        }
    }
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}

#Preview("Compact") {
    HStack(spacing: 16) {
        GoldHeaderCard(title: "high_score".localized, style: .compact) {
            Text("12,450")
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.primaryText)
        }
        GoldHeaderCard(title: "games_played".localized, style: .compact) {
            Text("42")
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.primaryText)
        }
    }
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}
