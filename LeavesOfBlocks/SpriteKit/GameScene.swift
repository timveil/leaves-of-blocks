import SpriteKit
import Combine

// MARK: - Game Scene

/// The main SpriteKit scene that renders the game grid and blocks.
///
/// `GameScene` observes `GameState` via Combine and renders the 8x8 grid using
/// SpriteKit nodes. It serves as the rendering layer while all game logic remains
/// in `GameLogic` and state management stays in `GameState`.
///
/// ## Architecture
/// - Subscribes to `GameState.objectWillChange` to detect state changes
/// - Uses a dirty flag pattern to only re-render when the model changes
/// - Delegates all game logic to the existing `GameLogic`/`GameState` system
///
/// ## Coordinate System
/// The scene uses a top-left origin (Y increases downward) to match SwiftUI layout.
/// The grid is positioned with padding matching `GameTheme.Layout.mediumPadding`.
///
/// ## Usage
/// ```swift
/// let scene = GameScene(gameState: gameState, size: CGSize(width: 373, height: 373))
/// ```
class GameScene: SKScene {

    // MARK: - Properties

    /// Reference to the shared game state (not owned)
    private weak var gameState: GameState?

    /// The grid rendering node
    private let gridNode: GridNode

    /// Cell size in points
    private let cellSize: CGFloat

    /// Grid spacing in points
    private let gridSpacing: CGFloat = 3

    /// Grid padding in points
    private let gridPadding: CGFloat = 16

    /// Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Dirty flag to avoid unnecessary re-renders
    private var needsGridSync = true

    /// Previous grid state hash for change detection
    private var lastGridHash: Int = 0

    // MARK: - Initialization

    /// Creates a new game scene bound to the given game state.
    ///
    /// - Parameters:
    ///   - gameState: The shared `GameState` to observe and render
    ///   - size: The scene size in points
    ///   - cellSize: Size of each grid cell (default: 40)
    init(gameState: GameState, size: CGSize, cellSize: CGFloat = 40) {
        self.gameState = gameState
        self.cellSize = cellSize
        self.gridNode = GridNode(cellSize: cellSize, spacing: gridSpacing, gridSize: GameTheme.GameConfig.gridSize)
        super.init(size: size)
        self.scaleMode = .resizeFill
        self.backgroundColor = SpriteKitColors.sceneBackground
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        setupGrid()
        subscribeToGameState()
        syncGridFromModel()
    }

    // MARK: - Setup

    /// Positions the grid node within the scene.
    private func setupGrid() {
        // Position grid with padding from the top-left
        gridNode.position = CGPoint(x: gridPadding, y: gridPadding)
        gridNode.zPosition = 0
        addChild(gridNode)
    }

    /// Subscribes to `GameState` changes via Combine.
    private func subscribeToGameState() {
        guard let gameState = gameState else { return }

        // Subscribe to any published property change
        gameState.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.needsGridSync = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        if needsGridSync {
            needsGridSync = false
            syncGridFromModel()
        }
    }

    // MARK: - Grid Synchronization

    /// Syncs the SpriteKit grid with the current `GameState` grid.
    private func syncGridFromModel() {
        guard let gameState = gameState else { return }

        // Compute a simple hash to detect actual changes
        let currentHash = computeGridHash(gameState.grid)
        guard currentHash != lastGridHash else { return }
        lastGridHash = currentHash

        gridNode.syncGrid(gameState.grid)
    }

    /// Computes a lightweight hash of the grid state for change detection.
    ///
    /// - Parameter grid: The 2D grid array
    /// - Returns: An integer hash value
    private func computeGridHash(_ grid: [[GridCell]]) -> Int {
        var hasher = Hasher()
        for row in grid {
            for cell in row {
                hasher.combine(cell.isFilled)
                if cell.isFilled {
                    hasher.combine(cell.color)
                }
            }
        }
        return hasher.finalize()
    }

    // MARK: - Preview Support

    /// Shows a placement preview for the given block at the specified position.
    ///
    /// Called by `GameSceneBridge` when the drag state changes. First restores the
    /// grid to model state, then overlays the preview highlighting.
    ///
    /// - Parameters:
    ///   - block: The block being previewed, or `nil` to clear
    ///   - position: The grid position for the preview, or `nil` to clear
    func updatePreview(block: BlockShape?, position: GridPosition?) {
        guard let gameState = gameState else { return }

        // First, sync grid to clean state
        gridNode.syncGrid(gameState.grid)

        // Then overlay preview if applicable
        guard let block = block, let position = position else { return }

        let canPlace = gameState.canPlaceBlock(block, at: position)
        gridNode.showPreview(block: block, at: position, canPlace: canPlace)
    }

    // MARK: - Scene Sizing

    /// Calculates the required scene size for the grid with padding.
    ///
    /// - Parameters:
    ///   - cellSize: The cell size in points
    ///   - gridSize: Number of rows/columns
    /// - Returns: The scene size needed to contain the grid
    static func sceneSize(cellSize: CGFloat = 40, gridSize: Int = 8) -> CGSize {
        let spacing: CGFloat = 3
        let padding: CGFloat = 16
        let gridDimension = CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * spacing
        let total = gridDimension + padding * 2
        return CGSize(width: total, height: total)
    }
}
