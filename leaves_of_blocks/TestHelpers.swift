import Foundation
import SwiftUI

// MARK: - Test Helpers and Mock Objects

#if DEBUG || TESTING

// MARK: - Mock Game State

class MockGameState: GameState {
    
    // MARK: - Test Properties
    
    var shouldFailBlockPlacement = false
    var forceGameOver = false
    var mockScore = 0
    var mockLinesCleared = 0
    
    // MARK: - Overridden Methods
    
    override func canPlaceBlock(_ block: BlockShape, at gridPosition: GridPosition) -> Bool {
        if shouldFailBlockPlacement {
            return false
        }
        return super.canPlaceBlock(block, at: gridPosition)
    }
    
    override func placeBlock(_ block: BlockShape, at gridPosition: GridPosition) {
        if shouldFailBlockPlacement {
            return
        }
        super.placeBlock(block, at: gridPosition)
    }
    
    override func checkGameOver() {
        if forceGameOver {
            isGameOver = true
            return
        }
        super.checkGameOver()
    }
}

// MARK: - Test Data Generators

struct TestDataGenerator {
    
    // MARK: - Grid Generation
    
    static func createEmptyGrid() -> [[GridCell]] {
        return Array(repeating: Array(repeating: GridCell(), count: GameTheme.GameConfig.gridSize), count: GameTheme.GameConfig.gridSize)
    }
    
    static func createFullGrid() -> [[GridCell]] {
        var grid = createEmptyGrid()
        for row in 0..<GameTheme.GameConfig.gridSize {
            for col in 0..<GameTheme.GameConfig.gridSize {
                grid[row][col].isFilled = true
                grid[row][col].color = .blue
            }
        }
        return grid
    }
    
    static func createGridWithFullRow(at row: Int) -> [[GridCell]] {
        var grid = createEmptyGrid()
        for col in 0..<GameTheme.GameConfig.gridSize {
            grid[row][col].isFilled = true
            grid[row][col].color = .red
        }
        return grid
    }
    
    static func createGridWithFullColumn(at col: Int) -> [[GridCell]] {
        var grid = createEmptyGrid()
        for row in 0..<GameTheme.GameConfig.gridSize {
            grid[row][col].isFilled = true
            grid[row][col].color = .green
        }
        return grid
    }
    
    // MARK: - Block Generation
    
    static func createSingleBlock() -> BlockShape {
        return BlockShape(positions: [GridPosition(row: 0, col: 0)], color: .blue)
    }
    
    static func createLShapeBlock() -> BlockShape {
        return BlockShape(
            positions: [
                GridPosition(row: 0, col: 0),
                GridPosition(row: 1, col: 0),
                GridPosition(row: 2, col: 0),
                GridPosition(row: 2, col: 1)
            ],
            color: .red
        )
    }
    
    static func createRandomBlock() -> BlockShape {
        return BlockShape.allShapes.randomElement() ?? createSingleBlock()
    }
    
    // MARK: - Game State Generation
    
    static func createGameStateWithScore(_ score: Int) -> GameState {
        let gameState = GameState()
        gameState.score = score
        return gameState
    }
    
    static func createGameStateWithFullRow() -> GameState {
        let gameState = GameState()
        gameState.grid = createGridWithFullRow(at: 0)
        return gameState
    }
}

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

// MARK: - UI Testing Helpers

struct UITestHelper {
    
    // MARK: - View State Testing
    
    static func createTestGameState(
        score: Int = 0,
        highScore: Int = 1000,
        linesCleared: Int = 0,
        isGameOver: Bool = false
    ) -> GameState {
        let gameState = GameState()
        gameState.score = score
        gameState.linesCleared = linesCleared
        gameState.isGameOver = isGameOver
        gameState.highScoreManager.updateHighScore(highScore)
        return gameState
    }
    
    static func simulateBlockDrag(
        from startPosition: GridPosition,
        to endPosition: GridPosition,
        with block: BlockShape
    ) -> Bool {
        // Simulate drag and drop logic
        return GameRules.canPlaceBlock(block, at: endPosition, in: TestDataGenerator.createEmptyGrid())
    }
}

// MARK: - Memory Leak Detection

class MemoryLeakDetector {
    
    private static var allocatedObjects: Set<ObjectIdentifier> = []
    
    static func trackObject(_ object: AnyObject) {
        allocatedObjects.insert(ObjectIdentifier(object))
    }
    
    static func releaseObject(_ object: AnyObject) {
        allocatedObjects.remove(ObjectIdentifier(object))
    }
    
    static func reportLeaks() {
        if !allocatedObjects.isEmpty {
            print("⚠️ Memory Leak Warning: \(allocatedObjects.count) objects still allocated")
            for id in allocatedObjects {
                print("  - Object ID: \(id)")
            }
        }
    }
    
    static func reset() {
        allocatedObjects.removeAll()
    }
}

#endif

// MARK: - Debug Menu (Available in Debug builds)

#if DEBUG
struct DebugMenuView: View {
    @ObservedObject var gameState: GameState
    @State private var showingDebugInfo = false
    
    var body: some View {
        VStack {
            Button("Debug Menu") {
                showingDebugInfo.toggle()
            }
            .padding()
            .background(Color.red.opacity(0.2))
            .cornerRadius(8)
            
            if showingDebugInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug Information")
                        .font(.headline)
                    
                    Text("Score: \(gameState.score)")
                    Text("Lines Cleared: \(gameState.linesCleared)")
                    Text("Current Blocks: \(gameState.currentBlocks.count)")
                    Text("Grid Filled Cells: \(countFilledCells())")
                    
                    HStack {
                        Button("Add 1000 Points") {
                            gameState.score += 1000
                        }
                        
                        Button("Clear Grid") {
                            gameState.grid = TestDataGenerator.createEmptyGrid()
                        }
                        
                        Button("Fill Row 0") {
                            gameState.grid = TestDataGenerator.createGridWithFullRow(at: 0)
                        }
                    }
                    
                    Button("Force Game Over") {
                        gameState.isGameOver = true
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
            }
        }
    }
    
    private func countFilledCells() -> Int {
        return gameState.grid.flatMap { $0 }.filter { $0.isFilled }.count
    }
}
#endif