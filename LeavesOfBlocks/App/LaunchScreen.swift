import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimated = false
    @State private var showIcon = false

    var body: some View {
        ZStack {
            GameBackgroundView()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 24) {
                    // Whitman Portrait in folk-art circle
                    Image("WhitmanPortrait")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth)
                        )
                        .shadow(color: GameTheme.Colors.cardShadow.opacity(0.4), radius: 16, x: 0, y: 8)
                        .scaleEffect(showIcon ? 1.0 : 0.5)
                        .opacity(showIcon ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6)
                            .delay(0.3),
                            value: showIcon
                        )

                    VStack(spacing: 8) {
                        Text("app_title".localized)
                            .font(GameTheme.Typography.title)
                            .foregroundColor(GameTheme.Colors.primaryText)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.85))
                            )
                            .scaleEffect(isAnimated ? 1.0 : 0.8)
                            .opacity(isAnimated ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.6)
                                .delay(0.8),
                                value: isAnimated
                            )

                        Text("app_tagline".localized)
                            .font(GameTheme.Typography.caption)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.75))
                            )
                            .opacity(isAnimated ? 1.0 : 0.0)
                            .animation(
                                .easeOut(duration: 1.0)
                                .delay(1.2),
                                value: isAnimated
                            )
                    }
                }

                Spacer()

                // Loading indicator
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(GameTheme.Colors.primaryAccent)
                                .frame(width: 12, height: 12)
                                .scaleEffect(isAnimated ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimated
                                )
                        }
                    }

                    Text("loading".localized)
                        .font(GameTheme.Typography.caption)
                        .foregroundColor(GameTheme.Colors.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.75))
                        )
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .animation(
                            .easeOut(duration: 1.0)
                            .delay(1.0),
                            value: isAnimated
                        )
                }
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            isAnimated = true
            showIcon = true
        }
    }
}

#Preview {
    LaunchScreen()
}
