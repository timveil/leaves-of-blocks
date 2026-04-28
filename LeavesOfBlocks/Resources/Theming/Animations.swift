import SwiftUI

extension GameTheme {
    struct Animations {
        static let springAnimation: Animation = .spring(response: 0.15, dampingFraction: 0.7)
        static let lineClearAnimation: Animation = .easeOut(duration: 0.2)
        static let fastSpring: Animation = .spring(response: 0.1, dampingFraction: 0.6)
        static let mediumSpring: Animation = .spring(response: 0.15, dampingFraction: 0.7)
        static let smoothEase: Animation = .easeInOut(duration: 0.15)
    }
}
