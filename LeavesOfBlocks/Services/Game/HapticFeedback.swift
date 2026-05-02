import UIKit

/// Lightweight haptic helpers for UI interactions (button taps, menu
/// selections, toggle changes).
///
/// Gameplay haptics (block placement, line clears, game-over) live on
/// `GameService` because they're tied to game-state transitions. This enum is
/// for UI surface-level events that don't have a service owner — call it
/// directly from any button action.
enum HapticFeedback {
    /// Light tap, intended for primary button presses and menu item selections.
    @MainActor
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Soft "tick" for control selection changes (toggles, segmented controls).
    @MainActor
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
