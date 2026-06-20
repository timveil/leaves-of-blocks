import SpriteKit
import Observation

// MARK: - Game Scene

/// The main SpriteKit scene that renders the game grid and blocks.
///
/// `GameScene` observes `GameState` via the Observation framework and renders the
/// 8x8 grid using SpriteKit nodes. It serves as the rendering layer while all game
/// logic remains in `GameLogic` and state management stays in `GameState`.
///
/// ## Architecture
/// - Tracks `GameState.grid` via `withObservationTracking` re-registration
/// - Uses a dirty flag pattern to only re-render when the model changes
/// - Delegates all game logic to the existing `GameLogic`/`GameState` system
/// - Triggers visual effects (placement pop, line-clear particles, combo pulse)
///
/// ## Coordinate System
/// The scene uses a top-left origin (Y increases downward) to match SwiftUI layout.
/// The grid is positioned with padding matching `GameTheme.Layout.mediumPadding`.
@MainActor
class GameScene: SKScene {

    // MARK: - Properties

    /// Reference to the shared game state (not owned)
    private weak var gameState: GameState?

    /// The grid rendering node
    private let gridNode: GridNode

    /// Cell size in points
    private let cellSize: CGFloat

    /// Grid spacing in points (matches gridLineWidth)
    private let gridSpacing: CGFloat = GameTheme.Layout.gridLineWidth

    /// Grid border width in points
    private let gridBorderWidth: CGFloat = GameTheme.Layout.gridBorderWidth

    /// Whether grid observation is active. Set to false on scene teardown to stop re-registering.
    private var observationActive = false

    /// Dirty flag to avoid unnecessary re-renders
    private var needsGridSync = true

    /// Previous grid state hash for change detection
    private var lastGridHash: Int = 0

    /// Snapshot of the last observed game-over state. Used by the shared
    /// observation loop to detect `isGameOver` transitions independently of
    /// grid mutations.
    private var lastObservedGameOver: Bool = false

    /// Ghost block node shown during drag (rendered in SpriteKit for visual consistency)
    private var ghostBlockNode: BlockNode?

    /// Tracks the last ghost block identity to avoid recreating on every drag move
    private var lastGhostBlockId: String?

    /// Pending high-score celebration dispatched after the game-over overlay
    /// settles. Held so an undo flipping `isGameOver` back to false (within
    /// the 0.5s pre-celebration window) can cancel it before the burst fires
    /// on an already-cleared overlay.
    private var highScoreCelebrationTask: Task<Void, Never>?

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
        self.gridNode = GridNode(cellSize: cellSize, spacing: gridSpacing, gridSize: AppConfiguration.GameRules.gridSize)
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
        observationActive = true
        lastObservedGameOver = gameState?.isGameOver ?? false
        observeGameState()
        syncGridFromModel()
    }

    override func willMove(from view: SKView) {
        observationActive = false
        ghostBlockNode?.removeFromParent()
        ghostBlockNode = nil
        super.willMove(from: view)
    }

    // MARK: - Setup

    /// Positions the grid node within the scene.
    private func setupGrid() {
        gridNode.position = .zero
        gridNode.zPosition = 0
        addChild(gridNode)
    }

    /// Tracks `GameState.grid` and `GameState.isGameOver` mutations.
    ///
    /// `withObservationTracking` fires its `onChange` block exactly once per
    /// registration, so we re-register inside the dispatched task to keep
    /// observing for further changes until the scene is torn down
    /// (`observationActive == false`). A single combined loop replaces what
    /// used to be a separate observation in `GameSceneBridge`.
    private func observeGameState() {
        guard observationActive, let gameState = gameState else { return }

        withObservationTracking { [weak self] in
            _ = self?.gameState?.grid
            _ = self?.gameState?.isGameOver
            _ = gameState // capture to keep tracking valid even if `self` is briefly nil
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.needsGridSync = true

                let currentGameOver = self.gameState?.isGameOver ?? false
                if currentGameOver != self.lastObservedGameOver {
                    self.lastObservedGameOver = currentGameOver
                    self.handleGameOverChange(isGameOver: currentGameOver)
                }

                self.observeGameState()
            }
        }
    }

    /// Dispatches the appropriate scene effect when `isGameOver` transitions.
    /// Pulled out of `GameSceneBridge` so the scene owns its own response to
    /// state changes instead of being driven from the SwiftUI bridge.
    private func handleGameOverChange(isGameOver: Bool) {
        if isGameOver {
            playGameOverEffect()
            if gameState?.isNewHighScore == true {
                highScoreCelebrationTask?.cancel()
                highScoreCelebrationTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !Task.isCancelled else { return }
                    self?.playHighScoreCelebration()
                }
            }
        } else {
            clearGameOverEffects()
        }
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

        let currentHash = computeGridHash(gameState.grid)
        guard currentHash != lastGridHash else { return }
        lastGridHash = currentHash

        gridNode.syncGrid(gameState.grid)
    }

    /// Computes a lightweight hash of the grid state for change detection.
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

        // Sync grid to clean state
        gridNode.syncGrid(gameState.grid)

        // Update ghost block
        updateGhostBlock(block: block, position: position)

        // Overlay preview highlighting
        guard let block = block, let position = position else { return }

        let canPlace = gameState.canPlaceBlock(block, at: position)
        gridNode.showPreview(block: block, at: position, canPlace: canPlace)

        if canPlace {
            let preview = GameLogic.linesThatWouldClear(placing: block, at: position, in: gameState.grid)
            if !preview.rows.isEmpty || !preview.cols.isEmpty {
                gridNode.showLineClearPreview(rows: preview.rows, cols: preview.cols)
            }
        }
    }

    // MARK: - Ghost Block (Drag Preview in Scene)

    /// Shows or hides a semi-transparent ghost of the dragged block at the preview position.
    ///
    /// The ghost block renders directly in the SpriteKit scene at the snapped grid
    /// position, giving the player a clear view of exactly where the block will land.
    ///
    /// - Parameters:
    ///   - block: The block being dragged, or `nil` to remove the ghost
    ///   - position: The grid position to show the ghost at, or `nil` to remove
    private func updateGhostBlock(block: BlockShape?, position: GridPosition?) {
        guard let block = block, let position = position,
              let gameState = gameState,
              gameState.canPlaceBlock(block, at: position) else {
            ghostBlockNode?.removeFromParent()
            ghostBlockNode = nil
            lastGhostBlockId = nil
            return
        }

        // Reuse existing ghost if same block at same position
        let ghostId = "\(block.positions.count)-\(block.color.hashValue)-\(position.row)-\(position.col)"
        if ghostId == lastGhostBlockId, ghostBlockNode?.parent != nil {
            return
        }

        ghostBlockNode?.removeFromParent()
        lastGhostBlockId = ghostId

        let ghost = BlockNode(block: block, cellSize: cellSize, spacing: gridSpacing)
        ghost.alpha = 0.4
        ghost.zPosition = 3

        let cellPos = gridNode.cellPosition(row: position.row, col: position.col)
        ghost.position = cellPos

        gridNode.contentNode.addChild(ghost)
        ghostBlockNode = ghost

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.4),
            SKAction.fadeAlpha(to: 0.3, duration: 0.4)
        ])
        ghost.run(SKAction.repeatForever(pulse))
    }

    // MARK: - Visual Effects

    /// Plays the block placement pop animation on the grid.
    ///
    /// Called by `GameSceneBridge` after a block is successfully placed.
    ///
    /// - Parameters:
    ///   - block: The block that was placed
    ///   - position: The grid position where it was placed
    func playBlockPlacementEffect(block: BlockShape, at position: GridPosition) {
        // Force grid sync first so cells show the placed block
        lastGridHash = 0
        syncGridFromModel()

        BlockPlacementEffect.play(
            block: block,
            at: position,
            in: gridNode.contentNode,
            cellSize: cellSize,
            spacing: gridSpacing
        )
    }

    /// Plays the line-clear sparkle and flash effect.
    ///
    /// Called by `GameSceneBridge` after lines are cleared.
    ///
    /// - Parameters:
    ///   - rows: Set of row indices that were cleared
    ///   - cols: Set of column indices that were cleared
    func playLineClearEffect(clearedRows rows: Set<Int>, clearedCols cols: Set<Int>) {
        let totalLines = rows.count + cols.count
        guard totalLines > 0 else { return }

        LineClearEffect.play(
            clearedRows: rows,
            clearedCols: cols,
            in: gridNode.contentNode,
            cellSize: cellSize,
            spacing: gridSpacing,
            gridSize: AppConfiguration.GameRules.gridSize
        )

        ComboPulseEffect.play(
            comboCount: totalLines,
            gridWidth: gridNode.gridWidth,
            in: gridNode.contentNode
        )

        if totalLines >= 2 {
            ComboBannerEffect.play(comboCount: totalLines, gridNode: gridNode)
        }

        // Force grid sync after effects start to show cleared state
        lastGridHash = 0
        needsGridSync = true
    }

    // MARK: - Hint Overlay

    /// Renders a pulsing hint overlay on the cells affected by the supplied
    /// `Hint`. Auto-fades after ~2 seconds; the rendering lives in
    /// `GridNode.showHintCells(_:)`.
    func showHint(_ hint: GameLogic.Hint) {
        gridNode.showHintCells(hint.highlightedCells)
    }

    /// Clears any active hint overlay immediately.
    func clearHint() {
        gridNode.clearHint()
    }

    // MARK: - Game Over Effects

    /// Plays the game-over grid sweep effect.
    ///
    /// Cascades a desaturated overlay across each row.
    func playGameOverEffect() {
        GameOverEffect.playGameOver(
            in: gridNode.contentNode,
            cellSize: cellSize,
            spacing: gridSpacing,
            gridSize: AppConfiguration.GameRules.gridSize
        )
    }

    /// Plays the new-high-score celebration burst.
    ///
    /// Golden firework sparkles and expanding rings radiate from the grid center.
    func playHighScoreCelebration() {
        GameOverEffect.playHighScoreCelebration(
            gridWidth: gridNode.gridWidth,
            in: gridNode.contentNode
        )
    }

    /// Clears game-over overlays (e.g., on new game).
    func clearGameOverEffects() {
        highScoreCelebrationTask?.cancel()
        highScoreCelebrationTask = nil
        GameOverEffect.clearGameOver(in: gridNode.contentNode)
    }

    // MARK: - Background / Foreground

    /// Stops the SpriteKit render loop to shrink the suspended-app memory
    /// footprint. Called when the app enters background.
    func suspendForBackground() {
        ghostBlockNode?.removeFromParent()
        ghostBlockNode = nil
        lastGhostBlockId = nil

        isPaused = true
        view?.isPaused = true
    }

    /// Restarts the render loop on return to foreground.
    func resumeFromBackground() {
        view?.isPaused = false
        isPaused = false
        // Force a grid re-render in case state mutated while suspended.
        lastGridHash = 0
        needsGridSync = true
    }

    // MARK: - Scene Sizing

    /// Calculates the required scene size for the grid including border.
    static func sceneSize(cellSize: CGFloat = 40, gridSize: Int = 8) -> CGSize {
        let spacing = GameTheme.Layout.gridLineWidth
        let border = GameTheme.Layout.gridBorderWidth
        let gridDimension = CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * spacing
        let total = gridDimension + border * 2
        return CGSize(width: total, height: total)
    }
}
