import SwiftUI

/// In-app branding splash shown once on cold launch.
///
/// The OS storyboard splash (`LaunchScreen.storyboard`) handles the very first
/// frame; this view runs a short staged entrance for the Whitman portrait,
/// app title, and tagline, then signals completion via `onComplete`.
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

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 24) {
                    portraitView
                        .scaleEffect(visible ? 1.0 : 0.6)
                        .opacity(visible ? 1.0 : 0.0)
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7),
                            value: visible
                        )

                    titleView
                        .scaleEffect(visible ? 1.0 : 0.85)
                        .opacity(visible ? 1.0 : 0.0)
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.75).delay(0.15),
                            value: visible
                        )

                    taglineView
                        .opacity(visible ? 1.0 : 0.0)
                        .animation(
                            reduceMotion ? nil : .easeOut(duration: 0.35).delay(0.30),
                            value: visible
                        )
                }

                Spacer()
            }
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

    // MARK: - Subviews

    private var portraitView: some View {
        Image("WhitmanPortrait")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 180, height: 180)
            .clipShape(Circle())
            .padding(14)
            .background(Circle().fill(Color.white))
            .overlay(
                Circle().stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth)
            )
            .shadow(color: GameTheme.Colors.cardShadow.opacity(0.4), radius: 16, x: 0, y: 8)
    }

    private var titleView: some View {
        Text("app_title".localized)
            .font(GameTheme.Typography.title)
            .foregroundColor(GameTheme.Colors.primaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.85)))
    }

    private var taglineView: some View {
        Text("app_tagline".localized)
            .font(GameTheme.Typography.caption)
            .foregroundColor(GameTheme.Colors.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.75)))
    }
}

#Preview {
    LaunchScreen(onComplete: {})
}
