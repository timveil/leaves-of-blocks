import Foundation
import Combine

// MARK: - Game Scene Bridge

/// Bridges communication between the SwiftUI view layer and the SpriteKit `GameScene`.
///
/// `GameSceneBridge` is an `ObservableObject` that coordinates state updates between
/// `GameState` (the model), SwiftUI views (navigation, overlays), and `GameScene`
/// (the SpriteKit renderer). It subscribes to relevant `GameState` properties and
/// forwards rendering-relevant changes to the scene.
///
/// ## Architecture
/// ```
/// SwiftUI Views  <-->  GameSceneBridge  <-->  GameScene
///                           |
///                       GameState
/// ```
///
/// ## Usage
/// ```swift
/// let bridge = GameSceneBridge(gameState: gameState)
/// bridge.scene  // Pass to SpriteView
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
    }

    // MARK: - Subscriptions

    /// Subscribes to preview state changes and forwards them to the scene.
    private func subscribeToPreviewChanges() {
        // Combine previewBlock and previewPosition into a single stream
        Publishers.CombineLatest($previewBlock, $previewPosition)
            .receive(on: RunLoop.main)
            .sink { [weak self] block, position in
                self?.scene.updatePreview(block: block, position: position)
            }
            .store(in: &cancellables)
    }

    // MARK: - Preview Control

    /// Updates the preview state during drag operations.
    ///
    /// Called by the SwiftUI drag handlers in `BoardView` to show/hide
    /// the placement preview in the SpriteKit scene.
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
}
