import SwiftUI

// MARK: - Performance Optimization Structures

/// Cache class for expensive preview calculations during drag operations
private class PreviewCache {
    private var lastBlockId: String?
    private var lastPreviewPosition: GridPosition?
    private var cachedCompletedLines: (rows: Set<Int>, cols: Set<Int>)?
    private var cacheTimestamp: Date = Date()
    
    // Cache validity duration from configuration
    private let cacheValidityDuration: TimeInterval = AppConfiguration.Performance.previewCacheValidityDuration
    
    func getCachedLines(for blockId: String, at position: GridPosition) -> (rows: Set<Int>, cols: Set<Int>)? {
        let now = Date()
        let isValid = now.timeIntervalSince(cacheTimestamp) < cacheValidityDuration &&
                     lastBlockId == blockId &&
                     lastPreviewPosition == position
        
        return isValid ? cachedCompletedLines : nil
    }
    
    func setCachedLines(_ lines: (rows: Set<Int>, cols: Set<Int>), for blockId: String, at position: GridPosition) {
        lastBlockId = blockId
        lastPreviewPosition = position
        cachedCompletedLines = lines
        cacheTimestamp = Date()
    }
    
    func invalidate() {
        lastBlockId = nil
        lastPreviewPosition = nil
        cachedCompletedLines = nil
    }
}

// MARK: - Grid Components

struct GameGridView: View {
    @ObservedObject var gameState: GameState
    let cellSize: CGFloat
    let draggedBlock: BlockShape?
    let previewPosition: GridPosition?
    let onGridFrameChange: (CGRect) -> Void
    
    // Performance caching for preview calculations
    @State private var previewCache = PreviewCache()
    
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
                                GameTheme.Gradients.cardBorder,
                                lineWidth: GameTheme.Layout.strokeWidth
                            )
                    )
                    .shadow(color: GameTheme.Colors.cardShadow, radius: GameTheme.Layout.shadowRadius, x: 0, y: GameTheme.Layout.shadowOffset)
            )
            .onChange(of: gameState.blocksPlaced) { _, _ in
                // Invalidate cache when blocks are placed to avoid stale data
                previewCache.invalidate()
            }
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        onGridFrameChange(geo.frame(in: .global))
                    }
                }
            )
            .accessibilityIdentifier("game_grid")
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
            
        case .areaClear:
            // Show preview for 3x3 area centered on placement position
            return isWithinAreaClearRange(row: row, col: col, center: previewPos)
            
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
            
        case .areaClear:
            // Area clear always shows the 3x3 area as "complete"
            return isWithinAreaClearRange(row: row, col: col, center: previewPos)
            
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
        
        // Create a unique identifier for this block at this position
        let blockId = "\(draggedBlock.positions.count)-\(draggedBlock.color.hashValue)"
        
        // Check cache first
        if let cachedResult = previewCache.getCachedLines(for: blockId, at: previewPos) {
            return cachedResult
        }
        
        // Perform expensive calculation only if not cached
        let result = calculateCompletedLines(for: draggedBlock, at: previewPos)
        
        // Cache the result for future use
        previewCache.setCachedLines(result, for: blockId, at: previewPos)
        
        return result
    }
    
    /// Separated expensive calculation logic for better performance monitoring
    private func calculateCompletedLines(for block: BlockShape, at position: GridPosition) -> (rows: Set<Int>, cols: Set<Int>) {
        // Create a temporary grid state to check line completion
        var tempGrid = gameState.grid
        
        // Place the block temporarily
        for blockPos in block.positions {
            let finalRow = position.row + blockPos.row
            let finalCol = position.col + blockPos.col
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
    
    private func isWithinAreaClearRange(row: Int, col: Int, center: GridPosition) -> Bool {
        let rowDistance = abs(row - center.row)
        let colDistance = abs(col - center.col)
        return rowDistance <= 1 && colDistance <= 1
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
                    cell.color.color :
                (isLineComplete ? 
                    GameTheme.Colors.lineCompletionPrimary :
                (isPreview ? 
                    previewColor.opacity(GameTheme.Layout.mediumHighOpacity) : 
                    GameTheme.Colors.blockBackground.opacity(GameTheme.Layout.mediumLowOpacity)
                ))
            )
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        cell.isFilled ? GameTheme.Colors.primaryText.opacity(GameTheme.Layout.mediumOpacity) :
                        (isLineComplete ? GameTheme.Colors.lineCompletionPrimary.opacity(GameTheme.Layout.veryHighOpacity) :
                        (isPreview ? previewColor.opacity(GameTheme.Layout.highOpacity) : GameTheme.Colors.gridBorder.opacity(GameTheme.Layout.lowOpacity))),
                        lineWidth: cell.isFilled ? 2 : (isLineComplete ? 3 : (isPreview ? 2 : 1))
                    )
            )
            .overlay(
                // Add special effects for line clearing only (avoid preview pulse during drag)
                Group {
                    if isLineComplete {
                        // Static golden glow for line clearing (no pulsing to avoid conflicts)
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GameTheme.Colors.lineCompletionAccent, lineWidth: 3)
                            .opacity(GameTheme.Layout.highOpacity)
                            .scaleEffect(GameTheme.Layout.subtleScale)
                    }
                }
            )
            .shadow(
                color: cell.isFilled ? cell.color.color.opacity(GameTheme.Layout.lowOpacity) :
                      (isLineComplete ? GameTheme.Colors.lineCompletionPrimary.opacity(GameTheme.Layout.mediumOpacity) :
                      (isPreview ? previewColor.opacity(GameTheme.Layout.mediumLowOpacity) : .clear)),
                radius: cell.isFilled ? 3 : (isLineComplete ? 4 : (isPreview ? 3 : 0)),
                x: 0, y: cell.isFilled ? 1 : 0
            )
            .scaleEffect(cell.isFilled ? 1.0 : (isLineComplete ? GameTheme.Layout.slightlyReducedScale : (isPreview ? GameTheme.Layout.minorScale : GameTheme.Layout.reducedScale)))
    }
}

// MARK: - Animation Helper Views

private struct LineCompletePulseView: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(GameTheme.Colors.lineCompletionAccent, lineWidth: 4)
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