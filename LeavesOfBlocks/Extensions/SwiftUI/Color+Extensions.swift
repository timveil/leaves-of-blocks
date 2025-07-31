import SwiftUI

extension Color {
    
    // MARK: - Game Colors
    
    static let gameBackground = GameTheme.Colors.primaryBackground
    static let gameAccent = GameTheme.Colors.primaryAccent
    static let gameText = GameTheme.Colors.primaryText
    static let gameSuccess = GameTheme.Colors.success
    static let gameWarning = GameTheme.Colors.warning
    static let gameError = GameTheme.Colors.error
    
    // MARK: - Hex Color Support
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Color Variations
    
    /// Creates a lighter version of the color by increasing brightness
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        let clampedPercentage = max(0, min(1, percentage))
        
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0  
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Increase brightness while maintaining hue and saturation
        let newBrightness = min(1.0, brightness + (1.0 - brightness) * clampedPercentage)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
        #else
        // Fallback for non-UIKit platforms (macOS)
        let nsColor = NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newBrightness = min(1.0, brightness + (1.0 - brightness) * clampedPercentage)
        
        return Color(NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
        #endif
    }
    
    /// Creates a darker version of the color by decreasing brightness
    func darker(by percentage: CGFloat = 0.2) -> Color {
        let clampedPercentage = max(0, min(1, percentage))
        
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Decrease brightness while maintaining hue and saturation
        let newBrightness = max(0.0, brightness * (1.0 - clampedPercentage))
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
        #else
        // Fallback for non-UIKit platforms (macOS)
        let nsColor = NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newBrightness = max(0.0, brightness * (1.0 - clampedPercentage))
        
        return Color(NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
        #endif
    }
}