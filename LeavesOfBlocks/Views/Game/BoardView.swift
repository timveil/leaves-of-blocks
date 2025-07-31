import SwiftUI

// MARK: - Main Game Board

struct BoardView: View {
    @ObservedObject var gameState: GameState
    @State private var draggedBlock: BlockShape?
    @State private var draggedBlockIndex: Int?  // Track which slot the block came from
    @State private var previewPosition: GridPosition?
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var gridFrame: CGRect = .zero
    @State private var blockSlotsFrame: CGRect = .zero  // Track the holding area frame
    @State private var isHoveringOverOrigin: Bool = false  // Track if hovering over original slot
    
    // Constants for consistent positioning
    private let dragOffsetY: CGFloat = 80 // Distance above finger
    
    let cellSize: CGFloat = 40
    let onViewSummary: () -> Void
    
    private var gameWidth: CGFloat {
        (8 * cellSize) + (7 * 3) + (2 * GameTheme.Layout.mediumPadding)
    }
    
    var body: some View {
        BaseScreenView(showsStatusBar: false) {
            ZStack {
                VStack(spacing: GameTheme.Layout.smallSpacing) {
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
                        GameGridView(
                        gameState: gameState,
                        cellSize: cellSize,
                        draggedBlock: draggedBlock,
                        previewPosition: previewPosition,
                        onGridFrameChange: { frame in
                            gridFrame = frame
                        }
                        )
                        .frame(width: gameWidth)
                        Spacer()
                    }
                    
                    // Game Stats Row
                    GameStatsRowView(
                        gameState: gameState,
                        gameWidth: gameWidth
                    )
                    
                    Spacer().frame(maxHeight: 30)
                    
                    // Holding Area Row
                    HStack {
                        Spacer()
                        CurrentBlocksView(
                        gameState: gameState,
                        cellSize: cellSize,
                        draggedBlock: draggedBlock,
                        isDragging: isDragging,
                        draggedBlockIndex: draggedBlockIndex,
                        isHoveringOverOrigin: isHoveringOverOrigin,
                        onDragStart: { block, index, location in
                            draggedBlock = block
                            draggedBlockIndex = index  // Remember which slot it came from
                            isDragging = true
                            dragLocation = location
                        },
                        onDragMove: { location in
                            dragLocation = location
                            
                            // Check if hovering over the holding area container  
                            isHoveringOverOrigin = isBlockOverHoldingArea(location: location)
                            
                            // Calculate preview position based on the dragged block's position
                            if let block = draggedBlock {
                                let blockCenterLocation = CGPoint(
                                    x: location.x,
                                    y: location.y - dragOffsetY
                                )
                                
                                // First check if user dragged way off-screen - clear preview if so
                                if isDraggedWayOffScreen(location: blockCenterLocation) {
                                    previewPosition = nil  // Clear preview when dragged off-screen
                                } else {
                                    // Calculate the block's dimensions relative to its anchor point (0,0)
                                    let minRow = block.positions.map(\.row).min() ?? 0
                                    let minCol = block.positions.map(\.col).min() ?? 0
                                    
                                    let blockWidth = CGFloat((block.positions.map(\.col).max() ?? 0) - minCol + 1) * cellSize
                                    let blockHeight = CGFloat((block.positions.map(\.row).max() ?? 0) - minRow + 1) * cellSize
                                    
                                    // Calculate where the block's anchor point (0,0) would be placed
                                    let anchorLocation = CGPoint(
                                        x: blockCenterLocation.x - blockWidth/2 + CGFloat(minCol) * cellSize,
                                        y: blockCenterLocation.y - blockHeight/2 + CGFloat(minRow) * cellSize
                                    )
                                    
                                    // Only update preview position if not hovering over origin
                                    if !isHoveringOverOrigin {
                                        updatePreviewPosition(for: anchorLocation)
                                    } else {
                                        previewPosition = nil  // Clear preview when hovering over origin
                                    }
                                }
                            }
                        },
                        onDragEnd: {
                            // First check if the user dragged way off-screen to cancel
                            let adjustedLocation = CGPoint(x: dragLocation.x, y: dragLocation.y - dragOffsetY)
                            if isDraggedWayOffScreen(location: adjustedLocation) {
                                // User dragged way off-screen - return block to holding area regardless of preview
                                gameState.blockReturnFeedback()
                                draggedBlock = nil
                                draggedBlockIndex = nil
                                previewPosition = nil
                                isDragging = false
                                isHoveringOverOrigin = false
                            } else if let block = draggedBlock,
                                      let previewPos = previewPosition,
                                      gameState.canPlaceBlock(block, at: previewPos) {
                                // Valid placement on grid - place the block
                                gameState.placeBlock(block, at: previewPos)
                                draggedBlock = nil
                                draggedBlockIndex = nil
                                previewPosition = nil
                                isDragging = false
                                isHoveringOverOrigin = false
                            } else {
                                // Invalid placement - return block to holding area
                                gameState.blockReturnFeedback()
                                draggedBlock = nil
                                draggedBlockIndex = nil
                                previewPosition = nil
                                isDragging = false
                                isHoveringOverOrigin = false
                            }
                        }
                        )
                        .frame(width: gameWidth)
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    blockSlotsFrame = geo.frame(in: .global)
                                }
                            }
                        )
                        Spacer()
                    }
                    
                    Spacer(minLength: 20) // Leave space for grass
                }
                .zIndex(10) // Game elements above grass
                .padding(.horizontal, GameTheme.Layout.largePadding)
            
            // Game Over Overlay - highest priority, appears above everything
            if gameState.isGameOver {
                ZStack {
                    // Semi-transparent background to dim the game
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack {
                        GameOverOverlayView(
                            gameState: gameState,
                            onViewSummary: onViewSummary
                        )
                        .padding(.top, 100) // Position closer to top
                        
                        Spacer()
                    }
                }
                .zIndex(2000) // Higher than dragged blocks
            }
        
        // Dragged block following finger - positioned above finger for better visibility
        if let draggedBlock = draggedBlock, isDragging {
            BlockView(block: draggedBlock, cellSize: cellSize)
                .position(
                    x: dragLocation.x,
                    y: dragLocation.y - dragOffsetY  // Position block above finger
                )
                .allowsHitTesting(false)
                .zIndex(1000)
                .scaleEffect(1.1) // Slightly larger during drag for better visibility
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
    }
    
    // MARK: - Helper Methods
    
    private func isDraggedWayOffScreen(location: CGPoint) -> Bool {
        // Get screen bounds
        let screenBounds = UIScreen.main.bounds
        
        // Define generous boundaries - user needs to drag way off screen
        let margin: CGFloat = 100 // pixels beyond screen edge
        let leftBound = -margin
        let rightBound = screenBounds.width + margin
        let topBound = -margin
        let bottomBound = screenBounds.height + margin
        
        // Check if dragged way outside these bounds
        return location.x < leftBound || 
               location.x > rightBound || 
               location.y < topBound || 
               location.y > bottomBound
    }
    
    private func isBlockOverHoldingArea(location: CGPoint) -> Bool {
        // Check if the current drag location is within the bounds of the entire holding area container
        // Validate that we have a valid blockSlotsFrame
        guard blockSlotsFrame.width > 0 && blockSlotsFrame.height > 0 else { return false }
        
        // Check if the drag location (adjusted for finger offset) is within the entire container bounds
        let adjustedLocation = CGPoint(x: location.x, y: location.y - dragOffsetY)
        
        // Add some tolerance to make it easier to hit the container
        let tolerance: CGFloat = 15
        
        return adjustedLocation.x >= (blockSlotsFrame.minX - tolerance) &&
               adjustedLocation.x <= (blockSlotsFrame.maxX + tolerance) &&
               adjustedLocation.y >= (blockSlotsFrame.minY - tolerance) &&
               adjustedLocation.y <= (blockSlotsFrame.maxY + tolerance)
    }
    
    private func getGridPosition(from location: CGPoint, in size: CGSize) -> GridPosition {
        // Account for the grid's internal padding (mediumPadding = 16)
        let adjustedX = location.x - 16  // GameTheme.Layout.mediumPadding
        let adjustedY = location.y - 16  // GameTheme.Layout.mediumPadding
        
        // Each cell is cellSize + 3 points spacing (except the last one)
        let cellSpacing: CGFloat = 3
        let cellWithSpacing = cellSize + cellSpacing
        
        let col = Int(adjustedX / cellWithSpacing)
        let row = Int(adjustedY / cellWithSpacing)
        
        // Don't clamp to grid bounds - allow negative/out-of-bounds positions for proper edge detection
        return GridPosition(row: row, col: col)
    }
    
    private func updatePreviewPosition(for globalLocation: CGPoint) {
        guard let draggedBlock = draggedBlock else {
            previewPosition = nil
            return
        }
        
        // Validate grid frame is available and reasonable
        guard gridFrame.width > 0 && gridFrame.height > 0 else {
            return
        }
        
        // Convert global coordinates to grid-relative coordinates
        let relativeLocation = CGPoint(
            x: globalLocation.x - gridFrame.minX,
            y: globalLocation.y - gridFrame.minY
        )
        
        // Only update if coordinates are reasonable (not too far negative)
        guard relativeLocation.x > -100 && relativeLocation.y > -100 else {
            previewPosition = nil
            return
        }
        
        // Find the best fit position for the block
        if let bestFit = findBestFitPosition(for: draggedBlock, near: relativeLocation) {
            // Only update if position actually changed to reduce animation triggers
            if previewPosition != bestFit {
                previewPosition = bestFit
            }
        } else {
            previewPosition = nil
        }
    }
    
    private func findBestFitPosition(for block: BlockShape, near targetLocation: CGPoint) -> GridPosition? {
        var bestPosition: GridPosition?
        var bestDistanceSquared: CGFloat = CGFloat.greatestFiniteMagnitude
        let maxSnapDistanceSquared: CGFloat = 300 * 300 // Maximum snap distance squared for performance
        
        // Check all possible positions on the grid
        for row in 0..<GameTheme.GameConfig.gridSize {
            for col in 0..<GameTheme.GameConfig.gridSize {
                let position = GridPosition(row: row, col: col)
                
                // Check if block can be placed at this position
                if gameState.canPlaceBlock(block, at: position) {
                    // Calculate the center point of the block if placed at this position
                    let blockCenter = getBlockCenterInGrid(for: block, at: position)
                    
                    // Calculate squared distance from target location (faster than sqrt)
                    let distanceSquared = pow(blockCenter.x - targetLocation.x, 2) + pow(blockCenter.y - targetLocation.y, 2)
                    
                    // Update best position if this is closer
                    if distanceSquared < bestDistanceSquared {
                        bestDistanceSquared = distanceSquared
                        bestPosition = position
                    }
                }
            }
        }
        
        // Only return a position if we found one within a reasonable distance
        // This prevents snapping when the user drags very far from the grid
        if bestDistanceSquared <= maxSnapDistanceSquared {
            return bestPosition
        }
        
        return nil
    }
    
    private func getBlockCenterInGrid(for block: BlockShape, at position: GridPosition) -> CGPoint {
        // Calculate the bounding box of the block
        let minRow = block.positions.map(\.row).min() ?? 0
        let maxRow = block.positions.map(\.row).max() ?? 0
        let minCol = block.positions.map(\.col).min() ?? 0
        let maxCol = block.positions.map(\.col).max() ?? 0
        
        // Calculate the center of the block in grid coordinates
        let blockCenterRow = CGFloat(position.row) + CGFloat(maxRow + minRow) / 2.0
        let blockCenterCol = CGFloat(position.col) + CGFloat(maxCol + minCol) / 2.0
        
        // Convert to pixel coordinates within the grid
        let cellSpacing: CGFloat = 3
        let cellWithSpacing = cellSize + cellSpacing
        let gridPadding: CGFloat = 16  // GameTheme.Layout.mediumPadding
        
        let centerX = blockCenterCol * cellWithSpacing + cellSize / 2.0 + gridPadding
        let centerY = blockCenterRow * cellWithSpacing + cellSize / 2.0 + gridPadding
        
        return CGPoint(x: centerX, y: centerY)
    }
    
}

#Preview {
    BoardView(
        gameState: GameState(),
        onViewSummary: {}
    )
}
