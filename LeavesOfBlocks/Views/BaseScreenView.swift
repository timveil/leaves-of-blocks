import SwiftUI

// MARK: - Base Screen View

/// A base container view that provides the standard layout structure for all game screens.
/// The tree background illustration frames all content.
struct BaseScreenView<Content: View>: View {
    let content: Content
    let showsStatusBar: Bool

    init(
        showsStatusBar: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.showsStatusBar = showsStatusBar
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GameBackgroundView()

                content
                    .frame(maxWidth: geometry.size.width)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .zIndex(1)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .statusBarHidden(!showsStatusBar)
    }
}
