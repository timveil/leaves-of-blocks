import SwiftUI

// MARK: - Styled Button Component

struct GameButtonView: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .tracking(0.5)
        }
        .gameButtonStyle()
        .scaleEffect(1.0)
        .animation(.spring(response: GameTheme.Animations.springResponse), value: title)
    }
}