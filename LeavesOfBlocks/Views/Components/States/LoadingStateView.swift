import SwiftUI

// MARK: - Loading State Component

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(GameTheme.Colors.primaryAccent)
            
            Text(message)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
        }
        .padding(32)
        .gameContainerStyle(
            backgroundColor: GameTheme.Colors.blockBackground.opacity(0.9),
            cornerRadius: GameTheme.Layout.mediumRadius,
            borderColor: GameTheme.Colors.gridBorder.opacity(0.3),
            borderWidth: 1
        )
    }
}