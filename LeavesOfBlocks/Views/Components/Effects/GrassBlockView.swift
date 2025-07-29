import SwiftUI

// MARK: - Grass Block Component

struct GrassBlockView: View {
    let color: Color
    let height: CGFloat
    let width: CGFloat = 12
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct UIComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ScoreDisplayView(
                title: "Score",
                value: 1250,
                icon: "🎯",
                color: GameTheme.Colors.primaryAccent
            )
            
            AnimatedBadgeView(
                text: "Leaves Cleared:",
                icon: "🍃",
                value: 5,
                isVisible: true
            )
            
            Button("New Game") { }
                .gameButtonStyle()
            
            ErrorStateView(
                title: "Oops!",
                message: "Something went wrong",
                retryAction: { }
            )
        }
        .padding()
        .background(GameTheme.Colors.primaryBackground)
        .previewLayout(.sizeThatFits)
    }
}
#endif