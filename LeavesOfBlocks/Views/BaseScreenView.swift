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
        ZStack {
            // Background layer
            GameBackgroundView()
            
            // Grass layer (if enabled)
            if showsGrass {
                VStack {
                    Spacer()
                    BlockGrassView()
                        .ignoresSafeArea(.all, edges: .bottom)
                }
                .zIndex(0)
            }
            
            // Content layer
            content
                .zIndex(1)
        }
        .ignoresSafeArea(edges: .bottom)
        .statusBarHidden(!showsStatusBar)
    }
}


