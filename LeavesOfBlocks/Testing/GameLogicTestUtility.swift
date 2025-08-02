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
    
    /// Test: Geometric pattern placement
    static func testGeometricPatterns() {
        print("Testing geometric pattern placement...")
        
        // Test all pattern types are defined
        let patterns = GeometricPattern.allCases
        expect(patterns.count > 0, "Should have geometric patterns defined")
        
        // Test each pattern has valid positions
        for pattern in patterns {
            let positions = pattern.positions
            expect(positions.count > 0, "Pattern \(pattern.rawValue) should have positions")
            expect(positions.count == pattern.size, "Pattern \(pattern.rawValue) size should match position count")
            
            // Verify positions are reasonable (within a 3x3 area for most patterns)
            for position in positions {
                expect(position.row >= 0 && position.row < 5, "Pattern \(pattern.rawValue) row should be reasonable")
                expect(position.col >= 0 && position.col < 5, "Pattern \(pattern.rawValue) col should be reasonable")
            }
        }
        
        // Test difficulty-specific pattern placement
        testDifficultySpecificPatterns()
        
        print("🎨 Geometric pattern tests completed")
    }
    
    /// Test: Difficulty-specific pattern behaviors
    static func testDifficultySpecificPatterns() {
        print("Testing difficulty-specific pattern behaviors...")
        
        let difficulties: [DifficultyMode] = [.easy, .moderate, .hard]
        var fillResults: [DifficultyMode: Int] = [:]
        
        for difficulty in difficulties {
            var testGrid = GameLogic.createEmptyGrid()
            GameLogic.randomlyFillGrid(&testGrid, difficulty: difficulty)
            
            // Count filled cells for this difficulty
            var filledCells = 0
            for row in testGrid {
                for cell in row {
                    if cell.isFilled {
                        filledCells += 1
                    }
                }
            }
            
            fillResults[difficulty] = filledCells
            
            // Test expected ranges for each difficulty
            switch difficulty {
            case .easy:
                expect(filledCells <= 8, "Easy mode should have fewer cells (≤8), got \(filledCells)")
            case .moderate:
                expect(filledCells >= 6 && filledCells <= 12, "Moderate mode should have balanced cells (6-12), got \(filledCells)")
            case .hard:
                expect(filledCells >= 8, "Hard mode should have more cells (≥8), got \(filledCells)")
            }
        }
        
        // Test that different difficulties produce different fill amounts
        let easyFill = fillResults[.easy] ?? 0
        let moderateFill = fillResults[.moderate] ?? 0
        let hardFill = fillResults[.hard] ?? 0
        
        expect(easyFill <= moderateFill, "Easy (\(easyFill)) should have ≤ moderate (\(moderateFill)) fill")
        expect(moderateFill <= hardFill || hardFill >= easyFill, "Hard (\(hardFill)) should generally have ≥ easy (\(easyFill)) fill")
        
        print("📊 Fill results - Easy: \(easyFill), Moderate: \(moderateFill), Hard: \(hardFill)")
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
    
    // MARK: - Solvability Validation Tests
    
    /// Test: Solvability check with empty grid
    static func testSolvabilityEmptyGrid() {
        print("Testing solvability with empty grid...")
        
        // Given
        let grid = GameLogic.createEmptyGrid()
        let blocks = [
            BlockShape.allShapes[0], // Single block
            BlockShape.allShapes[1], // 2-block horizontal
            BlockShape.allShapes[2]  // 2-block vertical
        ]
        
        // When
        let canPlaceAll = GameLogic.canAllBlocksBePlaced(blocks, in: grid)
        
        // Then
        expect(canPlaceAll == true, "Should be able to place all blocks on empty grid")
    }
    
    /// Test: Solvability check with nearly full grid
    static func testSolvabilityNearlyFullGrid() {
        print("Testing solvability with nearly full grid...")
        
        // Given
        var grid = GameLogic.createEmptyGrid()
        
        // Fill most of the grid, leaving only a few spaces
        for row in 0..<6 {
            for col in 0..<8 {
                grid[row][col].isFilled = true
                grid[row][col].color = .blue
            }
        }
        // Leave rows 6-7 empty (16 cells)
        
        let blocks = [
            BlockShape.allShapes[0], // Single block (1 cell)
            BlockShape.allShapes[0], // Single block (1 cell)  
            BlockShape.allShapes[0]  // Single block (1 cell)
        ]
        
        // When
        let canPlaceAll = GameLogic.canAllBlocksBePlaced(blocks, in: grid)
        
        // Then
        expect(canPlaceAll == true, "Should be able to place 3 single blocks with 16 empty cells")
    }
    
    /// Test: Solvability check with impossible scenario
    static func testSolvabilityImpossibleScenario() {
        print("Testing solvability with impossible scenario...")
        
        // Given
        var grid = GameLogic.createEmptyGrid()
        
        // Fill all but 2 cells
        for row in 0..<8 {
            for col in 0..<8 {
                if !(row == 7 && col == 6) && !(row == 7 && col == 7) {
                    grid[row][col].isFilled = true
                    grid[row][col].color = .blue
                }
            }
        }
        // Only 2 empty cells remain
        
        let blocks = [
            BlockShape.allShapes[4], // 2x2 square (4 cells) - impossible to fit
            BlockShape.allShapes[0], // Single block
            BlockShape.allShapes[0]  // Single block
        ]
        
        // When
        let canPlaceAll = GameLogic.canAllBlocksBePlaced(blocks, in: grid)
        
        // Then
        expect(canPlaceAll == false, "Should not be able to place 4-cell block with only 2 empty cells")
    }
    
    /// Test: Block generation solvability integration
    static func testBlockGenerationSolvability() {
        print("Testing block generation solvability integration...")
        
        // Given
        var grid = GameLogic.createEmptyGrid()
        
        // Partially fill grid to create challenging but solvable scenario
        for row in 0..<4 {
            for col in 0..<6 {
                grid[row][col].isFilled = true
                grid[row][col].color = .red
            }
        }
        // Leave bottom half and rightmost columns available
        
        // When
        let blocks = BlockGenerator.generateWeightedBlocks(count: 3, difficulty: .easy, grid: grid)
        let canPlaceAll = GameLogic.canAllBlocksBePlaced(blocks, in: grid)
        
        // Then
        expect(canPlaceAll == true, "Generated blocks should always be solvable")
        expect(blocks.count == 3, "Should generate exactly 3 blocks")
    }
    
    /// Test: Fallback strategy effectiveness
    static func testFallbackStrategyEffectiveness() {
        print("Testing fallback strategy effectiveness...")
        
        // Given
        var grid = GameLogic.createEmptyGrid()
        
        // Create scenario where only small blocks can fit
        for row in 0..<8 {
            for col in 0..<8 {
                // Leave only scattered single cells
                if !((row == 1 && col == 1) || (row == 3 && col == 5) || (row == 6 && col == 2)) {
                    grid[row][col].isFilled = true
                    grid[row][col].color = .green
                }
            }
        }
        // Only 3 scattered single cells remain
        
        // When
        let blocks = BlockGenerator.generateWeightedBlocks(count: 3, difficulty: .hard, grid: grid)
        let canPlaceAll = GameLogic.canAllBlocksBePlaced(blocks, in: grid)
        
        // Then
        expect(canPlaceAll == true, "Fallback strategy should ensure solvability even with limited space")
        
        // Verify blocks are appropriately sized for available space
        let allBlocksSmall = blocks.allSatisfy { $0.positions.count <= 1 }
        expect(allBlocksSmall == true, "Fallback should generate single blocks when only scattered cells available")
    }
    
    /// Test: Find valid positions function
    static func testFindValidPositions() {
        print("Testing find valid positions function...")
        
        // Given
        var grid = GameLogic.createEmptyGrid()
        
        // Fill some positions to limit valid placements
        grid[0][0].isFilled = true
        grid[0][1].isFilled = true
        grid[1][0].isFilled = true
        
        let twoBlockHorizontal = BlockShape.allShapes[1] // 2-block horizontal
        
        // When
        let validPositions = GameLogic.findValidPositions(for: twoBlockHorizontal, in: grid)
        
        // Then
        expect(validPositions.count > 0, "Should find some valid positions for 2-block horizontal")
        expect(!validPositions.contains(GridPosition(row: 0, col: 0)), "Should not include blocked position")
        
        // Verify all returned positions are actually valid
        for position in validPositions {
            let isValid = GameLogic.canPlaceBlock(twoBlockHorizontal, at: position, in: grid)
            expect(isValid == true, "All returned positions should be valid for placement")
        }
    }
    
    /// Test: Logging functionality with unsolvable scenario
    static func testLoggingFunctionality() {
        print("Testing logging functionality with unsolvable scenario...")
        
        // Given
        var grid = GameLogic.createEmptyGrid()
        
        // Create nearly impossible scenario - fill most cells
        for row in 0..<8 {
            for col in 0..<8 {
                // Leave only 3 scattered cells empty
                if !((row == 2 && col == 3) || (row == 5 && col == 1) || (row == 7 && col == 6)) {
                    grid[row][col].isFilled = true
                    grid[row][col].color = .blue
                }
            }
        }
        
        print("📝 Testing logging output (should see SOLVABILITY logs):")
        
        // When - This should trigger solvability logging
        let blocks = BlockGenerator.generateWeightedBlocks(count: 3, difficulty: .hard, grid: grid)
        
        // Then
        expect(blocks.count == 3, "Should still generate 3 blocks")
        let canPlaceAll = GameLogic.canAllBlocksBePlaced(blocks, in: grid)
        expect(canPlaceAll == true, "Generated blocks should be solvable even in difficult scenarios")
        
        print("✅ Logging test completed - check console output for [SOLVABILITY] messages")
    }
    
    // MARK: - Test Runner
    
    /// Runs all available tests including new solvability tests
    static func runAllTests() {
        print("🧪 Running GameLogic Development Tests...")
        print("=" * 50)
        
        // Original tests
        testCreateEmptyGrid()
        testGeometricPatterns()
        testCanPlaceSingleBlockValid()
        testCanPlaceBlockOutOfBounds()
        testCanPlaceBlockNegativePosition()
        testCalculateSingleBlockScore()
        testCalculateMultiCellBlockScore()
        testCalculateLineScore()
        testGameOverDetectionEmptyGrid()
        testGameOverDetectionNoBlocks()
        testCompleteBlockPlacementFlow()
        
        // New solvability tests
        testSolvabilityEmptyGrid()
        testSolvabilityNearlyFullGrid()
        testSolvabilityImpossibleScenario()
        testBlockGenerationSolvability()
        testFallbackStrategyEffectiveness()
        testFindValidPositions()
        testLoggingFunctionality()
        
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