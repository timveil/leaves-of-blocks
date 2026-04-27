import Foundation
import Combine

// MARK: - Game Scene Bridge

/// Bridges communication between the SwiftUI view layer and the SpriteKit `GameScene`.
///
/// `GameSceneBridge` is an `ObservableObject` that coordinates state updates between
/// `GameState` (the model), SwiftUI views (navigation, overlays), and `GameScene`
/// (the SpriteKit renderer). It forwards drag previews and triggers visual effects
/// for block placement, line clearing, and combo events.
///
/// ## Architecture
/// ```
/// SwiftUI Views  <-->  GameSceneBridge  <-->  GameScene
///                           |                    |
///                       GameState           Effects Layer
/// ```
class GameSceneBridge: ObservableObject {

    // MARK: - Properties

    /// The SpriteKit scene managed by this bridge
    let scene: GameScene

    /// Reference to the game state
    private let gameState: GameState

    /// Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Preview State

    /// The block currently being dragged (set by SwiftUI drag handlers)
    @Published var previewBlock: BlockShape?

    /// The grid position for the current preview (set by SwiftUI drag handlers)
    @Published var previewPosition: GridPosition?

    // MARK: - Initialization

    /// Creates a new bridge connecting the game state to a SpriteKit scene.
    ///
    /// - Parameters:
    ///   - gameState: The shared `GameState` instance
    ///   - cellSize: Cell size for the scene (default: 40)
    init(gameState: GameState, cellSize: CGFloat = 40) {
        self.gameState = gameState
        let sceneSize = GameScene.sceneSize(cellSize: cellSize)
        self.scene = GameScene(gameState: gameState, size: sceneSize, cellSize: cellSize)
        subscribeToPreviewChanges()
        subscribeToGameOverState()
    }

    // MARK: - Subscriptions

    /// Subscribes to preview state changes and forwards them to the scene.
    private func subscribeToPreviewChanges() {
        Publishers.CombineLatest($previewBlock, $previewPosition)
            .receive(on: RunLoop.main)
            .sink { [weak self] block, position in
                self?.scene.updatePreview(block: block, position: position)
            }
            .store(in: &cancellables)
    }

    /// Subscribes to game-over state changes for automatic effect triggering.
    private func subscribeToGameOverState() {
        gameState.$isGameOver
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isGameOver in
                guard let self else { return }
                if isGameOver {
                    self.scene.playGameOverEffect()
                    if self.gameState.isNewHighScore {
                        Task { @MainActor [weak self] in
                            try? await Task.sleep(for: .seconds(0.5))
                            self?.scene.playHighScoreCelebration()
                        }
                    }
                } else {
                    self.scene.clearGameOverEffects()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Preview Control

    /// Updates the preview state during drag operations.
    ///
    /// - Parameters:
    ///   - block: The block being dragged, or `nil` to clear
    ///   - position: The grid position for preview, or `nil` to clear
    func updatePreview(block: BlockShape?, position: GridPosition?) {
        previewBlock = block
        previewPosition = position
    }

    /// Clears the preview state.
    func clearPreview() {
        previewBlock = nil
        previewPosition = nil
    }

    // MARK: - Effect Triggers

    /// Triggers the block placement pop animation in the SpriteKit scene.
    ///
    /// Called by `BoardView` after a block is successfully placed on the grid.
    ///
    /// - Parameters:
    ///   - block: The block that was placed
    ///   - position: The grid position where it was placed
    func triggerBlockPlacementEffect(block: BlockShape, at position: GridPosition) {
        scene.playBlockPlacementEffect(block: block, at: position)
    }

    /// Triggers the line-clear sparkle and combo pulse effects.
    ///
    /// Called by `BoardView` after lines are cleared from the grid.
    ///
    /// - Parameters:
    ///   - rows: Set of cleared row indices
    ///   - cols: Set of cleared column indices
    func triggerLineClearEffect(clearedRows rows: Set<Int>, clearedCols cols: Set<Int>) {
        scene.playLineClearEffect(clearedRows: rows, clearedCols: cols)
    }
}
