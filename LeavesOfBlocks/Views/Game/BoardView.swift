import SwiftUI
import SpriteKit

// MARK: - Main Game Board

struct BoardView: View {
    var gameState: GameState
    @State private var dragState: DragState = DragState()
    @State private var gridFrame: CGRect = .zero
    @State private var blockSlotsFrame: CGRect = .zero
    @State private var viewBounds: CGRect = .zero
    /// When true at game-over, the results overlay is hidden so the player can
    /// inspect the final board (grid + unplaceable blocks). See issue #36.
    @State private var isPeekingBoard: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    /// Bridge for SpriteKit scene communication.
    ///
    /// Created eagerly in `init` (rather than lazily in `onAppear`) so the
    /// `SpriteKitGameView` is in the view tree on the very first body
    /// evaluation. The lazy variant relied on `onAppear` → state mutation
    /// → re-render to mount the scene, and on slow cold simulators (CI
    /// macos-15-arm64 runners on iOS 26.5) that follow-up render never
    /// landed inside the test's wait window — `testDifficultySelection`
    /// failed in run 26006753276 because `spritekit_game_grid` never
    /// appeared in 20s of polling.
    @State private var sceneBridge: GameSceneBridge

    init(gameState: GameState, onViewSummary: @escaping () -> Void, onNewGame: @escaping () -> Void) {
        self.gameState = gameState
        self.onViewSummary = onViewSummary
        self.onNewGame = onNewGame
        self._sceneBridge = State(
            initialValue: GameSceneBridge(gameState: gameState, cellSize: GameTheme.Layout.cellSize)
        )
    }
    
    // MARK: - Configuration
    private struct DragConfiguration {
        static let offsetAboveFinger: CGFloat = 40
        static let offScreenMargin: CGFloat = 100
        static let hoverTolerance: CGFloat = 15
        static let maxSnapDistance: CGFloat = 300
    }
    
    private struct GridConstants {
        static let cellSpacing: CGFloat = GameTheme.Layout.gridLineWidth
        static let gridPadding: CGFloat = GameTheme.Layout.gridBorderWidth

        static func cellWithSpacing(cellSize: CGFloat) -> CGFloat {
            return cellSize + cellSpacing
        }
    }
    
    // MARK: - Drag State
    private struct DragState {
        var draggedBlock: BlockShape?
        var draggedBlockIndex: Int?
        var isDragging: Bool = false
        var dragLocation: CGPoint = .zero
        var dragOffset: CGSize = .zero
        var previewPosition: GridPosition?
        var isHoveringOverOrigin: Bool = false
        
        mutating func reset() {
            draggedBlock = nil
            draggedBlockIndex = nil
            isDragging = false
            previewPosition = nil
            isHoveringOverOrigin = false
        }
    }
    
    let cellSize: CGFloat = GameTheme.Layout.cellSize
    let onViewSummary: () -> Void
    let onNewGame: () -> Void

    // Computed property - simple calculation, no need for lazy loading in SwiftUI
    private var gameWidth: CGFloat {
        let gridSize = CGFloat(AppConfiguration.GameRules.gridSize)
        return (gridSize * cellSize) + ((gridSize - 1) * GridConstants.cellSpacing) + (2 * GridConstants.gridPadding)
    }
    
    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            ZStack {
                // Score, assist bar, and grid sit ~20pt apart so the thin
                // assist bar reads as part of one compact top cluster instead
                // of floating with the full 44pt section gaps. The 44pt gap is
                // restored above the holding area below (see its `.padding`).
                VStack(spacing: 20) {
                    // Score Row
                    HStack {
                        Spacer()
                        SimpleScoreView(gameState: gameState)
                            .frame(width: gameWidth)
                        Spacer()
                    }

                    // Assist Bar Row (Undo + Hint)
                    HStack {
                        Spacer()
                        assistBar
                            .frame(width: gameWidth)
                        Spacer()
                    }

                    // Grid Row
                    HStack {
                        Spacer()
                        SpriteKitGameView(bridge: sceneBridge)
                            .frame(width: gameWidth, height: gameWidth)
                            .onGeometryChange(for: CGRect.self) { proxy in
                                proxy.frame(in: .global)
                            } action: { newValue in
                                gridFrame = newValue
                            }
                        Spacer()
                    }
                    
                    // Holding Area Row
                    HStack {
                        Spacer()
                        CurrentBlocksView(
                        gameState: gameState,
                        cellSize: cellSize,
                        draggedBlock: dragState.draggedBlock,
                        isDragging: dragState.isDragging,
                        draggedBlockIndex: dragState.draggedBlockIndex,
                        isHoveringOverOrigin: dragState.isHoveringOverOrigin,
                        onDragStart: { block, index, location in
                            handleDragStart(block: block, index: index, fingerLocation: location)
                        },
                        onDragMove: { location in
                            handleDragMove(fingerLocation: location)
                        },
                        onDragEnd: {
                            handleDragEnd()
                        }
                        )
                        .frame(width: gameWidth)
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .global)
                        } action: { newValue in
                            blockSlotsFrame = newValue
                        }
                        Spacer()
                    }
                    // Restore the full gap (20 stack spacing + 24) between the
                    // grid cluster above and the holding area.
                    .padding(.top, GameTheme.Layout.largePadding)

                    Spacer(minLength: 20) // Leave space for grass
                }
                .zIndex(10) // Game elements above grass
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.top, GameTheme.Layout.mediumPadding)
            
                gameOverOverlay
                peekBoardOverlay
                draggedBlockOverlay
            }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { newValue in
            viewBounds = newValue
        }
        .onChange(of: gameState.isGameOver) { _, isOver in
            // Leaving game-over (new game, or undo of the fatal move) ends any
            // board peek so the next game-over shows its results overlay.
            if !isOver { isPeekingBoard = false }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // SwiftUI doesn't reliably deliver DragGesture.onEnded when the app
            // is backgrounded mid-drag. Without this reset, the dragged-block
            // overlay can stay rendered at zIndex 1000 on return, masking taps.
            if newPhase != .active {
                dragState.reset()
                sceneBridge.clearPreview()
                // Pause SpriteKit so the suspended app drops GPU/CPU state and
                // is a less attractive jetsam target. Both reports we have were
                // jetsam kills while suspended at ~70-90 MB resident.
                sceneBridge.suspendForBackground()
            } else {
                sceneBridge.resumeFromBackground()
            }
        }
    }

    // MARK: - Assist Bar

    @ViewBuilder
    private var assistBar: some View {
        HStack(spacing: GameTheme.Layout.largePadding) {
            Spacer()
            CircularIconButton(
                icon: "arrow.uturn.backward",
                accessibilityLabel: gameState.canUndo
                    ? "ax_undo_available".localized
                    : "ax_undo_used".localized,
                color: gameState.canUndo
                    ? GameTheme.Colors.primaryAccent
                    : GameTheme.Colors.tertiaryText,
                size: 48,
                iconSize: 22,
                action: {
                    gameState.undoLastPlacement()
                    sceneBridge.clearHint()
                }
            )
            .disabled(!gameState.canUndo)

            CircularIconButton(
                icon: "lightbulb.fill",
                accessibilityLabel: gameState.canHint
                    ? "ax_hint_available".localized
                    : "ax_hint_used".localized,
                color: gameState.canHint
                    ? GameTheme.Colors.accent
                    : GameTheme.Colors.tertiaryText,
                size: 48,
                iconSize: 22,
                action: {
                    if let hint = gameState.requestHint() {
                        sceneBridge.showHint(hint)
                    }
                }
            )
            .disabled(!gameState.canHint)
            Spacer()
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var gameOverOverlay: some View {
        // Hidden while peeking the board so the player can inspect the final
        // grid; the floating "Show Results" button (peekBoardOverlay) brings
        // it back. See issue #36.
        if gameState.isGameOver && !isPeekingBoard {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack {
                    GameOverOverlayView(
                        gameState: gameState,
                        onViewSummary: onViewSummary,
                        onNewGame: onNewGame,
                        onUndo: {
                            gameState.undoLastPlacement()
                            sceneBridge.clearHint()
                        },
                        onViewBoard: { isPeekingBoard = true }
                    )
                    .padding(.top, 100) // Position closer to top

                    Spacer()
                }
            }
            .zIndex(2000) // Higher than dragged blocks
        }
    }

    /// While peeking the final board after game-over, a floating button to
    /// restore the results overlay. The board itself (grid + the unplaceable
    /// blocks) is the already-rendered `BoardView` showing through. See #36.
    @ViewBuilder
    private var peekBoardOverlay: some View {
        if gameState.isGameOver && isPeekingBoard {
            VStack {
                Spacer()
                Button {
                    isPeekingBoard = false
                } label: {
                    Label("show_results".localized, systemImage: "chevron.up")
                        .font(GameTheme.Typography.headline)
                        .foregroundColor(GameTheme.Colors.primaryText)
                        .padding(.vertical, GameTheme.Layout.mediumPadding)
                        .padding(.horizontal, GameTheme.Layout.largePadding)
                        .background(
                            Capsule().fill(GameTheme.Colors.cardBackground)
                        )
                        .overlay(
                            Capsule().stroke(GameTheme.Colors.primaryAccent, lineWidth: 2)
                        )
                }
                .accessibilityIdentifier("game_over_show_results_button")
                .padding(.bottom, GameTheme.Layout.largePadding)
            }
            .zIndex(2000)
        }
    }

    @ViewBuilder
    private var draggedBlockOverlay: some View {
        if let draggedBlock = dragState.draggedBlock, dragState.isDragging {
            BlockView(block: draggedBlock, cellSize: cellSize)
                .position(getDraggedBlockVisualCenter())
                .allowsHitTesting(false)
                .zIndex(1000)
                .scaleEffect(1.1)
        }
    }

    // MARK: - Drag Lifecycle Methods
    
    private func handleDragStart(block: BlockShape, index: Int, fingerLocation: CGPoint) {
        dragState.draggedBlock = block
        dragState.draggedBlockIndex = index
        dragState.isDragging = true
        dragState.dragLocation = fingerLocation
        dragState.dragOffset = CGSize(width: 0, height: -DragConfiguration.offsetAboveFinger)
        // Any pulsing hint overlay would visually fight the drag preview.
        sceneBridge.clearHint()
    }
    
    private func handleDragMove(fingerLocation: CGPoint) {
        dragState.dragLocation = fingerLocation

        let blockVisualCenter = getDraggedBlockVisualCenter()
        dragState.isHoveringOverOrigin = isBlockOverHoldingArea(visualCenter: blockVisualCenter)

        updateDragPreview(blockVisualCenter: blockVisualCenter)

        // Forward preview state to SpriteKit bridge
        sceneBridge.updatePreview(block: dragState.draggedBlock, position: dragState.previewPosition)
    }
    
    private func handleDragEnd() {
        defer {
            dragState.reset()
            sceneBridge.clearPreview()
        }

        guard let block = dragState.draggedBlock else { return }

        let blockVisualCenter = getDraggedBlockVisualCenter()

        // Check cancellation conditions
        if isLocationOffScreen(blockVisualCenter) {
            gameState.blockReturnFeedback()
            return
        }

        // Try to place the block
        if let position = dragState.previewPosition,
           gameState.canPlaceBlock(block, at: position) {
            // Capture pre-placement line counts to detect clears
            let linesBefore = gameState.linesCleared

            gameState.placeBlock(block, at: position)

            // Trigger SpriteKit visual effects
            sceneBridge.triggerBlockPlacementEffect(block: block, at: position)

            // Detect lines cleared during this placement
            if gameState.linesCleared > linesBefore {
                // Single-pass: count cells per row and per column
                var rowCounts: [Int: Int] = [:]
                var colCounts: [Int: Int] = [:]
                for cell in gameState.lastClearedCells {
                    rowCounts[cell.row, default: 0] += 1
                    colCounts[cell.col, default: 0] += 1
                }
                let gridSize = AppConfiguration.GameRules.gridSize
                let confirmedRows = Set(rowCounts.filter { $0.value >= gridSize }.keys)
                let confirmedCols = Set(colCounts.filter { $0.value >= gridSize }.keys)
                sceneBridge.triggerLineClearEffect(clearedRows: confirmedRows, clearedCols: confirmedCols)
            }
        } else {
            gameState.blockReturnFeedback()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getDraggedBlockVisualCenter() -> CGPoint {
        // The block is lifted above the finger so it isn't hidden under the
        // fingertip. `dragOffset.height` carries the base (negative) lift; the
        // applied lift tapers to zero near the grid's top edge so the targeting
        // point never floats off the top of the board (issue #39). When the
        // grid frame isn't measured yet, fall back to the full base lift.
        let baseLift = -dragState.dragOffset.height
        let lift: CGFloat
        if gridFrame.height > 0 {
            let fingerGridY = dragState.dragLocation.y - gridFrame.minY
            lift = BoardLayout.adaptiveLiftOffset(fingerGridY: fingerGridY, baseOffset: baseLift)
        } else {
            lift = baseLift
        }
        return CGPoint(
            x: dragState.dragLocation.x + dragState.dragOffset.width,
            y: dragState.dragLocation.y - lift
        )
    }
    
    private func isLocationOffScreen(_ location: CGPoint) -> Bool {
        let margin = DragConfiguration.offScreenMargin

        return location.x < viewBounds.minX - margin ||
               location.x > viewBounds.maxX + margin ||
               location.y < viewBounds.minY - margin ||
               location.y > viewBounds.maxY + margin
    }
    
    private func isBlockOverHoldingArea(visualCenter: CGPoint) -> Bool {
        guard blockSlotsFrame.width > 0 && blockSlotsFrame.height > 0 else { return false }
        
        let tolerance = DragConfiguration.hoverTolerance
        let expandedFrame = blockSlotsFrame.insetBy(dx: -tolerance, dy: -tolerance)
        
        return expandedFrame.contains(visualCenter)
    }
    
    private func updateDragPreview(blockVisualCenter: CGPoint) {
        guard let block = dragState.draggedBlock,
              !dragState.isHoveringOverOrigin,
              !isLocationOffScreen(blockVisualCenter) else {
            dragState.previewPosition = nil
            return
        }
        
        guard let gridRelativeCenter = globalToGridCoordinates(blockVisualCenter) else {
            dragState.previewPosition = nil
            return
        }
        
        let newPosition = findOptimalPlacement(for: block, nearPoint: gridRelativeCenter)
        
        // Only update if position changed to reduce animation triggers
        if dragState.previewPosition != newPosition {
            dragState.previewPosition = newPosition
        }
    }
    
    private func globalToGridCoordinates(_ globalLocation: CGPoint) -> CGPoint? {
        guard gridFrame.width > 0 && gridFrame.height > 0 else { return nil }
        
        return CGPoint(
            x: globalLocation.x - gridFrame.minX,
            y: globalLocation.y - gridFrame.minY
        )
    }
    
    private func findOptimalPlacement(for block: BlockShape, nearPoint: CGPoint) -> GridPosition? {
        BoardLayout.findOptimalPlacement(
            for: block,
            nearPoint: nearPoint,
            cellSize: cellSize,
            cellSpacing: GridConstants.cellSpacing,
            gridSize: AppConfiguration.GameRules.gridSize,
            maxDistance: DragConfiguration.maxSnapDistance,
            gridPadding: GridConstants.gridPadding,
            canPlace: { block, position in
                gameState.canPlaceBlock(block, at: position)
            }
        )
    }
    
}


#Preview {
    BoardView(
        gameState: GameState(),
        onViewSummary: {},
        onNewGame: {}
    )
}
