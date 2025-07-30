import SwiftUI

// MARK: - Base Screen View

/// A base container view that provides the standard layout structure for all game screens.
/// This includes the background, optional grass at the bottom, and content area.
struct BaseScreenView<Content: View>: View {
    let content: Content
    let showsGrass: Bool
    let showsStatusBar: Bool
    
    init(
        showsGrass: Bool = true,
        showsStatusBar: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.showsGrass = showsGrass
        self.showsStatusBar = showsStatusBar
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background layer
                GameBackgroundView()
                
                // Content layer - constrains the layout width and centers horizontally
                content
                    .frame(maxWidth: geometry.size.width)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .zIndex(1)
                
                // Grass layer (if enabled) - positioned absolutely to not affect layout
                if showsGrass {
                    VStack {
                        Spacer()
                        BlockGrassView()
                            .frame(width: geometry.size.width) // Constrain to screen width
                            .clipped() // Clip any overflow
                            .ignoresSafeArea(.all, edges: .bottom)
                    }
                    .zIndex(0)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .statusBarHidden(!showsStatusBar)
    }
}


