import SwiftUI

// MARK: - Visual Effects and Animations

struct LineCleaningEffect: View {
    let rows: Set<Int>
    let cols: Set<Int>
    let gridSize: Int
    let cellSize: CGFloat
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Highlight cleared rows
            ForEach(Array(rows), id: \.self) { row in
                Rectangle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: CGFloat(gridSize) * cellSize, height: cellSize)
                    .position(
                        x: CGFloat(gridSize) * cellSize / 2,
                        y: CGFloat(row) * cellSize + cellSize / 2
                    )
            }
            
            // Highlight cleared columns
            ForEach(Array(cols), id: \.self) { col in
                Rectangle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: cellSize, height: CGFloat(gridSize) * cellSize)
                    .position(
                        x: CGFloat(col) * cellSize + cellSize / 2,
                        y: CGFloat(gridSize) * cellSize / 2
                    )
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(GameTheme.Animations.lineClearAnimation) {
                opacity = 0.0
            }
        }
    }
}

struct ScorePopup: View {
    let score: Int
    let position: CGPoint
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: Double = 1.0
    
    var body: some View {
        Text("+\(score)")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.green)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(offset)
            .position(position)
            .onAppear {
                withAnimation(GameTheme.Animations.mediumSpring) {
                    offset = CGSize(width: 0, height: -50)
                    opacity = 0.0
                    scale = 1.5
                }
            }
    }
}

// MARK: - Enhanced Game State with Animations

extension GameState {
    func placeBlockWithAnimation(_ block: BlockShape, at gridPosition: GridPosition, completion: @escaping () -> Void) {
        guard canPlaceBlock(block, at: gridPosition) else { return }
        
        // Place the block
        for blockPos in block.positions {
            let finalRow = gridPosition.row + blockPos.row
            let finalCol = gridPosition.col + blockPos.col
            grid[finalRow][finalCol].isFilled = true
            grid[finalRow][finalCol].color = block.color
        }
        
        // Add points for placing block
        score += block.positions.count * 10
        
        // Remove the placed block from current blocks
        if let index = currentBlocks.firstIndex(where: { $0.positions == block.positions && $0.color == block.color }) {
            currentBlocks.remove(at: index)
        }
        
        // Faster line clearing with minimal delay
        DispatchQueue.main.asyncAfter(deadline: .now() + GameTheme.GameConfig.lineClearDelay) {
            let _ = self.clearCompletedLines()
            
            // Generate new blocks if all are used
            if self.currentBlocks.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.generateNewBlocks()
                    completion()
                }
            } else {
                completion()
            }
        }
    }
}

// MARK: - Improved Block Shapes with More Variety

extension BlockShape {
    static let enhancedShapes: [BlockShape] = [
        // Single blocks (common)
        BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue),
        
        // 2-block shapes (common)
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)], color: .green),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0)], color: .green),
        
        // 3-block straight lines (common)
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2)], color: .red),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0)], color: .red),
        
        // 3-block L-shapes (medium)
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0)], color: .yellow),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 1)], color: .yellow),
        BlockShape(positions: [GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1)], color: .yellow),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1)], color: .yellow),
        
        // 4-block squares (medium)
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1)], color: .purple),
        
        // 4-block straight lines (less common)
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2), GridPosition(row: 0, col: 3)], color: .orange),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), GridPosition(row: 3, col: 0)], color: .orange),
        
        // Complex L-shapes (less common)
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1)], color: .pink),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2), GridPosition(row: 1, col: 0)], color: .pink),
        BlockShape(positions: [GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 1), GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1)], color: .pink),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1), GridPosition(row: 1, col: 2)], color: .pink),
        
        // T-shapes (less common)
        BlockShape(positions: [GridPosition(row: 0, col: 1), GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1), GridPosition(row: 1, col: 2)], color: .blue),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), GridPosition(row: 1, col: 1)], color: .blue),
        
        // 3x3 square (9 blocks - rare)
        BlockShape(positions: [
            GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 0), GridPosition(row: 1, col: 1), GridPosition(row: 1, col: 2),
            GridPosition(row: 2, col: 0), GridPosition(row: 2, col: 1), GridPosition(row: 2, col: 2)
        ], color: .green),
        
        // 5-block long line (rare)
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1), GridPosition(row: 0, col: 2), GridPosition(row: 0, col: 3), GridPosition(row: 0, col: 4)], color: .red),
        BlockShape(positions: [GridPosition(row: 0, col: 0), GridPosition(row: 1, col: 0), GridPosition(row: 2, col: 0), GridPosition(row: 3, col: 0), GridPosition(row: 4, col: 0)], color: .red)
    ]
}

// MARK: - Weighted Random Block Generation

extension GameState {
    func generateWeightedBlocks() {
        currentBlocks = (0..<3).map { _ in
            // Define weights: smaller blocks are more common
            let weights: [(BlockShape, Int)] = [
                // Single blocks - very common (weight 10)
                (BlockShape.enhancedShapes[0], 10),
                
                // 2-block shapes - common (weight 8)
                (BlockShape.enhancedShapes[1], 8),
                (BlockShape.enhancedShapes[2], 8),
                
                // 3-block shapes - medium (weight 6)
                (BlockShape.enhancedShapes[3], 6),
                (BlockShape.enhancedShapes[4], 6),
                (BlockShape.enhancedShapes[5], 5),
                (BlockShape.enhancedShapes[6], 5),
                (BlockShape.enhancedShapes[7], 5),
                (BlockShape.enhancedShapes[8], 5),
                
                // 4-block shapes - less common (weight 3)
                (BlockShape.enhancedShapes[9], 4),
                (BlockShape.enhancedShapes[10], 3),
                (BlockShape.enhancedShapes[11], 3),
                
                // Complex shapes - uncommon (weight 2)
                (BlockShape.enhancedShapes[12], 2),
                (BlockShape.enhancedShapes[13], 2),
                (BlockShape.enhancedShapes[14], 2),
                (BlockShape.enhancedShapes[15], 2),
                (BlockShape.enhancedShapes[16], 2),
                (BlockShape.enhancedShapes[17], 2),
                
                // Large shapes - rare (weight 1)
                (BlockShape.enhancedShapes[18], 1),
                (BlockShape.enhancedShapes[19], 1),
                (BlockShape.enhancedShapes[20], 1)
            ]
            
            let totalWeight = weights.reduce(0) { $0 + $1.1 }
            let randomValue = Int.random(in: 0..<totalWeight)
            
            var currentWeight = 0
            for (shape, weight) in weights {
                currentWeight += weight
                if randomValue < currentWeight {
                    let randomColor = BlockColor.allCases.randomElement()!
                    return BlockShape(positions: shape.positions, color: randomColor)
                }
            }
            
            // Fallback (should never reach here)
            let randomColor = BlockColor.allCases.randomElement()!
            return BlockShape(positions: BlockShape.enhancedShapes[0].positions, color: randomColor)
        }
        
        checkGameOver()
    }
}