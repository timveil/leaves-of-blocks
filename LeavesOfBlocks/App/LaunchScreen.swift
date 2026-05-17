import SwiftUI

/// In-app branding splash shown once on cold launch.
///
/// The OS storyboard splash (`LaunchScreen.storyboard`) handles the very first
/// frame; this view runs a short staged entrance for the Whitman sticker, then
/// signals completion via `onComplete`.
///
/// The animation sequence is ~0.8 seconds; when Reduce Motion is enabled the
/// splash dismisses immediately so users aren't held behind an animation
/// they've explicitly opted out of.
struct LaunchScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Total dwell time before the splash dismisses, including animation tail.
    private static let dwell: Duration = .milliseconds(800)

    let onComplete: () -> Void

    @State private var visible = false

    var body: some View {
        ZStack {
            GameBackgroundView()

            WhitmanSticker(size: 240)
                .scaleEffect(visible ? 1.0 : 0.6)
                .opacity(visible ? 1.0 : 0.0)
                .animation(
                    reduceMotion ? nil : GameTheme.Animations.launchScreenEntrance,
                    value: visible
                )
        }
        .task {
            visible = true

            // Reduce Motion: skip the dwell. The OS storyboard splash already
            // covers the cold-launch moment; users don't owe us another second.
            if reduceMotion {
                onComplete()
                return
            }

            try? await Task.sleep(for: Self.dwell)
            onComplete()
        }
    }
}

#Preview {
    LaunchScreen(onComplete: {})
}
