import SwiftUI

/// The "gold header" band reused at the top of `GoldHeaderCard`, in the
/// in-game score view, and on the How-To-Play table tops. Centralizes the
/// `headerBand` background, divider line, and centering so callers only
/// choose a font and padding.
struct GoldHeaderBand: View {
    let title: String
    var titleFont: Font = GameTheme.Typography.title
    var letterTracking: CGFloat = 0
    var horizontalPadding: CGFloat = GameTheme.Layout.largePadding
    var verticalPadding: CGFloat = GameTheme.Layout.mediumPadding
    var uppercaseTitle: Bool = false
    var lineLimit: Int? = nil

    var body: some View {
        Text(uppercaseTitle ? title.uppercased() : title)
            .font(titleFont)
            .tracking(letterTracking)
            .foregroundColor(GameTheme.Colors.primaryText)
            .lineLimit(lineLimit)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(GameTheme.Colors.headerBand)
            .overlay(
                Rectangle()
                    .frame(height: GameTheme.Layout.dividerHeight)
                    .foregroundColor(.black),
                alignment: .bottom
            )
    }
}
