import SwiftUI

extension GameTheme {
    struct Animations {
        static let springAnimation: Animation = .spring(response: 0.15, dampingFraction: 0.7)
        static let lineClearAnimation: Animation = .easeOut(duration: 0.2)
        static let fastSpring: Animation = .spring(response: 0.1, dampingFraction: 0.6)
        static let mediumSpring: Animation = .spring(response: 0.15, dampingFraction: 0.7)
        static let smoothEase: Animation = .easeInOut(duration: 0.15)

        /// Easing applied when the acorn count / selected difficulty changes
        /// on the home screen. Slightly slower than `smoothEase` so the dim-in
        /// of unselected acorns reads clearly.
        static let difficultySelection: Animation = .easeInOut(duration: 0.2)

        /// Entrance spring for the launch-screen sticker. Bouncy on purpose;
        /// suppressed entirely when Reduce Motion is on (handled at the call
        /// site so the constant stays declarative).
        static let launchScreenEntrance: Animation = .spring(response: 0.6, dampingFraction: 0.7)

        /// Press-state brightness transition used by `PressDarkenButtonStyle`.
        /// Short and ease-out so the darken applies snappily but releases
        /// smoothly when the press ends.
        static let buttonPress: Animation = .easeOut(duration: 0.08)
    }
}
