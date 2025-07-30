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
    @State private var grassImage: UIImage?
    
    private let grassColors: [Color] = [
        Color(red: 0.15, green: 0.6, blue: 0.05),   // Dark green
        Color(red: 0.25, green: 0.7, blue: 0.15),   // Medium green
        Color(red: 0.2, green: 0.65, blue: 0.1),    // Forest green
        Color(red: 0.3, green: 0.75, blue: 0.2),    // Light green
        Color(red: 0.18, green: 0.62, blue: 0.08),  // Deep green
        Color(red: 0.22, green: 0.68, blue: 0.12),  // Pine green
        Color(red: 0.28, green: 0.73, blue: 0.18),  // Spring green
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Static grass image
                if let grassImage = grassImage {
                    Image(uiImage: grassImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: min(100, geometry.size.height * 0.3))
                        .clipped()
                } else {
                    // Fallback simple gradient while image loads
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.65, blue: 0.1),
                                    Color(red: 0.15, green: 0.55, blue: 0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 80)
                }
                
                // Ground base
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
            }
        }
        .onAppear {
            if grassImage == nil {
                generateGrassImage()
            }
        }
    }
    
    private func generateGrassImage() {
        DispatchQueue.global(qos: .background).async {
            let screenWidth = UIScreen.main.bounds.width
            let blockSize: CGFloat = 12
            let grassHeight: CGFloat = 80
            let columnCount = Int(screenWidth / (blockSize + 2))
            
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: screenWidth, height: grassHeight))
            
            let image = renderer.image { context in
                let cgContext = context.cgContext
                
                // Clear background
                cgContext.setFillColor(UIColor.clear.cgColor)
                cgContext.fill(CGRect(x: 0, y: 0, width: screenWidth, height: grassHeight))
                
                // Draw grass columns
                for col in 0..<columnCount {
                    let x = CGFloat(col) * (blockSize + 2)
                    let columnHeight = getColumnHeight(for: col)
                    
                    for blockIndex in 0..<columnHeight {
                        let y = grassHeight - CGFloat(blockIndex + 1) * (blockSize + 1)
                        let colorIndex = seededRandom(col: col, blockIndex: blockIndex) % grassColors.count
                        let color = UIColor(grassColors[colorIndex])
                        
                        // Draw grass block with gradient effect
                        let blockRect = CGRect(x: x, y: y, width: blockSize, height: blockSize)
                        
                        // Create gradient for each block
                        let colors = [color, color.withAlphaComponent(0.6)]
                        let colorSpace = CGColorSpaceCreateDeviceRGB()
                        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors.map { $0.cgColor } as CFArray, locations: [0, 1])!
                        
                        cgContext.saveGState()
                        
                        // Create rounded rectangle path
                        let path = UIBezierPath(roundedRect: blockRect, cornerRadius: 2)
                        cgContext.addPath(path.cgPath)
                        cgContext.clip()
                        cgContext.drawLinearGradient(gradient, start: blockRect.origin, end: CGPoint(x: blockRect.maxX, y: blockRect.maxY), options: [])
                        cgContext.restoreGState()
                        
                        // Add border
                        cgContext.setStrokeColor(color.withAlphaComponent(0.4).cgColor)
                        cgContext.setLineWidth(1)
                        cgContext.addPath(path.cgPath)
                        cgContext.strokePath()
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.grassImage = image
            }
        }
    }
    
    // Get deterministic column height
    private func getColumnHeight(for col: Int) -> Int {
        let seed = col * 7919
        let random = ((seed * 9301 + 49297) % 233280) / 50000
        return min(4, max(2, random + 2))
    }
    
    // Deterministic random for consistent block colors
    private func seededRandom(col: Int, blockIndex: Int) -> Int {
        let seed = col * 1000 + blockIndex * 100
        return ((seed * 9301 + 49297) % 233280) / 1000
    }
}

