import SwiftUI

// MARK: - Score Display Component

struct ScoreDisplayView: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.caption)
                Text(title)
                    .font(GameTheme.Typography.captionFont)
                    .foregroundColor(color)
                    .tracking(1.5)
            }
            Text("\(value)")
                .font(GameTheme.Typography.scoreFont)
                .foregroundStyle(GameTheme.Gradients.text)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}