import UIKit

extension UIAccessibility {
    /// `true` if the user has enabled "Reduce Motion" in iOS Settings, or if
    /// any of the related preferences ("Prefer Cross-Fade Transitions") is on.
    ///
    /// Used to gate non-essential SpriteKit particle effects and SwiftUI
    /// animations. SwiftUI views should prefer `@Environment(\.accessibilityReduceMotion)`.
    static var prefersReducedMotion: Bool {
        isReduceMotionEnabled
    }
}
