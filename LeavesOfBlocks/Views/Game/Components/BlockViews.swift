import SwiftUI

// MARK: - Current Blocks Components

struct CurrentBlocksView: View {
    @ObservedObject var gameState: GameState
    let cellSize: CGFloat
    let draggedBlock: BlockShape?
    let isDragging: Bool
    let draggedBlockIndex: Int?
    let isHoveringOverOrigin: Bool
    let onDragStart: (BlockShape, Int, CGPoint) -> Void  // Added index parameter
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    // Fixed dimensions to prevent layout shifts
    private let containerHeight: CGFloat = 50 // Reduced height for more compact layout
    private var gridWidth: CGFloat {
        // Match the game grid width: (8 cells * cellSize) + (7 spacings * 3px)
        return (8 * cellSize) + (7 * 3)
    }
    private var slotWidth: CGFloat {
        // Divide available width by 3 blocks, accounting for spacing between slots
        return (gridWidth - (2 * GameTheme.Layout.mediumSpacing)) / 3
    }
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.mediumSpacing) {
                ForEach(Array(gameState.currentBlocks.enumerated()), id: \.offset) { index, block in
                    // Fixed-size slot for each block
                    ZStack {
                        // Background for the slot - highlight if hovering over origin
                        RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                            .fill(GameTheme.Colors.blockContainerBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                                    .stroke(GameTheme.Colors.blockContainerBorder, lineWidth: 1)
                            )
                            .shadow(
                                color: GameTheme.Colors.blockContainerShadow,
                                radius: 6,
                                x: 2,
                                y: 3
                            )
                        
                        // Scaled block centered in slot - size stays consistent
                        DraggableBlockView(
                            block: block,
                            cellSize: scaledCellSize(for: block),
                            onDragStart: { location, startLocation in
                                onDragStart(block, index, location)  // Pass index
                            },
                            onDragMove: onDragMove,
                            onDragEnd: onDragEnd
                        )
                    }
                    .frame(width: slotWidth, height: containerHeight)
                }
            }
        .padding(GameTheme.Layout.mediumPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                .fill(
                    isHoveringOverOrigin ? 
                    GameTheme.Colors.accent.opacity(0.15) : 
                    GameTheme.Colors.cardBackground
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.cardCornerRadius)
                        .stroke(
                            isHoveringOverOrigin ?
                            LinearGradient(
                                colors: [GameTheme.Colors.accent, GameTheme.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: GameTheme.Colors.cardBorderGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isHoveringOverOrigin ? 3 : GameTheme.Layout.strokeWidth
                        )
                )
                .shadow(
                    color: isHoveringOverOrigin ? 
                    GameTheme.Colors.accent.opacity(0.4) : 
                    GameTheme.Colors.cardShadow, 
                    radius: isHoveringOverOrigin ? 12 : GameTheme.Layout.shadowRadius, 
                    x: 0, 
                    y: isHoveringOverOrigin ? 6 : GameTheme.Layout.shadowOffset
                )
        )
        .scaleEffect(isHoveringOverOrigin ? 1.02 : 1.0)
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

// MARK: - Block Views

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

private struct DraggableBlockView: View {
    let block: BlockShape
    let cellSize: CGFloat
    let onDragStart: (CGPoint, CGPoint) -> Void  // current location, start location
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    @State private var isDragging: Bool = false
    @State private var lastUpdateTime: Date = Date()
    
    var body: some View {
        ZStack {
            // Original block stays in place with reduced opacity when dragging
            BlockView(block: block, cellSize: cellSize)
                .opacity(isDragging ? 0.3 : 1.0)
        }
        .frame(width: getBlockWidth(), height: getBlockHeight())
        .contentShape(Rectangle()) // Ensure entire frame is tappable
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
                .onChanged { value in
                    let now = Date()
                    if !isDragging {
                        isDragging = true
                        lastUpdateTime = now
                        let blockCenter = CGPoint(
                            x: getBlockWidth() / 2,
                            y: getBlockHeight() / 2
                        )
                        onDragStart(value.location, blockCenter)
                    } else if now.timeIntervalSince(lastUpdateTime) >= 0.016 { // ~60fps limit
                        lastUpdateTime = now
                        onDragMove(value.location)
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    onDragEnd()
                }
        )
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
