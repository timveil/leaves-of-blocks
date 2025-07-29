import SwiftUI

extension GameTheme {
    struct Animations {
        // Faster, more responsive animations
        static let springResponse: Double = 0.15
        static let springDamping: Double = 0.7
        static let fallDuration: Double = 1.0
        static let springAnimation: Animation = .spring(response: 0.15, dampingFraction: 0.7)
        
        // Line clearing specific animations
        static let lineClearAnimation: Animation = .easeOut(duration: 0.2)
        static let lineHighlightAnimation: Animation = .easeInOut(duration: 0.1)
        static let blockPlaceAnimation: Animation = .spring(response: 0.1, dampingFraction: 0.6)
        
        // Enhanced animations for different effects
        static let fastSpring: Animation = .spring(response: 0.1, dampingFraction: 0.6)
        static let mediumSpring: Animation = .spring(response: 0.15, dampingFraction: 0.7)
        static let smoothEase: Animation = .easeInOut(duration: 0.15)
    }
}