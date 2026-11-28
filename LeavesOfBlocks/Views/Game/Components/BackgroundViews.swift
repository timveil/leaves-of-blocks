import SwiftUI

// MARK: - Background Components

struct GameBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            GameTheme.Colors.primaryBackground

            Image("TreeBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                // The art sits 30pt left of center. Widening the frame by
                // twice that and shifting it back keeps the same center while
                // still covering the right edge on screens as wide as an
                // iPad's, where the 2:3 art no longer overflows sideways.
                // iPhones stay height-limited, so their rendering is unchanged.
                .frame(width: geo.size.width + 60, height: geo.size.height)
                .offset(x: -60)
                .clipped()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Previews

#Preview {
    GameBackgroundView()
}

