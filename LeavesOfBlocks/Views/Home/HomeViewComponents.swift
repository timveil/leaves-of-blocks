import SwiftUI

// MARK: - Difficulty Selection Component

struct DifficultySelectionView: View {
    let onStartGame: (DifficultyMode) -> Void

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
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { index in
                    Image("AcornIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .opacity(index <= acornCount ? 1.0 : 0.2)
                        .animation(.easeInOut(duration: 0.2), value: acornCount)
                }
            }

            // Difficulty label
            Text(selectedDifficulty.displayName)
                .font(GameTheme.Typography.headline)
                .foregroundColor(GameTheme.Colors.primaryText)
                .animation(.easeInOut(duration: 0.2), value: selectedDifficulty)

            // Custom slider
            AcornSlider(value: $sliderValue)
                .frame(height: 36)

            // Play button
            Button(action: {
                onStartGame(selectedDifficulty)
            }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 32))
                    .foregroundColor(GameTheme.Colors.buttonText)
                    .frame(width: 72, height: 72)
                    .background(
                        Circle()
                            .fill(GameTheme.Colors.success)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("start_game_button")
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
                RoundedRectangle(cornerRadius: 4)
                    .fill(GameTheme.Colors.cardBackground)
                    .frame(height: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 2)
                    )

                // Filled portion
                RoundedRectangle(cornerRadius: 4)
                    .fill(GameTheme.Colors.accent)
                    .frame(width: thumbX + 18, height: 8)

                // Tick marks
                HStack {
                    ForEach(0..<3) { i in
                        if i > 0 { Spacer() }
                        Circle()
                            .fill(Color.black)
                            .frame(width: 6, height: 6)
                        if i < 2 { Spacer() }
                    }
                }
                .padding(.horizontal, 15)

                // Thumb
                Circle()
                    .fill(GameTheme.Colors.primaryBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: GameTheme.Layout.cardBorderWidth)
                    )
                    .offset(x: thumbX - 18)
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
