import SwiftUI

// MARK: - Error State Component

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(GameTheme.Colors.error)
            
            Text(title)
                .font(GameTheme.Typography.headlineFont)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Text(message)
                .font(GameTheme.Typography.bodyFont)
                .foregroundColor(GameTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            if let retryAction = retryAction {
                GameButtonView(title: "Try Again", action: retryAction)
            }
        }
        .padding(32)
        .gameContainerStyle(
            backgroundColor: GameTheme.Colors.blockBackground.opacity(0.9),
            cornerRadius: GameTheme.Layout.mediumRadius,
            borderColor: GameTheme.Colors.error.opacity(0.3),
            borderWidth: 2
        )
    }
}