import SwiftUI

// MARK: - Background Components

struct GameBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            GameTheme.Colors.primaryBackground

            Image("TreeBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .offset(x: -30)
                .clipped()
        }
        .ignoresSafeArea()
    }
}

struct BlockGrassView: View {
    var body: some View {
        EmptyView()
    }
}

// MARK: - Previews

#Preview {
    GameBackgroundView()
}

