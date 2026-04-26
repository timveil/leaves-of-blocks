import SwiftUI

// MARK: - Slide-Down Menu

struct ToolbarView: View {
    let currentScreen: AppScreen
    let onGoHome: () -> Void
    let onShowAbout: () -> Void
    let onShowHowToPlay: () -> Void
    let onShowSettings: () -> Void
    let onNewGame: () -> Void
    let onDismiss: () -> Void

    private let iconSize: CGFloat = 28

    var body: some View {
        VStack(spacing: GameTheme.Layout.largeSpacing) {
            // Menu grid
            HStack(spacing: GameTheme.Layout.extraLargeSpacing) {
                menuButton(
                    icon: "house",
                    label: "home".localized,
                    accessibilityId: "home_button",
                    disabled: currentScreen == .home
                ) {
                    onGoHome()
                    onDismiss()
                }

                menuButton(
                    icon: "play",
                    label: "new_game_menu".localized,
                    accessibilityId: "new_game_button"
                ) {
                    onNewGame()
                    onDismiss()
                }

                menuButton(
                    icon: "questionmark",
                    label: "how_to_play_menu".localized,
                    accessibilityId: "how_to_play_button"
                ) {
                    onShowHowToPlay()
                    onDismiss()
                }

                menuButton(
                    icon: "info",
                    label: "about_menu".localized,
                    accessibilityId: "about_button"
                ) {
                    onShowAbout()
                    onDismiss()
                }

                menuButton(
                    icon: "gearshape",
                    label: "settings_menu".localized,
                    accessibilityId: "settings_button"
                ) {
                    onShowSettings()
                    onDismiss()
                }
            }

            // Pull handle to dismiss
            Capsule()
                .fill(Color.black.opacity(0.3))
                .frame(width: 40, height: 4)
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.top, GameTheme.Layout.largePadding)
        .padding(.bottom, GameTheme.Layout.mediumPadding)
        .background(
            GameTheme.Colors.cardBackground
                .ignoresSafeArea(edges: .top)
        )
        .overlay(
            Rectangle()
                .frame(height: 2.5)
                .foregroundColor(.black),
            alignment: .bottom
        )
    }

    private func menuButton(
        icon: String,
        label: String,
        accessibilityId: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(disabled ? GameTheme.Colors.tertiaryText : GameTheme.Colors.primaryText)
                    .frame(width: 44, height: 44)

                Text(label)
                    .font(GameTheme.Typography.tiny)
                    .foregroundColor(disabled ? GameTheme.Colors.tertiaryText : GameTheme.Colors.secondaryText)
            }
        }
        .disabled(disabled)
        .accessibilityIdentifier(accessibilityId)
    }
}

#Preview {
    VStack {
        ToolbarView(
            currentScreen: .home,
            onGoHome: {},
            onShowAbout: {},
            onShowHowToPlay: {},
            onShowSettings: {},
            onNewGame: {},
            onDismiss: {}
        )

        Spacer()
    }
    .background(GameTheme.Colors.primaryBackground)
}
