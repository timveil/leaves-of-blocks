import SwiftUI

// MARK: - Difficulty Selection Component

struct DifficultySelectionView: View {
    let onStartGame: (DifficultyMode) -> Void
    var playButtonTitle: String = "play_game".localized

    @State private var sliderValue: Double = 2

    private var selectedDifficulty: DifficultyMode {
        switch Int(sliderValue.rounded()) {
        case 1: return .easy
        case 3: return .hard
        default: return .moderate
        }
    }

    private var acornCount: Int {
        Int(sliderValue.rounded())
    }

    var body: some View {
        VStack(spacing: GameTheme.Layout.extraLargeSpacing) {
            // Acorn display
            HStack(spacing: GameTheme.Layout.mediumSpacing) {
                ForEach(1...3, id: \.self) { index in
                    Image("AcornIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: GameTheme.Layout.acornIconHeight)
                        .opacity(index <= acornCount ? 1.0 : 0.2)
                        .animation(GameTheme.Animations.difficultySelection, value: acornCount)
                }
            }

            // Difficulty label
            Text(selectedDifficulty.displayName)
                .font(GameTheme.Typography.headline)
                .foregroundColor(GameTheme.Colors.primaryText)
                .animation(GameTheme.Animations.difficultySelection, value: selectedDifficulty)

            // Custom slider
            AcornSlider(value: $sliderValue)
                .frame(height: GameTheme.Layout.sliderHeight)
                .accessibilityElement()
                .accessibilityLabel("ax_difficulty_slider".localized)
                .accessibilityValue(selectedDifficulty.displayName)
                .accessibilityHint("ax_difficulty_hint".localized)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        sliderValue = min(3, sliderValue + 1)
                    case .decrement:
                        sliderValue = max(1, sliderValue - 1)
                    @unknown default:
                        break
                    }
                }

            // Play button
            FullWidthActionButton(
                title: playButtonTitle,
                icon: "play.fill",
                style: .primary,
                accessibilityId: "start_game_button"
            ) {
                onStartGame(selectedDifficulty)
            }
        }
        .padding(.horizontal, GameTheme.Layout.mediumPadding)
    }
}

// MARK: - Custom Acorn Slider

private struct AcornSlider: View {
    @Binding var value: Double

    @GestureState private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let fraction = CGFloat((value - 1) / 2)
            let thumbX = fraction * trackWidth

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: GameTheme.Layout.smallSpacing)
                    .fill(GameTheme.Colors.cardBackground)
                    .frame(height: GameTheme.Layout.sliderTrackHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.smallSpacing)
                            .stroke(GameTheme.Colors.outline, lineWidth: GameTheme.Layout.gridLineWidth)
                    )

                // Filled portion
                RoundedRectangle(cornerRadius: GameTheme.Layout.smallSpacing)
                    .fill(GameTheme.Colors.accent)
                    .frame(width: thumbX + GameTheme.Layout.sliderHeight / 2, height: GameTheme.Layout.sliderTrackHeight)

                // Tick marks
                HStack {
                    ForEach(0..<3) { i in
                        if i > 0 { Spacer() }
                        Circle()
                            .fill(GameTheme.Colors.outline)
                            .frame(width: GameTheme.Layout.tightSpacing, height: GameTheme.Layout.tightSpacing)
                        if i < 2 { Spacer() }
                    }
                }
                .padding(.horizontal, GameTheme.Layout.sliderTickPadding)

                // Thumb
                Circle()
                    .fill(GameTheme.Colors.primaryBackground)
                    .frame(width: GameTheme.Layout.sliderHeight, height: GameTheme.Layout.sliderHeight)
                    .overlay(
                        Circle()
                            .stroke(GameTheme.Colors.outline, lineWidth: GameTheme.Layout.cardBorderWidth)
                    )
                    .offset(x: thumbX - GameTheme.Layout.sliderHeight / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let fraction = max(0, min(1, drag.location.x / trackWidth))
                                let snapped = (fraction * 2 + 1).rounded()
                                value = min(3, max(1, snapped))
                            }
                    )
            }
        }
    }
}

// MARK: - Previews

#Preview("Difficulty Selection") {
    DifficultySelectionView(onStartGame: { _ in })
        .frame(width: 300)
        .padding()
}
