import SwiftUI

// MARK: - Current Blocks Components

struct CurrentBlocksView: View {
    var gameState: GameState
    let cellSize: CGFloat
    let draggedBlock: BlockShape?
    let isDragging: Bool
    let draggedBlockIndex: Int?
    let isHoveringOverOrigin: Bool
    let onDragStart: (BlockShape, Int, CGPoint) -> Void  // block, index, location
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    // Fixed dimensions to prevent layout shifts
    private let containerHeight: CGFloat = 50 // Reduced height for more compact layout
    private var gridWidth: CGFloat {
        let gridSize = CGFloat(GameTheme.GameConfig.gridSize)
        return (gridSize * cellSize) + ((gridSize - 1) * GameTheme.Layout.gridLineWidth)
    }
    private var slotWidth: CGFloat {
        // Divide available width by 3 blocks, accounting for spacing between slots
        return (gridWidth - (2 * GameTheme.Layout.mediumSpacing)) / 3
    }
    
    var body: some View {
        HStack(spacing: GameTheme.Layout.mediumSpacing) {
            ForEach(Array(gameState.currentBlocks.enumerated()), id: \.offset) { index, block in
                DraggableBlockView(
                    block: block,
                    cellSize: scaledCellSize(for: block),
                    onDragStart: { location in
                        onDragStart(block, index, location)
                    },
                    onDragMove: onDragMove,
                    onDragEnd: onDragEnd
                )
                .frame(width: slotWidth, height: containerHeight)
            }
        }
        .padding(GameTheme.Layout.smallPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                .fill(
                    isHoveringOverOrigin ?
                    GameTheme.Colors.accent.opacity(0.15) :
                    GameTheme.Colors.cardBackground
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.Layout.buttonCornerRadius)
                        .stroke(
                            isHoveringOverOrigin ? GameTheme.Colors.accent : Color.black,
                            lineWidth: GameTheme.Layout.cardBorderWidth
                        )
                )
        )
        // Modifier order matters: `.accessibilityElement(children:)` must come
        // first so the identifier and label apply to the resulting container
        // element. With the identifier listed first, SwiftUI cascades it down
        // to the descendant draggable blocks instead of binding it to the
        // container itself.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ax_available_blocks_format".localized(with: gameState.currentBlocks.count))
        .accessibilityIdentifier("block_container")
    }
    
    // Calculate optimal cell size for each block to fit in its slot
    private func scaledCellSize(for block: BlockShape) -> CGFloat {
        let bounds = block.getBounds()
        
        let blockWidth = CGFloat(bounds.width)
        let blockHeight = CGFloat(bounds.height)
        
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
        Group {
            if block.type == .horizontalClear || block.type == .verticalClear || block.type == .areaClear {
                // Special power-up block rendering
                ZStack {
                    RoundedRectangle(cornerRadius: GameTheme.Layout.specialBlockCornerRadius)
                        .fill(block.color.color)
                        .frame(
                            width: cellSize - GameTheme.Layout.specialBlockInset,
                            height: cellSize - GameTheme.Layout.specialBlockInset
                        )

                    // Icon overlay
                    Image(systemName: block.type.systemIconName)
                        .foregroundColor(GameTheme.Colors.buttonText)
                        .font(.system(size: cellSize * GameTheme.Layout.specialBlockIconScale, weight: .bold))
                }
            } else {
                // Normal block rendering
                ZStack {
                    // Calculate the bounding box of the block
                    let bounds = block.getBounds()

                    let width = CGFloat(bounds.width) * cellSize
                    let height = CGFloat(bounds.height) * cellSize

                    // Background for the block area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: width, height: height)

                    // Individual leaf-like cells of the block
                    ForEach(Array(block.positions.enumerated()), id: \.offset) { index, position in
                        RoundedRectangle(cornerRadius: GameTheme.Layout.cellCornerRadius)
                            .fill(block.color.color)
                            .frame(width: cellSize - 2, height: cellSize - 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: GameTheme.Layout.cellCornerRadius)
                                    .strokeBorder(Color.black.opacity(0.3), lineWidth: 1.5)
                            )
                            .offset(
                                x: CGFloat(position.col - bounds.minCol) * cellSize - width/2 + cellSize/2,
                                y: CGFloat(position.row - bounds.minRow) * cellSize - height/2 + cellSize/2
                            )
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct DraggableBlockView: View {
    let block: BlockShape
    let cellSize: CGFloat
    let onDragStart: (CGPoint) -> Void  // current location
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    @State private var isDragging: Bool = false
    @State private var throttleTask: Task<Void, Never>?
    @State private var pendingLocation: CGPoint?
    @Environment(\.scenePhase) private var scenePhase

    private let frameInterval: TimeInterval = AppConfiguration.Performance.dragUpdateThrottleInterval
    
    var body: some View {
        ZStack {
            // Original block stays in place with reduced opacity when dragging
            BlockView(block: block, cellSize: cellSize)
                .opacity(isDragging ? GameTheme.Layout.mediumLowOpacity : 1.0)
        }
        .frame(width: getBlockWidth(), height: getBlockHeight())
        .contentShape(Rectangle()) // Ensure entire frame is tappable
        // See block_container note above — element first, then label/id.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(block.accessibilityLabel)
        .accessibilityIdentifier("draggable_block")
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        onDragStart(value.location)
                        startThrottledUpdates()
                    } else {
                        // Store the latest location for throttled processing
                        pendingLocation = value.location
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    stopThrottledUpdates()
                    onDragEnd()
                }
        )
        .onDisappear {
            stopThrottledUpdates()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // If the app is backgrounded mid-drag, DragGesture.onEnded may
            // never fire — leaving local state stuck. The next drag would
            // skip onDragStart and the parent would never see it.
            if newPhase != .active && isDragging {
                isDragging = false
                stopThrottledUpdates()
            }
        }
    }
    
    private func startThrottledUpdates() {
        throttleTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(frameInterval))
                guard !Task.isCancelled else { break }
                if let location = pendingLocation {
                    onDragMove(location)
                    pendingLocation = nil
                }
            }
        }
    }

    private func stopThrottledUpdates() {
        throttleTask?.cancel()
        throttleTask = nil
        pendingLocation = nil
    }
    
    private func getBlockWidth() -> CGFloat {
        return CGFloat(block.getBounds().width) * cellSize
    }
    
    private func getBlockHeight() -> CGFloat {
        return CGFloat(block.getBounds().height) * cellSize
    }
}

// MARK: - Previews

#Preview("Block Shapes") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            BlockView(
                block: BlockShape(positions: [
                    GridPosition(row: 0, col: 0),
                    GridPosition(row: 0, col: 1),
                    GridPosition(row: 1, col: 0),
                    GridPosition(row: 1, col: 1)
                ], color: .green),
                cellSize: GameTheme.Layout.cellSize
            )
            BlockView(
                block: BlockShape(positions: [
                    GridPosition(row: 0, col: 0),
                    GridPosition(row: 0, col: 1),
                    GridPosition(row: 0, col: 2)
                ], color: .blue),
                cellSize: GameTheme.Layout.cellSize
            )
            BlockView(
                block: BlockShape(positions: [
                    GridPosition(row: 0, col: 0),
                    GridPosition(row: 1, col: 0),
                    GridPosition(row: 1, col: 1)
                ], color: .orange),
                cellSize: GameTheme.Layout.cellSize
            )
        }
        HStack(spacing: 20) {
            BlockView(
                block: BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .red, type: .horizontalClear),
                cellSize: GameTheme.Layout.cellSize
            )
            BlockView(
                block: BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue, type: .verticalClear),
                cellSize: GameTheme.Layout.cellSize
            )
            BlockView(
                block: BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .purple, type: .areaClear),
                cellSize: GameTheme.Layout.cellSize
            )
        }
    }
    .padding()
}

#Preview("Current Blocks") {
    CurrentBlocksView(
        gameState: GameState(),
        cellSize: GameTheme.Layout.cellSize,
        draggedBlock: nil,
        isDragging: false,
        draggedBlockIndex: nil,
        isHoveringOverOrigin: false,
        onDragStart: { _, _, _ in },
        onDragMove: { _ in },
        onDragEnd: {}
    )
    .padding()
}
