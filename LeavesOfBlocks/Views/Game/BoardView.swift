import SwiftUI
import SpriteKit

// MARK: - Main Game Board

struct BoardView: View {
    var gameState: GameState
    @State private var dragState: DragState = DragState()
    @State private var gridFrame: CGRect = .zero
    @State private var blockSlotsFrame: CGRect = .zero
    @State private var viewBounds: CGRect = .zero

    /// Bridge for SpriteKit scene communication
    @State private var sceneBridge: GameSceneBridge?
    
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
        let gridSize = CGFloat(GameTheme.GameConfig.gridSize)
        return (gridSize * cellSize) + ((gridSize - 1) * GridConstants.cellSpacing) + (2 * GridConstants.gridPadding)
    }
    
    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            ZStack {
                VStack(spacing: 44) {
                    // Score Row
                    HStack {
                        Spacer()
                        SimpleScoreView(gameState: gameState)
                            .frame(width: gameWidth)
                        Spacer()
                    }

                    // Grid Row
                    HStack {
                        Spacer()
                        if let bridge = sceneBridge {
                            SpriteKitGameView(bridge: bridge)
                                .frame(width: gameWidth, height: gameWidth)
                                .onGeometryChange(for: CGRect.self) { proxy in
                                    proxy.frame(in: .global)
                                } action: { newValue in
                                    gridFrame = newValue
                                }
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
                    
                    Spacer(minLength: 20) // Leave space for grass
                }
                .zIndex(10) // Game elements above grass
                .padding(.horizontal, GameTheme.Layout.largePadding)
                .padding(.top, GameTheme.Layout.mediumPadding)
                .onAppear {
                    if sceneBridge == nil {
                        sceneBridge = GameSceneBridge(gameState: gameState, cellSize: cellSize)
                    }
                }
            
            // Combo Notification Overlay - appears above game elements but below game over
            ComboNotificationOverlay(gameState: gameState)
                .zIndex(1500) // Above game elements, below game over
            
            // Game Over Overlay - highest priority, appears above everything
            if gameState.isGameOver {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    VStack {
                        GameOverOverlayView(
                            gameState: gameState,
                            onViewSummary: onViewSummary,
                            onNewGame: onNewGame
                        )
                        .padding(.top, 100) // Position closer to top
                        
                        Spacer()
                    }
                }
                .zIndex(2000) // Higher than dragged blocks
            }
            
        // Dragged block following finger - positioned with flexible offset for better visibility
        if let draggedBlock = dragState.draggedBlock, dragState.isDragging {
            BlockView(block: draggedBlock, cellSize: cellSize)
                .position(getDraggedBlockVisualCenter())
                .allowsHitTesting(false)
                .zIndex(1000)
                .scaleEffect(1.1)
            }
        }
    }
    .onGeometryChange(for: CGRect.self) { proxy in
        proxy.frame(in: .global)
    } action: { newValue in
        viewBounds = newValue
    }
    }

    // MARK: - Drag Lifecycle Methods
    
    private func handleDragStart(block: BlockShape, index: Int, fingerLocation: CGPoint) {
        dragState.draggedBlock = block
        dragState.draggedBlockIndex = index
        dragState.isDragging = true
        dragState.dragLocation = fingerLocation
        dragState.dragOffset = CGSize(width: 0, height: -DragConfiguration.offsetAboveFinger)
    }
    
    private func handleDragMove(fingerLocation: CGPoint) {
        dragState.dragLocation = fingerLocation

        let blockVisualCenter = getDraggedBlockVisualCenter()
        dragState.isHoveringOverOrigin = isBlockOverHoldingArea(visualCenter: blockVisualCenter)

        updateDragPreview(blockVisualCenter: blockVisualCenter)

        // Forward preview state to SpriteKit bridge
        sceneBridge?.updatePreview(block: dragState.draggedBlock, position: dragState.previewPosition)
    }
    
    private func handleDragEnd() {
        defer {
            dragState.reset()
            sceneBridge?.clearPreview()
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
            sceneBridge?.triggerBlockPlacementEffect(block: block, at: position)

            // Detect lines cleared during this placement
            if gameState.linesCleared > linesBefore {
                // Single-pass: count cells per row and per column
                var rowCounts: [Int: Int] = [:]
                var colCounts: [Int: Int] = [:]
                for cell in gameState.lastClearedCells {
                    rowCounts[cell.row, default: 0] += 1
                    colCounts[cell.col, default: 0] += 1
                }
                let gridSize = GameTheme.GameConfig.gridSize
                let confirmedRows = Set(rowCounts.filter { $0.value >= gridSize }.keys)
                let confirmedCols = Set(colCounts.filter { $0.value >= gridSize }.keys)
                sceneBridge?.triggerLineClearEffect(clearedRows: confirmedRows, clearedCols: confirmedCols)
            }
        } else {
            gameState.blockReturnFeedback()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getDraggedBlockVisualCenter() -> CGPoint {
        return CGPoint(
            x: dragState.dragLocation.x + dragState.dragOffset.width,
            y: dragState.dragLocation.y + dragState.dragOffset.height
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
        let maxDistance = DragConfiguration.maxSnapDistance
        var bestPosition: GridPosition?
        var bestDistance = CGFloat.greatestFiniteMagnitude
        
        let bounds = block.getBounds()
        let cellWithSpacing = GridConstants.cellWithSpacing(cellSize: cellSize)
        
        // Optimize search area - only check positions near the drag location
        let centerRow = Int(nearPoint.y / cellWithSpacing)
        let centerCol = Int(nearPoint.x / cellWithSpacing)
        let searchRadius = max(bounds.width, bounds.height) + 2
        
        let startRow = max(0, centerRow - searchRadius)
        let endRow = min(GameTheme.GameConfig.gridSize - 1, centerRow + searchRadius)
        let startCol = max(0, centerCol - searchRadius)
        let endCol = min(GameTheme.GameConfig.gridSize - 1, centerCol + searchRadius)
        
        for row in startRow...endRow {
            for col in startCol...endCol {
                let position = GridPosition(row: row, col: col)
                
                guard gameState.canPlaceBlock(block, at: position) else { continue }
                
                let blockCenter = calculateBlockCenter(block: block, at: position)
                let distance = hypot(blockCenter.x - nearPoint.x, blockCenter.y - nearPoint.y)
                
                if distance < bestDistance && distance <= maxDistance {
                    bestDistance = distance
                    bestPosition = position
                }
            }
        }
        
        return bestPosition
    }
    
    private func calculateBlockCenter(block: BlockShape, at position: GridPosition) -> CGPoint {
        let bounds = block.getBounds()
        let cellWithSpacing = GridConstants.cellWithSpacing(cellSize: cellSize)
        
        let centerRow = CGFloat(position.row) + CGFloat(bounds.maxRow + bounds.minRow) / 2.0
        let centerCol = CGFloat(position.col) + CGFloat(bounds.maxCol + bounds.minCol) / 2.0
        
        return CGPoint(
            x: centerCol * cellWithSpacing + cellSize / 2.0 + GridConstants.gridPadding,
            y: centerRow * cellWithSpacing + cellSize / 2.0 + GridConstants.gridPadding
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
