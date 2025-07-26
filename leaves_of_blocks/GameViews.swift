import SwiftUI

extension BlockColor {
    var color: Color {
        switch self {
        case .blue: return GameTheme.Colors.blockBlue
        case .green: return GameTheme.Colors.blockGreen
        case .red: return GameTheme.Colors.blockRed
        case .yellow: return GameTheme.Colors.blockYellow
        case .purple: return GameTheme.Colors.blockPurple
        case .orange: return GameTheme.Colors.blockOrange
        case .pink: return GameTheme.Colors.blockPink
        }
    }
}

struct SimpleAppTitleView: View {
    var body: some View {
        Text("🍂 Leaves of Blocks")
            .font(GameTheme.Typography.title)
            .foregroundColor(GameTheme.Colors.primaryText)
            .padding(.vertical, GameTheme.Layout.smallPadding)
    }
}

struct SimpleScoreView: View {
    @ObservedObject var gameState: GameState
    let onGoHome: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack {
            // Current Score
            Text("\(gameState.score)")
                .font(GameTheme.Typography.largeScore)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Spacer()
            
            // Home and Reset Icons
            HStack(spacing: GameTheme.Layout.smallSpacing) {
                // Home Button
                Button(action: onGoHome) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(GameTheme.Colors.accent)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GameTheme.Colors.cardBackground.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(GameTheme.Colors.accent.opacity(0.3), lineWidth: 2)
                                )
                        )
                }
                
                // Reset Button  
                Button(action: onReset) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(GameTheme.Colors.warning)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(GameTheme.Colors.cardBackground.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(GameTheme.Colors.warning.opacity(0.3), lineWidth: 2)
                                )
                        )
                }
            }
        }
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
    }
}

// MARK: - Background Components

struct GameBackgroundView: View {
    var body: some View {
        ZStack {
            // Autumn forest background
            LinearGradient(
                colors: GameTheme.Colors.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle leaf pattern overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            GameTheme.Colors.overlayPrimary,
                            Color.clear,
                            GameTheme.Colors.overlaySecondary
                        ],
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                )
                .ignoresSafeArea()
        }
    }
}

// MARK: - Grid Components

struct GameGridView: View {
    @ObservedObject var gameState: GameState
    let cellSize: CGFloat
    let draggedBlock: BlockShape?
    let previewPosition: GridPosition?
    let onGridFrameChange: (CGRect) -> Void
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 3) {
                ForEach(0..<GameState.gridSize, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<GameState.gridSize, id: \.self) { col in
                            GridCellView(
                                cell: gameState.grid[row][col],
                                size: cellSize,
                                isPreview: isPreviewCell(row: row, col: col),
                                previewColor: draggedBlock?.color.color ?? .clear,
                                isLineComplete: isLineCompleteCell(row: row, col: col)
                            )
                        }
                    }
                }
            }
            .padding(GameTheme.Layout.mediumPadding)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                    .fill(GameTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: GameTheme.Colors.cardBorderGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: GameTheme.Layout.strokeWidth
                            )
                    )
                    .shadow(color: GameTheme.Colors.cardShadow, radius: GameTheme.Layout.shadowRadius, x: 0, y: GameTheme.Layout.shadowOffset)
            )
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        onGridFrameChange(geo.frame(in: .global))
                    }
                }
            )
            Spacer()
        }
    }
    
    private func isPreviewCell(row: Int, col: Int) -> Bool {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock,
              gameState.canPlaceBlock(draggedBlock, at: previewPos) else { return false }
        
        for blockPos in draggedBlock.positions {
            let finalRow = previewPos.row + blockPos.row
            let finalCol = previewPos.col + blockPos.col
            if finalRow == row && finalCol == col {
                return true
            }
        }
        return false
    }
    
    private func isLineCompleteCell(row: Int, col: Int) -> Bool {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock,
              gameState.canPlaceBlock(draggedBlock, at: previewPos) else { return false }
        
        // Create a temporary grid state to check line completion
        var tempGrid = gameState.grid
        
        // Place the block temporarily
        for blockPos in draggedBlock.positions {
            let finalRow = previewPos.row + blockPos.row
            let finalCol = previewPos.col + blockPos.col
            if finalRow >= 0 && finalRow < GameState.gridSize && 
               finalCol >= 0 && finalCol < GameState.gridSize {
                tempGrid[finalRow][finalCol].isFilled = true
            }
        }
        
        // Check if this cell would be part of a completed line
        // Check row completion
        if tempGrid[row].allSatisfy({ $0.isFilled }) {
            return true
        }
        
        // Check column completion
        if (0..<GameState.gridSize).allSatisfy({ tempGrid[$0][col].isFilled }) {
            return true
        }
        
        return false
    }
}

// MARK: - Current Blocks Components

struct CurrentBlocksView: View {
    @ObservedObject var gameState: GameState
    let cellSize: CGFloat
    let draggedBlock: BlockShape?
    let isDragging: Bool
    let onDragStart: (BlockShape, CGPoint) -> Void
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    // Fixed dimensions to prevent layout shifts
    private let containerHeight: CGFloat = 120 // Fixed height for tallest blocks
    private var gridWidth: CGFloat {
        // Match the game grid width: (8 cells * 40px) + (7 spacings * 4px) + (2 * 12px padding)
        return (8 * cellSize) + (7 * 4) + (2 * 12)
    }
    private var slotWidth: CGFloat {
        // Divide available width by 3 blocks, accounting for spacing
        return (gridWidth - (2 * GameTheme.Layout.largePadding) - (2 * GameTheme.Layout.mediumSpacing)) / 3
    }
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.mediumSpacing) {
            ForEach(Array(gameState.currentBlocks.enumerated()), id: \.offset) { index, block in
                // Fixed-size slot for each block
                ZStack {
                    // Background for the slot
                    RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                        .fill(GameTheme.Colors.blockContainerBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                .stroke(GameTheme.Colors.blockContainerBorder, lineWidth: 1)
                        )
                        .shadow(color: GameTheme.Colors.blockContainerShadow, radius: 6, x: 2, y: 3)
                    
                    // Scaled block centered in slot - animates to full size when dragged
                    DraggableBlockView(
                        block: block,
                        cellSize: draggedBlock == block && isDragging ? cellSize : scaledCellSize(for: block),
                        onDragStart: { location, startLocation in
                            onDragStart(block, location)
                        },
                        onDragMove: onDragMove,
                        onDragEnd: onDragEnd
                    )
                    .gameAnimation(value: draggedBlock == block && isDragging)
                }
                .frame(width: slotWidth, height: containerHeight)
            }
        }
        .frame(width: gridWidth, height: containerHeight + (2 * GameTheme.Layout.mediumPadding))
        .padding(.horizontal, GameTheme.Layout.largePadding)
        .padding(.vertical, GameTheme.Layout.mediumPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(GameTheme.Colors.containerBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(GameTheme.Colors.containerBorder, lineWidth: 1)
                )
                .shadow(color: GameTheme.Colors.containerShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    // Calculate optimal cell size for each block to fit in its slot
    private func scaledCellSize(for block: BlockShape) -> CGFloat {
        let minRow = block.positions.map(\.row).min() ?? 0
        let maxRow = block.positions.map(\.row).max() ?? 0
        let minCol = block.positions.map(\.col).min() ?? 0
        let maxCol = block.positions.map(\.col).max() ?? 0
        
        let blockWidth = CGFloat(maxCol - minCol + 1)
        let blockHeight = CGFloat(maxRow - minRow + 1)
        
        // Calculate scale to fit within slot, leaving some padding
        let availableWidth = slotWidth * 0.8 // 80% of slot width for padding
        let availableHeight = containerHeight * 0.8 // 80% of slot height for padding
        
        let scaleForWidth = availableWidth / (blockWidth * cellSize)
        let scaleForHeight = availableHeight / (blockHeight * cellSize)
        
        // Use the smaller scale to ensure block fits in both dimensions
        let scale = min(scaleForWidth, scaleForHeight, 1.0) // Don't scale up, only down
        
        return cellSize * scale
    }
}

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 24) {
            Text("The Leaves Have Fallen")
                .font(GameTheme.Typography.headline)
                .fontWeight(.medium)
                .foregroundColor(GameTheme.Colors.error)
                .tracking(1)
                .italic()
            
            Text("Final Score")
                .font(GameTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(GameTheme.Colors.warning)
                .tracking(1)
            
            Text("\(gameState.score)")
                .font(GameTheme.Typography.largeScore)
                .foregroundColor(GameTheme.Colors.primaryText)
            
            Button(action: {
                withAnimation(GameTheme.Animations.springAnimation) {
                    gameState.resetGame()
                }
            }) {
                Text("New Season")
                    .font(GameTheme.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(GameTheme.Colors.buttonText)
                    .tracking(0.5)
                    .padding(.horizontal, GameTheme.Layout.largePadding)
                    .padding(.vertical, GameTheme.Layout.mediumPadding)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: GameTheme.Colors.buttonGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .scaleEffect(1.0)
            .gameAnimation(value: gameState.isGameOver)
        }
        .padding(GameTheme.Layout.largePadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                .fill(GameTheme.Colors.overlayBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.overlayCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: GameTheme.Colors.overlayBorderGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: GameTheme.Layout.strokeWidth
                        )
                )
        )
        .shadow(color: GameTheme.Colors.overlayDeepShadow, radius: 20, x: 0, y: 8)
        .scaleEffect(1.05)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Game Home View

struct GameHomeView: View {
    @ObservedObject var gameState: GameState
    let onStartGame: () -> Void
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            VStack(spacing: GameTheme.Layout.sectionSpacing) {
                Spacer()
                
                // App Title
                Text("🍂 Leaves of Blocks")
                    .font(GameTheme.Typography.title)
                    .foregroundColor(GameTheme.Colors.primaryText)
                    .padding(.vertical, GameTheme.Layout.largePadding)
                    .padding(.top, GameTheme.Layout.extraLargePadding) // Extra top spacing
                
                // High Score Display
                VStack(spacing: GameTheme.Layout.smallSpacing) {
                    Text("Best Score")
                        .font(GameTheme.Typography.headline)
                        .foregroundColor(GameTheme.Colors.accent)
                    
                    Text("\(gameState.highScoreManager.highScore)")
                        .font(GameTheme.Typography.largeScore)
                        .foregroundColor(GameTheme.Colors.accent)
                        
                    // Last played info if available
                    if gameState.score > 0 {
                        Text("Last Score: \(gameState.score)")
                            .font(GameTheme.Typography.caption)
                            .foregroundColor(GameTheme.Colors.secondaryText)
                    }
                }
                .padding(GameTheme.Layout.largePadding)
                .background(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .fill(GameTheme.Colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                                .stroke(GameTheme.Colors.accent.opacity(0.3), lineWidth: 2)
                        )
                )
                
                Spacer()
                
                // Start Game Button
                Button(action: onStartGame) {
                    Text("Start New Game")
                        .font(GameTheme.Typography.headline)
                        .fontWeight(.medium)
                        .foregroundColor(GameTheme.Colors.buttonText)
                        .tracking(0.5)
                        .padding(.horizontal, GameTheme.Layout.extraLargePadding)
                        .padding(.vertical, GameTheme.Layout.mediumPadding)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: GameTheme.Colors.buttonGradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .scaleEffect(1.0)
                .gameAnimation(value: true)
                
                Spacer()
                
                // Block Grass Artwork at bottom
                BlockGrassView()
            }
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
        }
    }
}

// MARK: - Main Game Board

struct GameBoardView: View {
    @ObservedObject var gameState: GameState
    @State private var draggedBlock: BlockShape?
    @State private var previewPosition: GridPosition?
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var gridFrame: CGRect = .zero
    @State private var fallingLeaves: [FallingLeaf] = []
    
    // Constants for consistent positioning
    private let dragOffsetY: CGFloat = 80 // Distance above finger
    
    let cellSize: CGFloat = 40
    let onGoHome: () -> Void
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            
            VStack(spacing: GameTheme.Layout.sectionSpacing) {
                // Score Section with integrated buttons
                SimpleScoreView(
                    gameState: gameState,
                    onGoHome: onGoHome,
                    onReset: {
                        withAnimation(GameTheme.Animations.springAnimation) {
                            gameState.resetGame()
                        }
                    }
                )
                .padding(.top, GameTheme.Layout.extraLargePadding) // Extra top spacing
                
                // Game Grid
                GameGridView(
                    gameState: gameState,
                    cellSize: cellSize,
                    draggedBlock: draggedBlock,
                    previewPosition: previewPosition,
                    onGridFrameChange: { frame in
                        gridFrame = frame
                    }
                )
                
                Spacer()
                
                // Current Blocks
                CurrentBlocksView(
                    gameState: gameState,
                    cellSize: cellSize,
                    draggedBlock: draggedBlock,
                    isDragging: isDragging,
                    onDragStart: { block, location in
                        draggedBlock = block
                        isDragging = true
                        dragLocation = location
                    },
                    onDragMove: { location in
                        dragLocation = location
                        // Calculate preview position based on the dragged block's position
                        // The block appears above the finger, so we use that location for preview
                        // But we need to offset to the block's top-left corner for grid alignment
                        if let block = draggedBlock {
                            let blockCenterLocation = CGPoint(
                                x: location.x,
                                y: location.y - dragOffsetY
                            )
                            
                            // Calculate the block's dimensions and offset to top-left corner
                            let minRow = block.positions.map(\.row).min() ?? 0
                            let maxRow = block.positions.map(\.row).max() ?? 0
                            let minCol = block.positions.map(\.col).min() ?? 0
                            let maxCol = block.positions.map(\.col).max() ?? 0
                            
                            let blockWidth = CGFloat(maxCol - minCol + 1) * cellSize
                            let blockHeight = CGFloat(maxRow - minRow + 1) * cellSize
                            
                            // Convert center position to top-left corner position
                            let blockTopLeftLocation = CGPoint(
                                x: blockCenterLocation.x - blockWidth/2,
                                y: blockCenterLocation.y - blockHeight/2
                            )
                            
                            updatePreviewPosition(for: blockTopLeftLocation)
                        }
                    },
                    onDragEnd: {
                        // Try to place the block if it's over the grid
                        if let block = draggedBlock,
                           let previewPos = previewPosition,
                           gameState.canPlaceBlock(block, at: previewPos) {
                            
                            gameState.placeBlock(block, at: previewPos)
                        }
                        
                        draggedBlock = nil
                        previewPosition = nil
                        isDragging = false
                    }
                )
                
                // Static grass foundation - always visible
                BlockGrassView()
            }
            .zIndex(10) // Game elements above grass
            .padding(.horizontal, GameTheme.Layout.largePadding)
            .padding(.vertical, GameTheme.Layout.mediumPadding)
            
            // Game Over Overlay
            if gameState.isGameOver {
                GameOverOverlayView(gameState: gameState)
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
        
        // Falling leaves animation
        ForEach(fallingLeaves.indices, id: \.self) { index in
            FallingLeafView(leaf: fallingLeaves[index])
                .zIndex(999)
        }
        }
        .onChange(of: gameState.lastClearedCells) { _, newClearedCells in
            if !newClearedCells.isEmpty {
                // Slight delay to let the clearing animation finish
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    createFallingLeaves(from: newClearedCells)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getGridPosition(from location: CGPoint, in size: CGSize) -> GridPosition {
        // Account for the grid's internal padding (mediumPadding = 16)
        let adjustedX = location.x - 16  // GameTheme.Layout.mediumPadding
        let adjustedY = location.y - 16  // GameTheme.Layout.mediumPadding
        
        // Each cell is cellSize + 3 points spacing (except the last one)
        let cellSpacing: CGFloat = 3
        let cellWithSpacing = cellSize + cellSpacing
        
        let col = Int(adjustedX / cellWithSpacing)
        let row = Int(adjustedY / cellWithSpacing)
        
        return GridPosition(
            row: max(0, min(GameState.gridSize - 1, row)),
            col: max(0, min(GameState.gridSize - 1, col))
        )
    }
    
    private func updatePreviewPosition(for globalLocation: CGPoint) {
        // Check if the drag location is over the grid
        if gridFrame.contains(globalLocation) {
            // Convert global coordinates to grid-relative coordinates
            let relativeLocation = CGPoint(
                x: globalLocation.x - gridFrame.minX,
                y: globalLocation.y - gridFrame.minY
            )
            let gridPosition = getGridPosition(from: relativeLocation, in: gridFrame.size)
            previewPosition = gridPosition
        } else {
            previewPosition = nil
        }
    }
    
    private func createFallingLeaves(from clearedCells: [ClearedCell]) {
        var newLeaves: [FallingLeaf] = []
        
        for cell in clearedCells {
            let leafPosition = CGPoint(
                x: gridFrame.minX + CGFloat(cell.col) * (cellSize + 3) + cellSize/2 + 12,
                y: gridFrame.minY + CGFloat(cell.row) * (cellSize + 3) + cellSize/2 + 12
            )
            let leaf = FallingLeaf(
                startPosition: leafPosition,
                color: cell.color.color,
                size: CGFloat.random(in: 16...24)
            )
            newLeaves.append(leaf)
        }
        
        fallingLeaves.append(contentsOf: newLeaves)
        
        // Remove leaves after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            fallingLeaves.removeAll()
        }
    }
}

struct GridCellView: View {
    let cell: GridCell
    let size: CGFloat
    let isPreview: Bool
    let previewColor: Color
    let isLineComplete: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                cell.isFilled ? 
                    LinearGradient(colors: [cell.color.color, cell.color.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                (isLineComplete ? 
                    LinearGradient(colors: [Color(red: 0.9, green: 0.7, blue: 0.1), Color(red: 0.9, green: 0.5, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                (isPreview ? 
                    LinearGradient(colors: [previewColor.opacity(0.7), previewColor.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                    LinearGradient(colors: [Color(red: 0.25, green: 0.2, blue: 0.15).opacity(0.3), Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                ))
            )
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        cell.isFilled ? Color(red: 0.95, green: 0.9, blue: 0.8).opacity(0.4) :
                        (isLineComplete ? Color(red: 0.9, green: 0.7, blue: 0.1).opacity(0.8) :
                        (isPreview ? previewColor.opacity(0.5) : Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.2))),
                        lineWidth: cell.isFilled ? 2 : 1
                    )
            )
            .shadow(
                color: cell.isFilled ? cell.color.color.opacity(0.4) :
                      (isLineComplete ? Color(red: 0.9, green: 0.6, blue: 0.1).opacity(0.6) :
                      (isPreview ? previewColor.opacity(0.4) : .clear)),
                radius: cell.isFilled ? 5 : (isLineComplete || isPreview ? 4 : 0),
                x: 0, y: cell.isFilled ? 2 : 1
            )
            .scaleEffect(cell.isFilled ? 1.0 : (isPreview ? 0.92 : 0.88))
            .gameAnimation(value: isPreview)
            .gameAnimation(value: isLineComplete)
            .gameAnimation(value: cell.isFilled)
    }
}

struct BlockView: View {
    let block: BlockShape
    let cellSize: CGFloat
    
    var body: some View {
        ZStack {
            // Calculate the bounding box of the block
            let minRow = block.positions.map(\.row).min() ?? 0
            let maxRow = block.positions.map(\.row).max() ?? 0
            let minCol = block.positions.map(\.col).min() ?? 0
            let maxCol = block.positions.map(\.col).max() ?? 0
            
            let width = CGFloat(maxCol - minCol + 1) * cellSize
            let height = CGFloat(maxRow - minRow + 1) * cellSize
            
            // Background for the block area
            Rectangle()
                .fill(Color.clear)
                .frame(width: width, height: height)
            
            // Individual leaf-like cells of the block
            ForEach(Array(block.positions.enumerated()), id: \.offset) { index, position in
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [block.color.color, block.color.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: cellSize - 2, height: cellSize - 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.95, green: 0.9, blue: 0.8).opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: block.color.color.opacity(0.5), radius: 5, x: 0, y: 3)
                    .offset(
                        x: CGFloat(position.col - minCol) * cellSize - width/2 + cellSize/2,
                        y: CGFloat(position.row - minRow) * cellSize - height/2 + cellSize/2
                    )
            }
        }
    }
}

struct DraggableBlockView: View {
    let block: BlockShape
    let cellSize: CGFloat
    let onDragStart: (CGPoint, CGPoint) -> Void  // current location, start location
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    @State private var isDragging: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            BlockView(block: block, cellSize: cellSize)
                .opacity(isDragging ? 0.4 : 1.0)
                .scaleEffect(isDragging ? 0.95 : 1.0)
                .gameAnimation(value: isDragging)
                .gesture(
                    DragGesture(minimumDistance: 5, coordinateSpace: .global)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                let blockCenter = CGPoint(
                                    x: geometry.frame(in: .global).midX,
                                    y: geometry.frame(in: .global).midY
                                )
                                onDragStart(value.location, blockCenter)
                            }
                            onDragMove(value.location)
                        }
                        .onEnded { _ in
                            isDragging = false
                            onDragEnd()
                        }
                )
        }
        .frame(width: getBlockWidth(), height: getBlockHeight())
    }
    
    private func getBlockWidth() -> CGFloat {
        let minCol = block.positions.map(\.col).min() ?? 0
        let maxCol = block.positions.map(\.col).max() ?? 0
        return CGFloat(maxCol - minCol + 1) * cellSize
    }
    
    private func getBlockHeight() -> CGFloat {
        let minRow = block.positions.map(\.row).min() ?? 0
        let maxRow = block.positions.map(\.row).max() ?? 0
        return CGFloat(maxRow - minRow + 1) * cellSize
    }
}

extension BlockShape: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

// MARK: - Falling Leaves Animation

struct FallingLeaf: Identifiable {
    let id = UUID()
    let startPosition: CGPoint
    let color: Color
    let size: CGFloat
    var currentPosition: CGPoint
    var rotation: Double
    var rotationSpeed: Double
    var fallSpeed: Double
    var horizontalDrift: Double
    
    init(startPosition: CGPoint, color: Color, size: CGFloat = 20) {
        self.startPosition = startPosition
        self.color = color
        self.size = size
        self.currentPosition = startPosition
        self.rotation = 0
        self.rotationSpeed = Double.random(in: -180...180)
        self.fallSpeed = Double.random(in: 100...200)
        self.horizontalDrift = Double.random(in: -30...30)
    }
}

struct FallingLeafView: View {
    @State var leaf: FallingLeaf
    @State private var animationOffset: CGSize = .zero
    @State private var animationRotation: Double = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [leaf.color, leaf.color.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: leaf.size, height: leaf.size)
            .rotationEffect(.degrees(animationRotation))
            .position(
                x: leaf.currentPosition.x + animationOffset.width,
                y: leaf.currentPosition.y + animationOffset.height
            )
            .onAppear {
                withAnimation(.easeIn(duration: GameTheme.Animations.leafFallDuration)) {
                    animationOffset = CGSize(
                        width: leaf.horizontalDrift,
                        height: 600
                    )
                    animationRotation = leaf.rotationSpeed * 4
                }
            }
    }
}


struct BlockGrassView: View {
    let grassColors: [Color] = [
        Color(red: 0.15, green: 0.6, blue: 0.05),   // Dark green
        Color(red: 0.25, green: 0.7, blue: 0.15),   // Medium green
        Color(red: 0.2, green: 0.65, blue: 0.1),    // Forest green
        Color(red: 0.3, green: 0.75, blue: 0.2),    // Light green
        Color(red: 0.18, green: 0.62, blue: 0.08),  // Deep green
        Color(red: 0.22, green: 0.68, blue: 0.12),  // Pine green
        Color(red: 0.28, green: 0.73, blue: 0.18),  // Spring green
    ]
    
    private let blockSize: CGFloat = 12
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                // Create columns of varying heights
                HStack(spacing: 1) {
                    ForEach(0..<Int(screenWidth / (blockSize + 1)), id: \.self) { col in
                        VStack(spacing: 1) {
                            Spacer()
                            // Each column has a random height between 2-5 blocks
                            let columnHeight = getColumnHeight(for: col)
                            ForEach(0..<columnHeight, id: \.self) { blockIndex in
                                StaticGrassBlockView(
                                    color: grassColors[seededRandom(col: col, blockIndex: blockIndex) % grassColors.count],
                                    size: blockSize
                                )
                            }
                        }
                    }
                }
                .frame(height: 80) // Max height for grass area
                
                // Ground base
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.15, blue: 0.1),
                                Color(red: 0.15, green: 0.1, blue: 0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                    .shadow(color: Color(red: 0.1, green: 0.05, blue: 0.02).opacity(0.5), radius: 4, x: 0, y: -2)
            }
        }
    }
    
    // Get deterministic column height
    private func getColumnHeight(for col: Int) -> Int {
        let seed = col * 7919
        let random = ((seed * 9301 + 49297) % 233280) / 50000
        return min(5, max(2, random + 2)) // Heights between 2-5 blocks
    }
    
    // Deterministic random for consistent block colors
    private func seededRandom(col: Int, blockIndex: Int) -> Int {
        let seed = col * 1000 + blockIndex * 100
        return ((seed * 9301 + 49297) % 233280) / 1000
    }
}

struct StaticGrassBlockView: View {
    let color: Color
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}
