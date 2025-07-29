import SwiftUI

// MARK: - Background Components

struct GameBackgroundView: View {
    var body: some View {
        ZStack {
            // Autumn forest background
            LinearGradient(
                colors: GameTheme.Colors.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle leaf pattern overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            GameTheme.Colors.overlayPrimary,
                            Color.clear,
                            GameTheme.Colors.overlaySecondary
                        ],
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                )
                .ignoresSafeArea()
        }
    }
}

struct BlockGrassView: View {
    let grassColors: [Color] = [
        Color(red: 0.15, green: 0.6, blue: 0.05),   // Dark green
        Color(red: 0.25, green: 0.7, blue: 0.15),   // Medium green
        Color(red: 0.2, green: 0.65, blue: 0.1),    // Forest green
        Color(red: 0.3, green: 0.75, blue: 0.2),    // Light green
        Color(red: 0.18, green: 0.62, blue: 0.08),  // Deep green
        Color(red: 0.22, green: 0.68, blue: 0.12),  // Pine green
        Color(red: 0.28, green: 0.73, blue: 0.18),  // Spring green
    ]
    
    private let blockSize: CGFloat = 12
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Create columns of varying heights that fill available space
                HStack(spacing: 1) {
                    ForEach(0..<Int(screenWidth / (blockSize + 1)), id: \.self) { col in
                        VStack(spacing: 1) {
                            Spacer()
                            // Each column has a random height between 2-5 blocks
                            let columnHeight = getColumnHeight(for: col)
                            ForEach(0..<columnHeight, id: \.self) { blockIndex in
                                StaticGrassBlockView(
                                    color: grassColors[seededRandom(col: col, blockIndex: blockIndex) % grassColors.count],
                                    size: blockSize
                                )
                            }
                        }
                    }
                }
                .frame(height: max(80, geometry.size.height - 20)) // Use available height minus ground base
                
                // Ground base that extends to bottom
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.45, blue: 0.04),
                                Color(red: 0.1, green: 0.4, blue: 0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                    .shadow(color: Color(red: 0.05, green: 0.2, blue: 0.02).opacity(0.5), radius: 4, x: 0, y: -2)
            }
        }
    }
    
    // Get deterministic column height
    private func getColumnHeight(for col: Int) -> Int {
        let seed = col * 7919
        let random = ((seed * 9301 + 49297) % 233280) / 50000
        return min(5, max(2, random + 2)) // Heights between 2-5 blocks
    }
    
    // Deterministic random for consistent block colors
    private func seededRandom(col: Int, blockIndex: Int) -> Int {
        let seed = col * 1000 + blockIndex * 100
        return ((seed * 9301 + 49297) % 233280) / 1000
    }
}

private struct StaticGrassBlockView: View {
    let color: Color
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}