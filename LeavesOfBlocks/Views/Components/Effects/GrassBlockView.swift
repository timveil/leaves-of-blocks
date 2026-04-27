import SwiftUI

// MARK: - Grass Block Component

struct GrassBlockView: View {
    let color: Color
    let height: CGFloat
    let width: CGFloat = 12
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                GameTheme.Gradients.verticalFade(from: color, to: color.opacity(0.6))
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    HStack(spacing: 8) {
        GrassBlockView(color: GameTheme.Colors.blockGreen, height: 30)
        GrassBlockView(color: GameTheme.Colors.blockGreen, height: 40)
        GrassBlockView(color: GameTheme.Colors.blockGreen, height: 25)
    }
    .padding()
}

