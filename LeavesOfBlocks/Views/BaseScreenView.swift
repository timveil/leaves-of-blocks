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

// MARK: - Convenience Initializers

extension View {
    /// Wraps any view in a BaseScreenView with standard game layout
    func gameScreen(showsGrass: Bool = true, showsStatusBar: Bool = false) -> some View {
        BaseScreenView(showsGrass: showsGrass, showsStatusBar: showsStatusBar) {
            self
        }
    }
    
    /// Wraps any view in a BaseScreenView with scrollable content
    func gameScrollableScreen(
        showsGrass: Bool = true,
        showsStatusBar: Bool = false,
        spacing: CGFloat = GameTheme.Layout.largePadding,
        horizontalPadding: CGFloat = GameTheme.Layout.largePadding
    ) -> some View {
        BaseScreenView(showsGrass: showsGrass, showsStatusBar: showsStatusBar) {
            ScrollView {
                VStack(spacing: spacing) {
                    self
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, showsGrass ? 80 : GameTheme.Layout.largePadding)
            }
        }
    }
    
    /// Wraps any view in a BaseScreenView with a navigation bar
    func gameScreenWithNavBar(
        title: String,
        showsGrass: Bool = true,
        showsStatusBar: Bool = false,
        onBack: @escaping () -> Void
    ) -> some View {
        BaseScreenView(showsGrass: showsGrass, showsStatusBar: showsStatusBar) {
            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: GameTheme.Layout.smallSpacing) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Back")
                                .font(GameTheme.Typography.bodyFont)
                        }
                        .foregroundColor(GameTheme.Colors.primaryText)
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .font(GameTheme.Typography.titleFont)
                        .foregroundColor(GameTheme.Colors.primaryText)
                    
                    Spacer()
                    
                    // Invisible spacer to balance the back button
                    HStack(spacing: GameTheme.Layout.smallSpacing) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Back")
                            .font(GameTheme.Typography.bodyFont)
                    }
                    .opacity(0)
                }
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.vertical, GameTheme.Layout.mediumPadding)
                .background(
                    GameTheme.Colors.cardBackground
                        .opacity(0.95)
                        .ignoresSafeArea(edges: .top)
                )
                
                // Content
                self
            }
        }
    }
}

