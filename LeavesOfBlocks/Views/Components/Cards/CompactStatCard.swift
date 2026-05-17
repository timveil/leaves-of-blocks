import SwiftUI

/// A compact title + value tile for stat grids. Wraps `GoldHeaderCard` in
/// its `.compact` style with a single-line value rendered in `Typography.title`.
struct CompactStatCard: View {
    let title: String
    let value: String

    var body: some View {
        GoldHeaderCard(title: title, style: .compact) {
            Text(value)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .font(GameTheme.Typography.title)
                .foregroundColor(GameTheme.Colors.primaryText)
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        CompactStatCard(title: "high_score".localized, value: "12,450")
        CompactStatCard(title: "games_played".localized, value: "42")
        CompactStatCard(title: "average_score".localized, value: "3,180")
        CompactStatCard(title: "total_blocks".localized, value: "1,205")
    }
    .padding()
    .background(GameTheme.Colors.primaryBackground)
}
