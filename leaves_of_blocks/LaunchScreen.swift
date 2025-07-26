import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimated = false
    @State private var showBlocks = false
    @State private var rotateLeaves = false
    
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo area with blocks and leaves
                VStack(spacing: 24) {
                    // Blocks arrangement (similar to icon)
                    HStack(spacing: 12) {
                        // Orange block
                        RoundedRectangle(cornerRadius: 12)
                            .fill(GameTheme.Colors.blockOrange)
                            .frame(width: 60, height: 60)
                            .scaleEffect(showBlocks ? 1.0 : 0.1)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.6)
                                .delay(0.1),
                                value: showBlocks
                            )
                        
                        VStack(spacing: 8) {
                            // Teal block
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.3, green: 0.7, blue: 0.6))
                                .frame(width: 60, height: 60)
                                .scaleEffect(showBlocks ? 1.0 : 0.1)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.6)
                                    .delay(0.2),
                                    value: showBlocks
                                )
                            
                            // Yellow block
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GameTheme.Colors.blockYellow)
                                .frame(width: 60, height: 60)
                                .scaleEffect(showBlocks ? 1.0 : 0.1)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.6)
                                    .delay(0.0),
                                    value: showBlocks
                                )
                        }
                        
                        // Green block with leaves
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GameTheme.Colors.blockGreen)
                                .frame(width: 60, height: 60)
                                .scaleEffect(showBlocks ? 1.0 : 0.1)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.6)
                                    .delay(0.3),
                                    value: showBlocks
                                )
                            
                            // Stylized leaves
                            VStack(spacing: -8) {
                                HStack(spacing: -4) {
                                    LeafShape()
                                        .fill(GameTheme.Colors.grassSecondary)
                                        .frame(width: 16, height: 24)
                                        .rotationEffect(.degrees(rotateLeaves ? 15 : -15))
                                    
                                    LeafShape()
                                        .fill(GameTheme.Colors.grassPrimary)
                                        .frame(width: 18, height: 26)
                                        .rotationEffect(.degrees(rotateLeaves ? -10 : 10))
                                }
                                
                                LeafShape()
                                    .fill(GameTheme.Colors.grassTertiary)
                                    .frame(width: 14, height: 20)
                                    .rotationEffect(.degrees(rotateLeaves ? 5 : -5))
                            }
                            .scaleEffect(showBlocks ? 1.0 : 0.1)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.5)
                                .delay(0.5),
                                value: showBlocks
                            )
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                                value: rotateLeaves
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // App title
                    VStack(spacing: 8) {
                        Text("Leaves of Blocks")
                            .font(GameTheme.Typography.title)
                            .foregroundStyle(GameTheme.Gradients.text)
                            .scaleEffect(isAnimated ? 1.0 : 0.8)
                            .opacity(isAnimated ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.6)
                                .delay(0.8),
                                value: isAnimated
                            )
                        
                        Text("Block Puzzle Adventure")
                            .font(GameTheme.Typography.subtitleFont)
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
                    
                    Text("Loading...")
                        .font(GameTheme.Typography.captionFont)
                        .foregroundColor(GameTheme.Colors.tertiaryText)
                        .opacity(isAnimated ? 0.6 : 0.0)
                        .animation(
                            .easeOut(duration: 1.0)
                            .delay(1.0),
                            value: isAnimated
                        )
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimated = true
            showBlocks = true
            rotateLeaves = true
        }
    }
}

// Custom leaf shape
struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Start at bottom center (stem)
        path.move(to: CGPoint(x: width * 0.5, y: height))
        
        // Left curve to top
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.1),
            control: CGPoint(x: width * 0.1, y: height * 0.6)
        )
        
        // Right curve back to bottom
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: width * 0.9, y: height * 0.6)
        )
        
        return path
    }
}

#Preview {
    LaunchScreen()
}