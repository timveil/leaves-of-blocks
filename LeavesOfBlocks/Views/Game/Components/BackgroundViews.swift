import SwiftUI

// MARK: - Background Components

struct GameBackgroundView: View {
    var body: some View {
        // Simplified background - matches LaunchScreen for smooth transitions
        GameTheme.Gradients.background
            .ignoresSafeArea()
    }
}

struct BlockGrassView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Static grass texture from asset catalog
            Image("GrassTexture")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 80)
                .frame(maxWidth: .infinity) // Ensure it fills available width
                .clipped()
            
            // Static ground texture from asset catalog  
            Image("GroundTexture")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 20)
                .frame(maxWidth: .infinity) // Ensure it fills available width
                .clipped()
        }
    }
}

