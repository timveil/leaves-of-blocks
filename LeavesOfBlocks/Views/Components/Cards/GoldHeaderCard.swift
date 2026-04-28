import SwiftUI

// MARK: - Gold Header Card

struct GoldHeaderCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.buttonText)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(GameTheme.Colors.accent)
                .overlay(
                    Rectangle()
                        .frame(height: GameTheme.Layout.dividerHeight)
                        .foregroundColor(.black),
                    alignment: .bottom
                )

            content()
                .frame(maxWidth: .infinity)
                .padding(GameTheme.Layout.largePadding)
                .background(Color.white)
        }
        .folkArtCard()
    }
}

#Preview {
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
