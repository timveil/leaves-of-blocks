import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimated = false
    @State private var showIcon = false
    
    var body: some View {
        ZStack {
            // Background gradient
            GameTheme.Gradients.background
                .ignoresSafeArea()
            
            // Animated background pattern
            GeometryReader { geometry in
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(GameTheme.Colors.overlayPrimary)
                        .frame(width: 200, height: 200)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .scaleEffect(isAnimated ? 1.5 : 0.5)
                        .opacity(isAnimated ? 0.1 : 0.3)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimated
                        )
                }
            }
            
            // Grass at bottom (lowest z-index)
            VStack {
                Spacer()
                BlockGrassView()
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .zIndex(0)
            
            // Content layer
            VStack(spacing: 40) {
                Spacer()
                
                // Logo area with app icon
                VStack(spacing: 24) {
                    // App Icon
                    Image("LaunchIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                        .cornerRadius(40)
                        .shadow(color: GameTheme.Colors.cardShadow, radius: 20, x: 0, y: 10)
                        .scaleEffect(showIcon ? 1.0 : 0.5)
                        .opacity(showIcon ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6)
                            .delay(0.3),
                            value: showIcon
                        )
                    
                    // App title
                    VStack(spacing: 8) {
                        Text("app_title".localized)
                            .font(GameTheme.Typography.fontXLarge)
                            .foregroundStyle(GameTheme.Gradients.text)
                            .scaleEffect(isAnimated ? 1.0 : 0.8)
                            .opacity(isAnimated ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.6)
                                .delay(0.8),
                                value: isAnimated
                            )
                        
                        Text("app_subtitle".localized)
                            .font(GameTheme.Typography.fontXXSmall)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                            .opacity(isAnimated ? 0.8 : 0.0)
                            .animation(
                                .easeOut(duration: 1.0)
                                .delay(1.2),
                                value: isAnimated
                            )
                    }
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(GameTheme.Colors.primaryAccent)
                                .frame(width: 12, height: 12)
                                .scaleEffect(isAnimated ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimated
                                )
                        }
                    }
                    
                    Text("loading".localized)
                        .font(GameTheme.Typography.fontXSmall)
                        .foregroundColor(GameTheme.Colors.tertiaryText)
                        .opacity(isAnimated ? 0.6 : 0.0)
                        .animation(
                            .easeOut(duration: 1.0)
                            .delay(1.0),
                            value: isAnimated
                        )
                }
                .padding(.bottom, 120)
            }
            .zIndex(1)
        }
        .onAppear {
            isAnimated = true
            showIcon = true
        }
    }
}

#Preview {
    LaunchScreen()
}