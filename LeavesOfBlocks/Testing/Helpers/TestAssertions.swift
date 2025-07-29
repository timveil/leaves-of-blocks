import Foundation
import SwiftUI

// MARK: - Test Assertions and Performance Testing

#if DEBUG || TESTING

// MARK: - Test Assertions

struct TestAssertions {
    
    // MARK: - Grid Assertions
    
    static func assertGridIsEmpty(_ grid: [[GridCell]], file: StaticString = #file, line: UInt = #line) {
        for row in grid {
            for cell in row {
                assert(!cell.isFilled, "Expected empty grid but found filled cell", file: file, line: line)
            }
        }
    }
    
    static func assertGridIsFull(_ grid: [[GridCell]], file: StaticString = #file, line: UInt = #line) {
        for row in grid {
            for cell in row {
                assert(cell.isFilled, "Expected full grid but found empty cell", file: file, line: line)
            }
        }
    }
    
    static func assertRowIsFull(_ grid: [[GridCell]], row: Int, file: StaticString = #file, line: UInt = #line) {
        for cell in grid[row] {
            assert(cell.isFilled, "Expected full row \(row) but found empty cell", file: file, line: line)
        }
    }
    
    static func assertColumnIsFull(_ grid: [[GridCell]], col: Int, file: StaticString = #file, line: UInt = #line) {
        for row in 0..<grid.count {
            assert(grid[row][col].isFilled, "Expected full column \(col) but found empty cell at row \(row)", file: file, line: line)
        }
    }
    
    // MARK: - Game State Assertions
    
    static func assertValidScore(_ score: Int, file: StaticString = #file, line: UInt = #line) {
        assert(score >= 0, "Score should not be negative: \(score)", file: file, line: line)
    }
    
    static func assertValidGameState(_ gameState: GameState, file: StaticString = #file, line: UInt = #line) {
        let errors = GameStateValidator.validateGameState(gameState)
        assert(errors.isEmpty, "Game state validation failed: \(errors)", file: file, line: line)
    }
}

// MARK: - Performance Testing

struct PerformanceTestHelper {
    
    // MARK: - Load Testing
    
    static func stressTestBlockPlacement(iterations: Int = 1000) {
        let gameState = GameState()
        
        let (_, time) = PerformanceMonitor.measureExecutionTime {
            for _ in 0..<iterations {
                let block = TestDataGenerator.createRandomBlock()
                let position = GridPosition(
                    row: Int.random(in: 0..<GameTheme.GameConfig.gridSize-1),
                    col: Int.random(in: 0..<GameTheme.GameConfig.gridSize-1)
                )
                
                if gameState.canPlaceBlock(block, at: position) {
                    gameState.placeBlock(block, at: position)
                }
            }
        }
        
        PerformanceMonitor.logPerformanceWarning(
            operation: "Block placement stress test (\(iterations) iterations)",
            time: time,
            threshold: 1.0 // 1 second threshold for stress test
        )
    }
    
    static func measureGridValidation() {
        let grid = TestDataGenerator.createFullGrid()
        
        let (_, time) = PerformanceMonitor.measureExecutionTime {
            let _ = GameRules.findCompletedLines(in: grid)
        }
        
        PerformanceMonitor.logPerformanceWarning(
            operation: "Grid validation (full grid)",
            time: time
        )
    }
}

#endif