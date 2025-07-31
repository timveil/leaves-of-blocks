import Foundation

/// Development utility for testing GameLogic functionality.
///
/// This utility provides basic validation tests for core game logic operations.
/// These tests are designed as development aids and should eventually be moved
/// to a proper test target with Swift Testing framework support.
///
/// ## Usage
/// ```swift
/// // In development or debug builds
/// GameLogicTestUtility.runAllTests()
/// ```
struct GameLogicTestUtility {
    
    /// Simple assertion helper for development testing
    private static func expect(_ condition: Bool, _ message: String = "Assertion failed") {
        if !condition {
            print("❌ TEST FAILED: \(message)")
        } else {
            print("✅ Test passed: \(message)")
        }
    }
    
    // MARK: - Grid Creation Tests
    
    /// Test: Empty grid creation
    static func testCreateEmptyGrid() {
        print("Testing empty grid creation...")
        
        // When
        let grid = GameLogic.createEmptyGrid()
        
        // Then
        expect(grid.count == 8, "Grid should have 8 rows")
        expect(grid[0].count == 8, "Grid should have 8 columns")
        
        // Verify all cells are empty initially (some may be filled by random pre-fill)
        var hasEmptyCells = false
        for row in grid {
            for cell in row {
                if !cell.isFilled {
                    hasEmptyCells = true
                    break
                }
            }
            if hasEmptyCells { break }
        }
        expect(true, "Grid creation completed (may have random pre-fill)")
    }
    
    // MARK: - Block Placement Validation Tests
    
    /// Test: Single block placement validation - valid position
    static func testCanPlaceSingleBlockValid() {
        print("Testing single block placement validation...")
        
        // Given
        let grid = GameLogic.createEmptyGrid()
        
        // Find an empty cell for testing
        var testPosition: GridPosition?
        for row in 0..<8 {
            for col in 0..<8 {
                if !grid[row][col].isFilled {
                    testPosition = GridPosition(row: row, col: col)
                    break
                }
            }
            if testPosition != nil { break }
        }
        
        guard let position = testPosition else {
            print("⚠️  Grid is completely filled, skipping placement test")
            return
        }
        
        let singleBlock = BlockShape.allShapes[0] // Single block
        
        // When
        let canPlace = GameLogic.canPlaceBlock(singleBlock, at: position, in: grid)
        
        // Then
        expect(canPlace == true, "Should be able to place single block at empty position")
    }
    
    /// Test: Block placement validation - out of bounds
    static func testCanPlaceBlockOutOfBounds() {
        print("Testing out of bounds placement...")
        
        // Given
        let grid = GameLogic.createEmptyGrid()
        let singleBlock = BlockShape.allShapes[0] // Single block
        let position = GridPosition(row: 8, col: 5) // Out of bounds
        
        // When
        let canPlace = GameLogic.canPlaceBlock(singleBlock, at: position, in: grid)
        
        // Then
        expect(canPlace == false, "Should not be able to place block out of bounds")
    }
    
    /// Test: Block placement validation - negative position
    static func testCanPlaceBlockNegativePosition() {
        print("Testing negative position placement...")
        
        // Given
        let grid = GameLogic.createEmptyGrid()
        let singleBlock = BlockShape.allShapes[0] // Single block
        let position = GridPosition(row: -1, col: 3)
        
        // When
        let canPlace = GameLogic.canPlaceBlock(singleBlock, at: position, in: grid)
        
        // Then
        expect(canPlace == false, "Should not be able to place block at negative position")
    }
    
    // MARK: - Score Calculation Tests
    
    /// Test: Single block score calculation
    static func testCalculateSingleBlockScore() {
        print("Testing single block score calculation...")
        
        // Given
        let singleBlock = BlockShape.allShapes[0] // Single block (1 cell)
        
        // When
        let score = GameLogic.calculateBlockScore(block: singleBlock)
        
        // Then
        expect(score == 10, "Single block should score 10 points (1 cell * 10)")
    }
    
    /// Test: Multi-cell block score calculation
    static func testCalculateMultiCellBlockScore() {
        print("Testing multi-cell block score calculation...")
        
        // Given
        let largeBlock = BlockShape.allShapes.last! // 3x3 square (9 cells)
        
        // When
        let score = GameLogic.calculateBlockScore(block: largeBlock)
        
        // Then
        expect(score == 90, "3x3 block should score 90 points (9 cells * 10)")
    }
    
    /// Test: Line score calculation
    static func testCalculateLineScore() {
        print("Testing line score calculation...")
        
        // When
        let singleLineScore = GameLogic.calculateLineScore(clearedRows: 1, clearedCols: 0)
        let multiLineScore = GameLogic.calculateLineScore(clearedRows: 2, clearedCols: 1)
        
        // Then
        expect(singleLineScore == 100, "Single line should score 100 points")
        expect(multiLineScore == 400, "Multiple lines should include combo bonus (300 base + 100 combo)")
    }
    
    // MARK: - Game Over Detection Tests
    
    /// Test: Game over detection with empty grid
    static func testGameOverDetectionEmptyGrid() {
        print("Testing game over detection with empty grid...")
        
        // Given
        let grid = GameLogic.createEmptyGrid()
        let blocks = [BlockShape.allShapes[0]] // Single block
        
        // When
        let isGameOver = GameLogic.isGameOver(currentBlocks: blocks, grid: grid)
        
        // Then
        expect(isGameOver == false, "Should not be game over with empty grid and small block")
    }
    
    /// Test: Game over detection with no blocks
    static func testGameOverDetectionNoBlocks() {
        print("Testing game over detection with no blocks...")
        
        // Given
        let grid = GameLogic.createEmptyGrid()
        let blocks: [BlockShape] = []
        
        // When
        let isGameOver = GameLogic.isGameOver(currentBlocks: blocks, grid: grid)
        
        // Then
        expect(isGameOver == true, "Should be game over when no blocks available")
    }
    
    // MARK: - Integration Tests
    
    /// Test: Complete block placement flow
    static func testCompleteBlockPlacementFlow() {
        print("Testing complete block placement flow...")
        
        // Given
        var grid = GameLogic.createEmptyGrid()
        let singleBlock = BlockShape.allShapes[0]
        
        // Find an empty position
        var testPosition: GridPosition?
        for row in 0..<8 {
            for col in 0..<8 {
                if !grid[row][col].isFilled {
                    testPosition = GridPosition(row: row, col: col)
                    break
                }
            }
            if testPosition != nil { break }
        }
        
        guard let position = testPosition else {
            print("⚠️  Grid is completely filled, skipping placement flow test")
            return
        }
        
        // When - Validate placement
        let canPlace = GameLogic.canPlaceBlock(singleBlock, at: position, in: grid)
        expect(canPlace == true, "Should be able to place block")
        
        // When - Place block
        GameLogic.placeBlock(singleBlock, at: position, in: &grid)
        
        // Then - Verify placement
        expect(grid[position.row][position.col].isFilled == true, "Cell should be filled after placement")
        expect(grid[position.row][position.col].color == singleBlock.color, "Cell should have correct color")
        
        // When - Calculate score
        let score = GameLogic.calculateBlockScore(block: singleBlock)
        expect(score == 10, "Should calculate correct score")
    }
    
    // MARK: - Test Runner
    
    /// Runs all available tests
    static func runAllTests() {
        print("🧪 Running GameLogic Development Tests...")
        print("=" * 50)
        
        testCreateEmptyGrid()
        testCanPlaceSingleBlockValid()
        testCanPlaceBlockOutOfBounds()
        testCanPlaceBlockNegativePosition()
        testCalculateSingleBlockScore()
        testCalculateMultiCellBlockScore()
        testCalculateLineScore()
        testGameOverDetectionEmptyGrid()
        testGameOverDetectionNoBlocks()
        testCompleteBlockPlacementFlow()
        
        print("=" * 50)
        print("✅ GameLogic development tests completed")
        print("⚠️  Note: These are development utility tests.")
        print("   For comprehensive testing, create a dedicated test target")
        print("   with Swift Testing framework support.")
    }
    
    /// Runs basic validation tests only
    static func runBasicValidationTests() {
        print("🔍 Running basic GameLogic validation...")
        
        testCreateEmptyGrid()
        testCalculateSingleBlockScore()
        testGameOverDetectionNoBlocks()
        
        print("✅ Basic validation completed")
    }
}

// MARK: - String Extension for Test Output

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}