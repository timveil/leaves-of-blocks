import SwiftUI

// MARK: - Stroked Title

/// White serif heading with a dark stroke. Used as the page title on most
/// screens and as the section title within Statistics. The stroke gives the
/// text high contrast against the busy folk-art background — the standard
/// "stamped on artwork" treatment used by casual games.
///
/// The component is intentionally flat: no drop shadow, matching the rest of
/// the UI's flat aesthetic.
struct StrokedTitle: View {
    let text: String
    var font: Font = StrokedTitle.defaultFont
    var strokeWidth: CGFloat = 1.5
    var fillColor: Color = .white
    var strokeColor: Color = .black

    static let defaultFont: Font = .system(.largeTitle, design: .default).weight(.black)

    /// Eight evenly-spaced offsets approximate a 1px-equivalent stroke ring.
    private var strokeOffsets: [CGSize] {
        [
            CGSize(width: -strokeWidth, height: 0),
            CGSize(width: strokeWidth, height: 0),
            CGSize(width: 0, height: -strokeWidth),
            CGSize(width: 0, height: strokeWidth),
            CGSize(width: -strokeWidth, height: -strokeWidth),
            CGSize(width: strokeWidth, height: -strokeWidth),
            CGSize(width: -strokeWidth, height: strokeWidth),
            CGSize(width: strokeWidth, height: strokeWidth)
        ]
    }

    var body: some View {
        ZStack {
            ForEach(strokeOffsets.indices, id: \.self) { index in
                let offset = strokeOffsets[index]
                Text(text)
                    .font(font)
                    .foregroundColor(strokeColor)
                    .offset(x: offset.width, y: offset.height)
            }

            Text(text)
                .font(font)
                .foregroundColor(fillColor)
        }
    }
}

#Preview {
    ZStack {
        GameTheme.Gradients.background
            .ignoresSafeArea()

        VStack(alignment: .leading, spacing: 24) {
            StrokedTitle(text: "Game History")
            StrokedTitle(text: "Statistics")
            StrokedTitle(text: "How to Play")
            StrokedTitle(text: "About the Game")
            StrokedTitle(text: "Settings")
        }
        .padding()
    }
}
