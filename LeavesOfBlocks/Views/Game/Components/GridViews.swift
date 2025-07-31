import SwiftUI

// MARK: - Grid Components

struct GameGridView: View {
    @ObservedObject var gameState: GameState
    let cellSize: CGFloat
    let draggedBlock: BlockShape?
    let previewPosition: GridPosition?
    let onGridFrameChange: (CGRect) -> Void
    
    var body: some View {
        VStack(spacing: 3) {
                ForEach(0..<GameTheme.GameConfig.gridSize, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<GameTheme.GameConfig.gridSize, id: \.self) { col in
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
    }
    
    private func isPreviewCell(row: Int, col: Int) -> Bool {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock else { return false }
        
        // Only show preview if the block can be placed at this position
        guard gameState.canPlaceBlock(draggedBlock, at: previewPos) else { return false }
        
        switch draggedBlock.type {
        case .horizontalClear:
            // Show preview for the entire row
            return row == previewPos.row
            
        case .verticalClear:
            // Show preview for the entire column
            return col == previewPos.col
            
        case .normal:
            // Check if this grid cell matches any block position
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
    
    private func isLineCompleteCell(row: Int, col: Int) -> Bool {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock,
              gameState.canPlaceBlock(draggedBlock, at: previewPos) else { return false }
        
        switch draggedBlock.type {
        case .horizontalClear:
            // Horizontal clear always shows the entire row as "complete"
            return row == previewPos.row
            
        case .verticalClear:
            // Vertical clear always shows the entire column as "complete"
            return col == previewPos.col
            
        case .normal:
            // Get the lines that would be completed with this placement
            let completedLines = getCompletedLinesForPreview()
            
            // Check if this cell is in any completed row or column
            return completedLines.rows.contains(row) || completedLines.cols.contains(col)
        }
    }
    
    private func getCompletedLinesForPreview() -> (rows: Set<Int>, cols: Set<Int>) {
        guard let previewPos = previewPosition,
              let draggedBlock = draggedBlock,
              gameState.canPlaceBlock(draggedBlock, at: previewPos) else { 
            return (rows: Set<Int>(), cols: Set<Int>()) 
        }
        
        // Create a temporary grid state to check line completion
        var tempGrid = gameState.grid
        
        // Place the block temporarily
        for blockPos in draggedBlock.positions {
            let finalRow = previewPos.row + blockPos.row
            let finalCol = previewPos.col + blockPos.col
            if finalRow >= 0 && finalRow < GameTheme.GameConfig.gridSize && 
               finalCol >= 0 && finalCol < GameTheme.GameConfig.gridSize {
                tempGrid[finalRow][finalCol].isFilled = true
            }
        }
        
        var completedRows: Set<Int> = []
        var completedCols: Set<Int> = []
        
        // Check all rows for completion
        for row in 0..<GameTheme.GameConfig.gridSize {
            if tempGrid[row].allSatisfy({ $0.isFilled }) {
                completedRows.insert(row)
            }
        }
        
        // Check all columns for completion
        for col in 0..<GameTheme.GameConfig.gridSize {
            if (0..<GameTheme.GameConfig.gridSize).allSatisfy({ tempGrid[$0][col].isFilled }) {
                completedCols.insert(col)
            }
        }
        
        return (rows: completedRows, cols: completedCols)
    }
}

private struct GridCellView: View {
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
                    LinearGradient(colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                (isPreview ? 
                    LinearGradient(colors: [previewColor.opacity(0.8), previewColor.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                    LinearGradient(colors: [Color(red: 0.25, green: 0.2, blue: 0.15).opacity(0.3), Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                ))
            )
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        cell.isFilled ? Color(red: 0.95, green: 0.9, blue: 0.8).opacity(0.4) :
                        (isLineComplete ? Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.9) :
                        (isPreview ? previewColor.opacity(0.8) : Color(red: 0.4, green: 0.25, blue: 0.1).opacity(0.2))),
                        lineWidth: cell.isFilled ? 2 : (isLineComplete ? 3 : (isPreview ? 2 : 1))
                    )
            )
            .overlay(
                // Add special effects for line clearing only (avoid preview pulse during drag)
                Group {
                    if isLineComplete {
                        // Static golden glow for line clearing (no pulsing to avoid conflicts)
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 1.0, green: 0.9, blue: 0.2), lineWidth: 3)
                            .opacity(0.8)
                            .scaleEffect(1.02)
                    }
                }
            )
            .shadow(
                color: cell.isFilled ? cell.color.color.opacity(0.4) :
                      (isLineComplete ? Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8) :
                      (isPreview ? previewColor.opacity(0.6) : .clear)),
                radius: cell.isFilled ? 5 : (isLineComplete ? 8 : (isPreview ? 6 : 0)),
                x: 0, y: cell.isFilled ? 2 : 1
            )
            .scaleEffect(cell.isFilled ? 1.0 : (isLineComplete ? 0.98 : (isPreview ? 0.95 : 0.88)))
    }
}

// MARK: - Animation Helper Views

private struct LineCompletePulseView: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color(red: 1.0, green: 0.9, blue: 0.2), lineWidth: 4)
            .opacity(isAnimating ? 0.8 : 0.4)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isAnimating = true
                }
            }
    }
}

private struct PreviewPulseView: View {
    let previewColor: Color
    @State private var isAnimating: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(previewColor, lineWidth: 3)
            .opacity(isAnimating ? 0.6 : 0.3)
            .scaleEffect(isAnimating ? 1.02 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isAnimating = true
                }
            }
    }
}