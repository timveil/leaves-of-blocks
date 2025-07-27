//
//  GameEnhancementsTests.swift
//  LeavesOfBlocksTests
//
//  Created by Tim Veil on 7/25/25.
//

import Testing
import Foundation
@testable import LeavesOfBlocks
import SwiftUI

// MARK: - Visual Effects Tests

struct VisualEffectsTests {
    
    @Test("LineCleaningEffect initializes with correct properties")
    func lineCleaningEffectInitialization() {
        let rows: Set<Int> = [0, 2, 5]
        let cols: Set<Int> = [1, 3]
        let gridSize = 8
        let cellSize: CGFloat = 40.0
        
        let effect = LineCleaningEffect(
            rows: rows,
            cols: cols,
            gridSize: gridSize,
            cellSize: cellSize
        )
        
        #expect(effect.rows == rows)
        #expect(effect.cols == cols)
        #expect(effect.gridSize == gridSize)
        #expect(effect.cellSize == cellSize)
    }
    
    @Test("LineCleaningEffect handles empty sets")
    func lineCleaningEffectEmptySets() {
        let effect = LineCleaningEffect(
            rows: [],
            cols: [],
            gridSize: 8,
            cellSize: 40.0
        )
        
        #expect(effect.rows.isEmpty)
        #expect(effect.cols.isEmpty)
    }
    
    @Test("ScorePopup initializes with correct properties")
    func scorePopupInitialization() {
        let score = 150
        let position = CGPoint(x: 100, y: 200)
        
        let popup = ScorePopup(score: score, position: position)
        
        #expect(popup.score == score)
        #expect(popup.position == position)
    }
    
    @Test("ScorePopup handles zero score")
    func scorePopupZeroScore() {
        let popup = ScorePopup(score: 0, position: CGPoint(x: 0, y: 0))
        #expect(popup.score == 0)
    }
    
    @Test("ScorePopup handles large scores")
    func scorePopupLargeScore() {
        let largeScore = 999999
        let popup = ScorePopup(score: largeScore, position: CGPoint(x: 0, y: 0))
        #expect(popup.score == largeScore)
    }
}

// MARK: - Enhanced Block Shapes Tests

struct EnhancedBlockShapesTests {
    
    @Test("Enhanced shapes collection is not empty")
    func enhancedShapesNotEmpty() {
        #expect(!BlockShape.enhancedShapes.isEmpty)
    }
    
    @Test("Enhanced shapes have valid positions")
    func enhancedShapesValidPositions() {
        for shape in BlockShape.enhancedShapes {
            #expect(!shape.positions.isEmpty)
            
            for position in shape.positions {
                #expect(position.row >= 0)
                #expect(position.col >= 0)
            }
        }
    }
    
    @Test("Enhanced shapes include single blocks")
    func enhancedShapesIncludeSingleBlocks() {
        let singleBlocks = BlockShape.enhancedShapes.filter { $0.positions.count == 1 }
        #expect(!singleBlocks.isEmpty)
    }
    
    @Test("Enhanced shapes include various sizes")
    func enhancedShapesIncludeVariousSizes() {
        let shapes = BlockShape.enhancedShapes
        let sizes = Set(shapes.map { $0.positions.count })
        
        #expect(sizes.count > 3, "Should have blocks of different sizes")
        #expect(sizes.contains(1), "Should have single blocks")
        #expect(sizes.contains(2), "Should have double blocks")
        #expect(sizes.contains(3), "Should have triple blocks")
        #expect(sizes.contains(4), "Should have quad blocks")
    }
    
    @Test("Enhanced shapes include complex shapes")
    func enhancedShapesIncludeComplexShapes() {
        let largeShapes = BlockShape.enhancedShapes.filter { $0.positions.count >= 5 }
        #expect(!largeShapes.isEmpty, "Should have some large/complex shapes")
    }
    
    @Test("Enhanced shapes have different colors")
    func enhancedShapesDifferentColors() {
        let colors = Set(BlockShape.enhancedShapes.map { $0.color })
        #expect(colors.count > 1, "Should use different colors")
    }
    
    @Test("Enhanced shapes T-shape validation")
    func enhancedShapesTShapeValidation() {
        let tShapes = BlockShape.enhancedShapes.filter { shape in
            shape.positions.count == 4 && 
            shape.positions.contains { $0.row == 0 && $0.col == 1 } &&
            shape.positions.contains { $0.row == 1 && $0.col == 0 } &&
            shape.positions.contains { $0.row == 1 && $0.col == 1 } &&
            shape.positions.contains { $0.row == 1 && $0.col == 2 }
        }
        
        #expect(!tShapes.isEmpty, "Should have T-shaped blocks")
    }
    
    @Test("Enhanced shapes L-shape validation")
    func enhancedShapesLShapeValidation() {
        let lShapes = BlockShape.enhancedShapes.filter { shape in
            shape.positions.count >= 3 &&
            shape.positions.contains { $0.row == 0 && $0.col == 0 } &&
            shape.positions.contains { $0.row == 0 && $0.col == 1 }
        }
        
        #expect(!lShapes.isEmpty, "Should have L-shaped blocks")
    }
    
    @Test("Enhanced shapes 3x3 square validation")
    func enhancedShapes3x3SquareValidation() {
        let squares = BlockShape.enhancedShapes.filter { $0.positions.count == 9 }
        #expect(!squares.isEmpty, "Should have 3x3 square blocks")
        
        if let square = squares.first {
            // Verify it's actually a 3x3 square
            let minRow = square.positions.map(\.row).min() ?? 0
            let maxRow = square.positions.map(\.row).max() ?? 0
            let minCol = square.positions.map(\.col).min() ?? 0
            let maxCol = square.positions.map(\.col).max() ?? 0
            
            #expect(maxRow - minRow == 2, "Should span 3 rows")
            #expect(maxCol - minCol == 2, "Should span 3 columns")
        }
    }
}

// MARK: - Animation Integration Tests

struct AnimationIntegrationTests {
    
    @Test("PlaceBlockWithAnimation places block correctly")
    func placeBlockWithAnimationPlacesBlock() async {
        let gameState = GameState()
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 2, col: 2)
        
        var completionCalled = false
        
        gameState.placeBlockWithAnimation(block, at: position) {
            completionCalled = true
        }
        
        // Verify block is placed immediately
        #expect(gameState.grid[2][2].isFilled)
        #expect(gameState.grid[2][2].color == .blue)
        
        // Wait for completion
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        #expect(completionCalled)
    }
    
    @Test("PlaceBlockWithAnimation updates score")
    func placeBlockWithAnimationUpdatesScore() {
        let gameState = GameState()
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 0, col: 0)
        let initialScore = gameState.score
        
        gameState.placeBlockWithAnimation(block, at: position) { }
        
        #expect(gameState.score > initialScore)
        #expect(gameState.score == initialScore + 10)
    }
    
    @Test("PlaceBlockWithAnimation removes placed block")
    func placeBlockWithAnimationRemovesPlacedBlock() {
        let gameState = GameState()
        let originalBlockCount = gameState.currentBlocks.count
        let blockToPlace = gameState.currentBlocks.first!
        let position = GridPosition(row: 0, col: 0)
        
        gameState.placeBlockWithAnimation(blockToPlace, at: position) { }
        
        #expect(gameState.currentBlocks.count == originalBlockCount - 1)
        #expect(!gameState.currentBlocks.contains { 
            $0.positions == blockToPlace.positions && $0.color == blockToPlace.color 
        })
    }
    
    @Test("PlaceBlockWithAnimation handles invalid placement")
    func placeBlockWithAnimationInvalidPlacement() {
        let gameState = GameState()
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let invalidPosition = GridPosition(row: -1, col: 0)
        let initialScore = gameState.score
        let originalBlockCount = gameState.currentBlocks.count
        
        gameState.placeBlockWithAnimation(block, at: invalidPosition) { }
        
        // Should not place block or update score
        #expect(gameState.score == initialScore)
        #expect(gameState.currentBlocks.count == originalBlockCount)
    }
    
    @Test("PlaceBlockWithAnimation generates new blocks when empty")
    func placeBlockWithAnimationGeneratesNewBlocks() async {
        let gameState = GameState()
        
        // Place all current blocks
        let allBlocks = gameState.currentBlocks
        var row = 0
        var col = 0
        
        for block in allBlocks {
            if gameState.canPlaceBlock(block, at: GridPosition(row: row, col: col)) {
                gameState.placeBlockWithAnimation(block, at: GridPosition(row: row, col: col)) { }
                col += 2
                if col >= GameState.gridSize {
                    col = 0
                    row += 2
                }
            }
        }
        
        // Wait for new block generation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        #expect(gameState.currentBlocks.count == 3)
    }
}

// MARK: - Performance Tests for Enhancements

struct EnhancementPerformanceTests {
    
    @Test("Enhanced shapes access performance")
    func enhancedShapesAccessPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<10000 {
            let _ = BlockShape.enhancedShapes.randomElement()
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 0.1, "Enhanced shapes access should be fast")
    }
    
    @Test("Visual effect creation performance")
    func visualEffectCreationPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<1000 {
            let _ = LineCleaningEffect(
                rows: Set([i % 8]),
                cols: Set([(i + 1) % 8]),
                gridSize: 8,
                cellSize: 40.0
            )
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 0.1, "Visual effect creation should be fast")
    }
    
    @Test("Score popup creation performance")
    func scorePopupCreationPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<1000 {
            let _ = ScorePopup(
                score: i * 10,
                position: CGPoint(x: Double(i % 100), y: Double(i % 100))
            )
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 0.1, "Score popup creation should be fast")
    }
}

// MARK: - Edge Cases for Enhancements

struct EnhancementEdgeCaseTests {
    
    @Test("LineCleaningEffect with maximum grid size")
    func lineCleaningEffectMaxGridSize() {
        let maxRows = Set(0..<8)
        let maxCols = Set(0..<8)
        
        let effect = LineCleaningEffect(
            rows: maxRows,
            cols: maxCols,
            gridSize: 8,
            cellSize: 40.0
        )
        
        #expect(effect.rows.count == 8)
        #expect(effect.cols.count == 8)
    }
    
    @Test("ScorePopup with extreme positions")
    func scorePopupExtremePositions() {
        let extremePositions = [
            CGPoint(x: -1000, y: -1000),
            CGPoint(x: 10000, y: 10000),
            CGPoint(x: 0, y: 0),
            CGPoint(x: CGFloat.infinity, y: CGFloat.infinity)
        ]
        
        for position in extremePositions {
            let popup = ScorePopup(score: 100, position: position)
            if position.x.isFinite && position.y.isFinite {
                #expect(popup.position == position)
            }
        }
    }
    
    @Test("Enhanced shapes bounds checking")
    func enhancedShapesBoundsChecking() {
        for shape in BlockShape.enhancedShapes {
            let maxRow = shape.positions.map(\.row).max() ?? 0
            let maxCol = shape.positions.map(\.col).max() ?? 0
            
            #expect(maxRow < 8, "Shape should fit within grid bounds")
            #expect(maxCol < 8, "Shape should fit within grid bounds")
        }
    }
    
    @Test("PlaceBlockWithAnimation with concurrent calls")
    func placeBlockWithAnimationConcurrentCalls() async {
        let gameState = GameState()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
                    let position = GridPosition(row: i, col: i)
                    
                    if gameState.canPlaceBlock(block, at: position) {
                        gameState.placeBlockWithAnimation(block, at: position) { }
                    }
                }
            }
        }
        
        // Should handle concurrent access gracefully
        #expect(gameState.score >= 0)
    }
}

// MARK: - Integration Tests for Enhanced Features

struct EnhancedFeaturesIntegrationTests {
    
    @Test("Enhanced shapes work with game logic")
    func enhancedShapesWorkWithGameLogic() {
        let gameState = GameState()
        
        for shape in BlockShape.enhancedShapes.prefix(5) {
            if gameState.canPlaceBlock(shape, at: GridPosition(row: 0, col: 0)) {
                let initialScore = gameState.score
                gameState.placeBlock(shape, at: GridPosition(row: 0, col: 0))
                
                #expect(gameState.score > initialScore)
                break // Only test one placement to avoid conflicts
            }
        }
    }
    
    @Test("Visual effects work with line clearing")
    func visualEffectsWorkWithLineClearing() {
        let gameState = GameState()
        
        // Fill a row manually
        for col in 0..<GameState.gridSize {
            gameState.grid[0][col].isFilled = true
            gameState.grid[0][col].color = .blue
        }
        
        let clearResult = gameState.clearCompletedLines()
        
        // Create visual effect for cleared lines
        let effect = LineCleaningEffect(
            rows: clearResult.clearedRows,
            cols: clearResult.clearedCols,
            gridSize: GameState.gridSize,
            cellSize: 40.0
        )
        
        #expect(effect.rows.contains(0))
        #expect(clearResult.clearedRows.contains(0))
    }
    
    @Test("Score popup coordinates with game scoring")
    func scorePopupCoordinatesWithGameScoring() {
        let gameState = GameState()
        let block = BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
        let position = GridPosition(row: 2, col: 2)
        
        let initialScore = gameState.score
        gameState.placeBlock(block, at: position)
        let scoreIncrease = gameState.score - initialScore
        
        let popup = ScorePopup(
            score: scoreIncrease,
            position: CGPoint(x: 100, y: 100)
        )
        
        #expect(popup.score == scoreIncrease)
        #expect(popup.score == 10) // Single block placement
    }
}