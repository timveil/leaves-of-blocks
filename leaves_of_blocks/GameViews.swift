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
    
    let cellSize: CGFloat = 32
    
    var body: some View {
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
            VStack(spacing: 2) {
                ForEach(0..<GameState.gridSize, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<GameState.gridSize, id: \.self) { col in
                            GridCellView(
                                cell: gameState.grid[row][col],
                                size: cellSize,
                                isPreview: isPreviewCell(row: row, col: col),
                                previewColor: draggedBlock?.color.color ?? .clear
                            )
                        }
                    }
                }
            }
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
            .dropDestination(for: BlockShape.self) { blocks, location in
                guard let block = blocks.first else { return false }
                
                let gridPosition = getGridPosition(from: location)
                if gameState.canPlaceBlock(block, at: gridPosition) {
                    gameState.placeBlock(block, at: gridPosition)
                    draggedBlock = nil
                    previewPosition = nil
                    return true
                }
                return false
            } isTargeted: { isTargeted in
                // Handle drag enter/exit for preview
            }
            .onDrop(of: [.data], isTargeted: nil) { providers, location in
                return false
            }
            
            Spacer()
            
            // Current Blocks
            HStack(spacing: 30) {
                ForEach(Array(gameState.currentBlocks.enumerated()), id: \.offset) { index, block in
                    DraggableBlockView(
                        block: block,
                        cellSize: cellSize * 0.8,
                        onDragStart: { draggedBlock = block },
                        onDragEnd: { 
                            draggedBlock = nil
                            previewPosition = nil
                        },
                        onDragMove: { location in
                            let gridPos = getGridPosition(from: location)
                            if gameState.canPlaceBlock(block, at: gridPos) {
                                previewPosition = gridPos
                            } else {
                                previewPosition = nil
                            }
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
    }
    
    private func getGridPosition(from location: CGPoint) -> GridPosition {
        let row = Int(location.y / (cellSize + 2))
        let col = Int(location.x / (cellSize + 2))
        return GridPosition(
            row: max(0, min(GameState.gridSize - 1, row)),
            col: max(0, min(GameState.gridSize - 1, col))
        )
    }
    
    private func isPreviewCell(row: Int, col: Int) -> Bool {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock else { return false }
        
        for blockPos in draggedBlock.positions {
            let finalRow = previewPos.row + blockPos.row
            let finalCol = previewPos.col + blockPos.col
            if finalRow == row && finalCol == col {
                return true
            }
        }
        return false
    }
}

struct GridCellView: View {
    let cell: GridCell
    let size: CGFloat
    let isPreview: Bool
    let previewColor: Color
    
    var body: some View {
        Rectangle()
            .fill(cell.isFilled ? cell.color.color : 
                  (isPreview ? previewColor.opacity(0.5) : Color.white))
            .frame(width: size, height: size)
            .border(Color.gray.opacity(0.5), width: 1)
            .animation(.easeInOut(duration: 0.1), value: isPreview)
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
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    let onDragMove: (CGPoint) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    var body: some View {
        BlockView(block: block, cellSize: cellSize)
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .opacity(isDragging ? 0.8 : 1.0)
            .offset(dragOffset)
            .draggable(block) {
                BlockView(block: block, cellSize: cellSize * 0.6)
                    .opacity(0.8)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            onDragStart()
                        }
                        dragOffset = value.translation
                        onDragMove(value.location)
                    }
                    .onEnded { value in
                        isDragging = false
                        dragOffset = .zero
                        onDragEnd()
                    }
            )
            .animation(.spring(response: 0.3), value: isDragging)
            .animation(.spring(response: 0.3), value: dragOffset)
    }
}

// Extension to make BlockShape conform to Transferable for drag and drop
extension BlockShape: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

