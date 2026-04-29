import SwiftUI

/// Compact two-column variant of `GoldHeaderCard`. Same visual language
/// (gold header, white content, folk-art border) but with reduced fonts and
/// padding so two tiles fit comfortably side-by-side in a grid.
struct CompactGoldHeaderCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(GameTheme.Typography.headline)
                .foregroundColor(GameTheme.Colors.buttonText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, GameTheme.Layout.smallPadding)
                .padding(.vertical, GameTheme.Layout.smallPadding)
                .background(GameTheme.Colors.accent)
                .overlay(
                    Rectangle()
                        .frame(height: GameTheme.Layout.dividerHeight)
                        .foregroundColor(.black),
                    alignment: .bottom
                )

            content()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, GameTheme.Layout.smallPadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(Color.white)
        }
        .folkArtCard()
    }
}

#Preview {
    HStack(spacing: 16) {
        CompactGoldHeaderCard(title: "high_score".localized) {
            Text("12,450")
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.primaryText)
        }
        CompactGoldHeaderCard(title: "games_played".localized) {
            Text("42")
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.primaryText)
        }
    }
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}
