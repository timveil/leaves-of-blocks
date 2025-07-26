import SwiftUI

extension BlockColor {
    var color: Color {
        switch self {
        case .blue: return Color(red: 0.4, green: 0.6, blue: 0.8)     // Twilight blue
        case .green: return Color(red: 0.3, green: 0.6, blue: 0.2)   // Forest green
        case .red: return Color(red: 0.8, green: 0.2, blue: 0.1)     // Deep crimson
        case .yellow: return Color(red: 0.9, green: 0.7, blue: 0.1)  // Golden amber
        case .purple: return Color(red: 0.5, green: 0.3, blue: 0.4)  // Muted plum
        case .orange: return Color(red: 0.9, green: 0.5, blue: 0.1)  // Burnt orange
        case .pink: return Color(red: 0.8, green: 0.4, blue: 0.3)    // Rust pink
        }
    }
}

struct AppTitleView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("🍂 Leaves of Blocks 🍂")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.9, green: 0.7, blue: 0.1),
                            Color(red: 0.9, green: 0.5, blue: 0.1),
                            Color(red: 0.8, green: 0.4, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.6, green: 0.3, blue: 0.1).opacity(0.6), radius: 3, x: 1, y: 2)
                .italic()
                .tracking(1.2)
            
            Text("A Whitman-inspired Puzzle")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.3).opacity(0.8))
                .tracking(2)
                .italic()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.05).opacity(0.9),
                            Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.9, green: 0.7, blue: 0.1).opacity(0.7),
                                    Color(red: 0.9, green: 0.5, blue: 0.1).opacity(0.4),
                                    Color(red: 0.8, green: 0.4, blue: 0.1).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.4), radius: 10, x: 0, y: 5)
        )
    }
}

struct EnhancedScoreView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("🎯")
                            .font(.caption)
                        Text("Score")
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.1))
                            .tracking(1.5)
                    }
                    Text("\(gameState.score)")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.9, blue: 0.8),
                                    Color(red: 0.9, green: 0.8, blue: 0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.8, green: 0.6, blue: 0.2).opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("High Score")
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.1))
                            .tracking(1.5)
                        Text("🏆")
                            .font(.caption)
                    }
                    Text("\(gameState.highScoreManager.highScore)")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.9, blue: 0.8),
                                    Color(red: 0.9, green: 0.8, blue: 0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.8, green: 0.6, blue: 0.2).opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            
            if gameState.linesCleared > 0 {
                HStack(spacing: 8) {
                    Text("🍃")
                        .font(.headline)
                    Text("Leaves Cleared:")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.2))
                        .tracking(1)
                    Text("\(gameState.linesCleared)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.9, blue: 0.8),
                                    Color(red: 0.9, green: 0.8, blue: 0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.3, green: 0.6, blue: 0.2).opacity(0.4), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 0.25, green: 0.2, blue: 0.15).opacity(0.6))
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.3, green: 0.6, blue: 0.2).opacity(0.4), lineWidth: 1.5)
                        )
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: gameState.linesCleared)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.13, blue: 0.08).opacity(0.9),
                            Color(red: 0.22, green: 0.17, blue: 0.12).opacity(0.8),
                            Color(red: 0.16, green: 0.11, blue: 0.06).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.9, green: 0.7, blue: 0.1).opacity(0.6),
                                    Color(red: 0.9, green: 0.5, blue: 0.1).opacity(0.4),
                                    Color(red: 0.8, green: 0.4, blue: 0.1).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.4), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Background Components

struct GameBackgroundView: View {
    var body: some View {
        ZStack {
            // Autumn forest background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.02), // Deep brown
                    Color(red: 0.2, green: 0.15, blue: 0.1),  // Rich earth
                    Color(red: 0.15, green: 0.1, blue: 0.05)  // Dark bark
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle leaf pattern overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.1),
                            Color.clear,
                            Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.05)
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
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.15, green: 0.1, blue: 0.05).opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.4),
                                        Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.6),
                                        Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.4), radius: 12, x: 0, y: 6)
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
    let onDragStart: (BlockShape, CGPoint, CGPoint) -> Void
    let onDragMove: (CGPoint) -> Void
    let onDragEnd: () -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            ForEach(Array(gameState.currentBlocks.enumerated()), id: \.offset) { index, block in
                DraggableBlockView(
                    block: block,
                    cellSize: cellSize * 0.8,
                    onDragStart: { location, startLocation in
                        onDragStart(block, location, startLocation)
                    },
                    onDragMove: onDragMove,
                    onDragEnd: onDragEnd
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 0.1, green: 0.05, blue: 0.02).opacity(0.4), radius: 6, x: 2, y: 3)
                )
                .scaleEffect(draggedBlock == block && isDragging ? 0.7 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: draggedBlock == block && isDragging)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.12, green: 0.08, blue: 0.04).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.1, green: 0.05, blue: 0.02).opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Game Over Overlay

struct GameOverOverlayView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 24) {
            Text("The Leaves Have Fallen")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.1))
                .tracking(1)
                .italic()
            
            Text("Final Score")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.1))
                .tracking(1)
            
            Text("\(gameState.score)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.95, green: 0.9, blue: 0.8))
            
            Button(action: {
                withAnimation(.spring()) {
                    gameState.resetGame()
                }
            }) {
                Text("New Season")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.1, green: 0.05, blue: 0.02))
                    .tracking(0.5)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.9, green: 0.7, blue: 0.1),
                                        Color(red: 0.9, green: 0.5, blue: 0.1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3), value: gameState.isGameOver)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 0.15, green: 0.1, blue: 0.05).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.8, green: 0.2, blue: 0.1).opacity(0.6),
                                    Color(red: 0.9, green: 0.5, blue: 0.1).opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
        )
        .shadow(color: Color(red: 0.3, green: 0.1, blue: 0.05).opacity(0.6), radius: 20, x: 0, y: 8)
        .scaleEffect(1.05)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Main Game Board

struct GameBoardView: View {
    @ObservedObject var gameState: GameState
    @State private var draggedBlock: BlockShape?
    @State private var previewPosition: GridPosition?
    @State private var dragLocation: CGPoint = .zero
    @State private var dragStartOffset: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var gridFrame: CGRect = .zero
    @State private var fallingLeaves: [FallingLeaf] = []
    
    let cellSize: CGFloat = 32
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            VStack(spacing: 24) {
                // App Title
                AppTitleView()
                
                // Enhanced Score Section
                EnhancedScoreView(gameState: gameState)
                
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
                    onDragStart: { block, location, startLocation in
                        draggedBlock = block
                        isDragging = true
                        dragLocation = location
                        dragStartOffset = CGPoint(
                            x: location.x - startLocation.x,
                            y: location.y - startLocation.y
                        )
                    },
                    onDragMove: { location in
                        dragLocation = location
                        let adjustedLocation = CGPoint(
                            x: location.x - dragStartOffset.x,
                            y: location.y - dragStartOffset.y
                        )
                        updatePreviewPosition(for: adjustedLocation)
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
                        dragStartOffset = .zero
                    }
                )
                
                // Block Grass Artwork at bottom
                BlockGrassView()
            }
            .padding(.horizontal, 16)
            
            // Game Over Overlay
            if gameState.isGameOver {
                GameOverOverlayView(gameState: gameState)
            }
        
        // Dragged block following finger
        if let draggedBlock = draggedBlock, isDragging {
            BlockView(block: draggedBlock, cellSize: cellSize * 0.8)
                .position(
                    x: dragLocation.x - dragStartOffset.x,
                    y: dragLocation.y - dragStartOffset.y
                )
                .allowsHitTesting(false)
                .zIndex(1000)
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
        let row = Int(location.y / (cellSize + 2))
        let col = Int(location.x / (cellSize + 2))
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
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPreview)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isLineComplete)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: cell.isFilled)
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
                .opacity(isDragging ? 0.3 : 1.0)
                .animation(.spring(response: 0.1), value: isDragging)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
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
                withAnimation(.easeIn(duration: 2.0)) {
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
    let grassBlocks: [(color: Color, height: CGFloat)] = [
        (Color(red: 0.15, green: 0.6, blue: 0.05), 45),
        (Color(red: 0.25, green: 0.7, blue: 0.15), 52),
        (Color(red: 0.2, green: 0.65, blue: 0.1), 48),
        (Color(red: 0.3, green: 0.75, blue: 0.2), 55),
        (Color(red: 0.18, green: 0.62, blue: 0.08), 42),
        (Color(red: 0.22, green: 0.68, blue: 0.12), 49),
        (Color(red: 0.28, green: 0.73, blue: 0.18), 54),
        (Color(red: 0.16, green: 0.58, blue: 0.06), 46),
        (Color(red: 0.24, green: 0.69, blue: 0.14), 51),
        (Color(red: 0.19, green: 0.63, blue: 0.09), 47),
        (Color(red: 0.27, green: 0.72, blue: 0.17), 53),
        (Color(red: 0.21, green: 0.66, blue: 0.11), 44),
        (Color(red: 0.26, green: 0.71, blue: 0.16), 50),
        (Color(red: 0.17, green: 0.59, blue: 0.07), 43),
        (Color(red: 0.23, green: 0.67, blue: 0.13), 48),
        (Color(red: 0.29, green: 0.74, blue: 0.19), 56),
        (Color(red: 0.15, green: 0.57, blue: 0.05), 41),
        (Color(red: 0.25, green: 0.7, blue: 0.15), 52),
        (Color(red: 0.2, green: 0.64, blue: 0.1), 49),
        (Color(red: 0.3, green: 0.76, blue: 0.2), 54),
        (Color(red: 0.18, green: 0.61, blue: 0.08), 45),
        (Color(red: 0.22, green: 0.65, blue: 0.12), 47),
        (Color(red: 0.28, green: 0.73, blue: 0.18), 53),
        (Color(red: 0.16, green: 0.56, blue: 0.06), 42),
        (Color(red: 0.24, green: 0.68, blue: 0.14), 50),
        (Color(red: 0.19, green: 0.62, blue: 0.09), 46),
        (Color(red: 0.27, green: 0.71, blue: 0.17), 55),
        (Color(red: 0.21, green: 0.66, blue: 0.11), 48),
        (Color(red: 0.26, green: 0.7, blue: 0.16), 51),
        (Color(red: 0.17, green: 0.58, blue: 0.07), 44),
    ]
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                // Multiple rows of grass for fuller effect
                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(Array(grassBlocks.enumerated()), id: \.offset) { index, grass in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [grass.color, grass.color.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 12, height: grass.height)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(grass.color.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: grass.color.opacity(0.4), radius: 3, x: 0, y: 2)
                    }
                }
                
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
            .padding(.horizontal, 0)
        }
    }
}
