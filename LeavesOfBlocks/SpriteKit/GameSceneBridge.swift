import Foundation
import Observation

// MARK: - Game Scene Bridge

/// Bridges communication between the SwiftUI view layer and the SpriteKit `GameScene`.
///
/// `GameSceneBridge` coordinates state updates between `GameState` (the model),
/// SwiftUI views (navigation, overlays), and `GameScene` (the SpriteKit renderer).
/// It forwards drag previews and triggers visual effects for block placement,
/// line clearing, and combo events.
///
/// ## Architecture
/// ```
/// SwiftUI Views  <-->  GameSceneBridge  <-->  GameScene
///                           |                    |
///                       GameState           Effects Layer
/// ```
@MainActor
@Observable
final class GameSceneBridge {

    // MARK: - Properties

    /// The SpriteKit scene managed by this bridge.
    let scene: GameScene

    /// Reference to the game state.
    @ObservationIgnored private let gameState: GameState

    // MARK: - Preview State

    /// The block currently being dragged (set by SwiftUI drag handlers).
    var previewBlock: BlockShape?

    /// The grid position for the current preview (set by SwiftUI drag handlers).
    var previewPosition: GridPosition?

    // MARK: - Initialization

    /// Creates a new bridge connecting the game state to a SpriteKit scene.
    ///
    /// - Parameters:
    ///   - gameState: The shared `GameState` instance.
    ///   - cellSize: Cell size for the scene (default: 40).
    init(gameState: GameState, cellSize: CGFloat = 40) {
        self.gameState = gameState
        let sceneSize = GameScene.sceneSize(cellSize: cellSize)
        self.scene = GameScene(gameState: gameState, size: sceneSize, cellSize: cellSize)
    }

    // MARK: - Preview Control

    /// Updates the preview state during drag operations and forwards it to the scene.
    ///
    /// - Parameters:
    ///   - block: The block being dragged, or `nil` to clear.
    ///   - position: The grid position for preview, or `nil` to clear.
    func updatePreview(block: BlockShape?, position: GridPosition?) {
        previewBlock = block
        previewPosition = position
        scene.updatePreview(block: block, position: position)
    }

    /// Clears the preview state.
    func clearPreview() {
        updatePreview(block: nil, position: nil)
    }

    // MARK: - Effect Triggers

    /// Triggers the block placement pop animation in the SpriteKit scene.
    ///
    /// Called by `BoardView` after a block is successfully placed on the grid.
    ///
    /// - Parameters:
    ///   - block: The block that was placed.
    ///   - position: The grid position where it was placed.
    func triggerBlockPlacementEffect(block: BlockShape, at position: GridPosition) {
        scene.playBlockPlacementEffect(block: block, at: position)
    }

    /// Triggers the line-clear sparkle and combo pulse effects.
    ///
    /// Called by `BoardView` after lines are cleared from the grid.
    ///
    /// - Parameters:
    ///   - rows: Set of cleared row indices.
    ///   - cols: Set of cleared column indices.
    func triggerLineClearEffect(clearedRows rows: Set<Int>, clearedCols cols: Set<Int>) {
        scene.playLineClearEffect(clearedRows: rows, clearedCols: cols)
    }

    // MARK: - Hint Overlay

    /// Renders a pulsing hint overlay on the cells the supplied `Hint` would
    /// affect. Implementation lands in `GridNode.showHintCells(_:)` (Step 7);
    /// for Step 6 this is a stub that just logs.
    func showHint(_ hint: GameLogic.Hint) {
        scene.showHint(hint)
    }

    /// Clears any active hint overlay. Called when the player starts a drag or
    /// when undo is used (the hint may have referenced now-invalid state).
    func clearHint() {
        scene.clearHint()
    }

    // MARK: - Background / Foreground

    /// Pauses the SpriteKit scene so the suspended app holds less GPU/CPU
    /// state and is a less attractive jetsam target.
    func suspendForBackground() {
        scene.suspendForBackground()
    }

    /// Resumes the SpriteKit scene when the app returns to the foreground.
    func resumeFromBackground() {
        scene.resumeFromBackground()
    }
}
