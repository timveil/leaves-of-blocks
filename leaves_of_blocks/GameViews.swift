import SwiftUI

extension BlockColor {
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .red: return .red
        case .yellow: return .yellow
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        }
    }
}

struct GameBoardView: View {
    @ObservedObject var gameState: GameState
    @State private var draggedBlock: BlockShape?
    @State private var previewPosition: GridPosition?
    @State private var dragLocation: CGPoint = .zero
    @State private var dragStartOffset: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var gridFrame: CGRect = .zero
    
    let cellSize: CGFloat = 32
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
            // Score Section
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(gameState.score)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("High Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(gameState.highScoreManager.highScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                
                if gameState.linesCleared > 0 {
                    Text("Lines Cleared: \(gameState.linesCleared)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Game Grid
            GeometryReader { geometry in
                VStack(spacing: 2) {
                    ForEach(0..<GameState.gridSize, id: \.self) { row in
                        HStack(spacing: 2) {
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
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            gridFrame = geo.frame(in: .global)
                        }
                    }
                )
            }
            .frame(height: CGFloat(GameState.gridSize) * (cellSize + 2) - 2)
            
            Spacer()
            
            // Current Blocks
            HStack(spacing: 30) {
                ForEach(Array(gameState.currentBlocks.enumerated()), id: \.offset) { index, block in
                    DraggableBlockView(
                        block: block,
                        cellSize: cellSize * 0.8,
                        onDragStart: { location, startLocation in
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
                }
            }
            .padding()
            
            if gameState.isGameOver {
                VStack {
                    Text("Game Over!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Final Score: \(gameState.score)")
                        .font(.headline)
                        .padding(.bottom)
                    
                    Button("New Game") {
                        gameState.resetGame()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 10)
            }
        }
        .padding()
        
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
        }
    }
    
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

struct GridCellView: View {
    let cell: GridCell
    let size: CGFloat
    let isPreview: Bool
    let previewColor: Color
    let isLineComplete: Bool
    
    var body: some View {
        Rectangle()
            .fill(cell.isFilled ? cell.color.color : 
                  (isLineComplete ? Color.yellow.opacity(0.6) :
                   (isPreview ? previewColor.opacity(0.5) : Color.white)))
            .frame(width: size, height: size)
            .border(Color.gray.opacity(0.5), width: 1)
            .animation(.easeInOut(duration: 0.1), value: isPreview)
            .animation(.easeInOut(duration: 0.1), value: isLineComplete)
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
            
            // Individual cells of the block
            ForEach(Array(block.positions.enumerated()), id: \.offset) { index, position in
                Rectangle()
                    .fill(block.color.color)
                    .frame(width: cellSize - 2, height: cellSize - 2)
                    .cornerRadius(4)
                    .shadow(radius: 2)
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
