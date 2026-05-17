import SwiftUI

/// Button style that darkens the entire label on press without changing
/// opacity. Replaces SwiftUI's default press fade, which makes buttons look
/// translucent against the folk-art backgrounds.
struct PressDarkenButtonStyle: ButtonStyle {
    var darkenAmount: Double = 0.08

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -darkenAmount : 0)
            .animation(GameTheme.Animations.buttonPress, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressDarkenButtonStyle {
    static var pressDarken: PressDarkenButtonStyle { PressDarkenButtonStyle() }
}
