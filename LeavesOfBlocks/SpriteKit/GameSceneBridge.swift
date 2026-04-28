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

    /// Snapshot of the last observed game-over state, used to dedupe re-registrations.
    @ObservationIgnored private var lastObservedGameOver: Bool

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
        self.lastObservedGameOver = gameState.isGameOver
        observeGameOverState()
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

    // MARK: - Game-Over Observation

    /// Observes `gameState.isGameOver` and triggers scene effects when it changes.
    ///
    /// `withObservationTracking` fires its `onChange` block exactly once per registration,
    /// so we re-register inside the dispatched task to keep observing for further changes.
    private func observeGameOverState() {
        withObservationTracking { [weak self] in
            _ = self?.gameState.isGameOver
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let isGameOver = self.gameState.isGameOver
                if isGameOver != self.lastObservedGameOver {
                    self.lastObservedGameOver = isGameOver
                    self.handleGameOverChange(isGameOver: isGameOver)
                }
                self.observeGameOverState()
            }
        }
    }

    private func handleGameOverChange(isGameOver: Bool) {
        if isGameOver {
            scene.playGameOverEffect()
            if gameState.isNewHighScore {
                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(0.5))
                    self?.scene.playHighScoreCelebration()
                }
            }
        } else {
            scene.clearGameOverEffects()
        }
    }
}
