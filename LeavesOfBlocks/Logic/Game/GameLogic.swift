import Foundation

// MARK: - Game Logic Service

// MARK: - Difficulty Pattern Configuration

/// Configuration for geometric pattern placement based on difficulty mode
private struct DifficultyPatternConfig {
    let targetFillPercentage: Double
    let allowedPatterns: [GeometricPattern]
    let patternWeights: [GeometricPattern: Double]
    
    static func forDifficulty(_ difficulty: DifficultyMode) -> DifficultyPatternConfig {
        switch difficulty {
        case .easy:
            return DifficultyPatternConfig(
                targetFillPercentage: 0.09, // 8-10% fill - fewer obstacles
                allowedPatterns: [.line2, .diagonal, .corner], // Simple patterns only
                patternWeights: [
                    .line2: 3.0,    // Favor simple 2-cell lines
                    .diagonal: 2.5, // Moderate diagonal preference
                    .corner: 2.0    // Some L-corners
                ]
            )
            
        case .moderate:
            return DifficultyPatternConfig(
                targetFillPercentage: 0.135, // 12-15% fill - balanced
                allowedPatterns: GeometricPattern.allCases, // All patterns available
                patternWeights: [
                    .line2: 2.0,
                    .line3: 2.0,
                    .corner: 2.0,
                    .diagonal: 1.5,
                    .square2x2: 1.5,
                    .triangle: 1.5,
                    .zigzag: 1.0,
                    .cross: 1.0     // Cross patterns less common
                ]
            )
            
        case .hard:
            return DifficultyPatternConfig(
                targetFillPercentage: 0.175, // 15-20% fill - more obstacles
                allowedPatterns: [.line3, .square2x2, .cross, .triangle, .zigzag, .corner], // Complex patterns
                patternWeights: [
                    .cross: 3.0,     // Favor complex 5-cell crosses
                    .square2x2: 2.5, // 2x2 squares common
                    .zigzag: 2.5,    // Zigzag patterns
                    .triangle: 2.0,  // Triangle shapes
                    .line3: 1.5,     // 3-cell lines
                    .corner: 1.0     // Some L-corners
                ]
            )
        }
    }
}

/// Handles all game logic operations separate from state management.
///
/// This is a static-only namespace; all members are `static`. Declared as an
/// `enum` (without cases) so it cannot be accidentally instantiated.
enum GameLogic {
    
    // MARK: - Block Placement Logic
    
    /// Validates if a block can be placed at the specified position
    static func canPlaceBlock(_ block: BlockShape, at gridPosition: GridPosition, in grid: [[GridCell]]) -> Bool {
        switch block.type {
        case .horizontalClear, .verticalClear, .areaClear:
            // All special blocks require a valid grid position
            return isValidGridPosition(gridPosition)
            
        case .normal:
            // Normal block placement validation
            for blockPos in block.positions {
                let finalRow = gridPosition.row + blockPos.row
                let finalCol = gridPosition.col + blockPos.col
                
                // Check bounds
                if finalRow < 0 || finalRow >= AppConfiguration.GameRules.gridSize || 
                   finalCol < 0 || finalCol >= AppConfiguration.GameRules.gridSize {
                    return false
                }
                
                // Check if cell is already filled
                if grid[finalRow][finalCol].isFilled {
                    return false
                }
            }
            return true
        }
    }
    
    /// Places a block on the grid and returns the updated grid
    static func placeBlock(_ block: BlockShape, at gridPosition: GridPosition, in grid: inout [[GridCell]]) {
        switch block.type {
        case .horizontalClear:
            // Clear the entire row where the special block is placed
            let targetRow = gridPosition.row
            if targetRow >= 0 && targetRow < AppConfiguration.GameRules.gridSize {
                for col in 0..<AppConfiguration.GameRules.gridSize {
                    grid[targetRow][col] = GridCell()  // Reset to default state
                }
            }
            
        case .verticalClear:
            // Clear the entire column where the special block is placed
            let targetCol = gridPosition.col
            if targetCol >= 0 && targetCol < AppConfiguration.GameRules.gridSize {
                for row in 0..<AppConfiguration.GameRules.gridSize {
                    grid[row][targetCol] = GridCell()  // Reset to default state
                }
            }
            
        case .areaClear:
            // Clear a 3x3 area centered on the placement position
            let centerRow = gridPosition.row
            let centerCol = gridPosition.col
            
            // Clear 3x3 area (one cell in each direction from center)
            for rowOffset in -1...1 {
                for colOffset in -1...1 {
                    let targetRow = centerRow + rowOffset
                    let targetCol = centerCol + colOffset
                    let targetPosition = GridPosition(row: targetRow, col: targetCol)
                    
                    // Only clear cells that are within grid bounds
                    if isValidGridPosition(targetPosition) {
                        grid[targetRow][targetCol] = GridCell()  // Reset to default state
                    }
                }
            }
            
        case .normal:
            // Normal block placement
            for blockPos in block.positions {
                let finalRow = gridPosition.row + blockPos.row
                let finalCol = gridPosition.col + blockPos.col
                
                grid[finalRow][finalCol].isFilled = true
                grid[finalRow][finalCol].color = block.color
            }
        }
    }
    
    // MARK: - Line Clearing Logic
    
    /// Finds and clears completed lines, returning information about cleared cells
    static func clearCompletedLines(in grid: inout [[GridCell]]) -> (clearedRows: Set<Int>, clearedCols: Set<Int>, clearedCells: [ClearedCell]) {
        var clearedRows: Set<Int> = []
        var clearedCols: Set<Int> = []
        var clearedCells: [ClearedCell] = []
        
        // Check rows
        for row in 0..<AppConfiguration.GameRules.gridSize {
            if grid[row].allSatisfy({ $0.isFilled }) {
                clearedRows.insert(row)
            }
        }
        
        // Check columns
        for col in 0..<AppConfiguration.GameRules.gridSize {
            if (0..<AppConfiguration.GameRules.gridSize).allSatisfy({ grid[$0][col].isFilled }) {
                clearedCols.insert(col)
            }
        }
        
        // Collect cell information before clearing
        for row in clearedRows {
            for col in 0..<AppConfiguration.GameRules.gridSize {
                clearedCells.append(ClearedCell(row: row, col: col, color: grid[row][col].color))
            }
        }
        
        for col in clearedCols {
            for row in 0..<AppConfiguration.GameRules.gridSize {
                // Avoid double-counting cells that are in both cleared rows and columns
                if !clearedRows.contains(row) {
                    clearedCells.append(ClearedCell(row: row, col: col, color: grid[row][col].color))
                }
            }
        }
        
        // Clear the lines
        for row in clearedRows {
            for col in 0..<AppConfiguration.GameRules.gridSize {
                grid[row][col] = GridCell()
            }
        }
        
        for col in clearedCols {
            for row in 0..<AppConfiguration.GameRules.gridSize {
                grid[row][col] = GridCell()
            }
        }
        
        return (clearedRows, clearedCols, clearedCells)
    }

    /// Determines which rows and columns would be fully filled if the given
    /// block were placed at the given position, without mutating the grid.
    ///
    /// Used by the drag preview to highlight "good move" placements before
    /// the player commits.
    static func linesThatWouldClear(placing block: BlockShape, at position: GridPosition, in grid: [[GridCell]]) -> (rows: Set<Int>, cols: Set<Int>) {
        guard canPlaceBlock(block, at: position, in: grid) else { return ([], []) }

        var simulated = grid
        placeBlock(block, at: position, in: &simulated)

        let size = AppConfiguration.GameRules.gridSize
        var rows: Set<Int> = []
        var cols: Set<Int> = []

        for row in 0..<size where simulated[row].allSatisfy({ $0.isFilled }) {
            rows.insert(row)
        }
        for col in 0..<size where (0..<size).allSatisfy({ simulated[$0][col].isFilled }) {
            cols.insert(col)
        }

        return (rows, cols)
    }

    // MARK: - Hint Logic

    /// A suggested placement returned by `findHint`. Captures everything the
    /// view layer needs to render the highlight without re-deriving footprints
    /// for special blocks.
    struct Hint: Equatable {
        let blockIndex: Int
        let block: BlockShape
        let position: GridPosition
        let willClearLines: Bool
        /// The absolute grid cells the placement would affect — already
        /// resolved through special-block footprints so the view layer can
        /// pulse them directly.
        let highlightedCells: [GridPosition]
    }

    /// Finds a hint placement for the player. Prefers placements that
    /// immediately clear at least one line; otherwise returns the placement
    /// that sits against the most existing blocks (consolidating the board
    /// rather than stranding a piece alone in the top-left corner), breaking
    /// ties by scan order. Returns `nil` when no block in `blocks` can be
    /// placed anywhere on `grid`.
    ///
    /// Pure / side-effect-free. Worst-case cost is `O(|blocks| × gridSize²)`
    /// validity probes; line-clearing simulation runs only on valid candidates
    /// until the first clearing hit is found.
    static func findHint(blocks: [BlockShape], grid: [[GridCell]]) -> Hint? {
        let size = AppConfiguration.GameRules.gridSize
        var bestFallback: Hint?
        var bestAdjacency = -1

        for (index, block) in blocks.enumerated() {
            for row in 0..<size {
                for col in 0..<size {
                    let position = GridPosition(row: row, col: col)
                    guard canPlaceBlock(block, at: position, in: grid) else { continue }

                    let preview = linesThatWouldClear(placing: block, at: position, in: grid)
                    let willClear = !preview.rows.isEmpty || !preview.cols.isEmpty
                    let hint = Hint(
                        blockIndex: index,
                        block: block,
                        position: position,
                        willClearLines: willClear,
                        highlightedCells: highlightedCells(for: block, at: position)
                    )
                    if willClear { return hint }

                    // Fallback ranking: prefer the placement whose footprint
                    // touches the most filled cells. On an empty board every
                    // candidate scores 0, so the first (top-left) placement
                    // wins — unchanged from the old behavior; mid-game this
                    // points at a useful, board-consolidating move instead.
                    let adjacency = filledNeighborCount(for: block, at: position, in: grid)
                    if adjacency > bestAdjacency {
                        bestAdjacency = adjacency
                        bestFallback = hint
                    }
                }
            }
        }
        return bestFallback
    }

    /// Counts how many of `block`'s occupied cells (placed at `position`) sit
    /// orthogonally against a filled grid cell. Used to rank non-clearing hint
    /// candidates toward consolidating placements. Edges don't count — only
    /// existing blocks — so an empty grid scores every placement 0.
    private static func filledNeighborCount(for block: BlockShape, at position: GridPosition, in grid: [[GridCell]]) -> Int {
        let size = AppConfiguration.GameRules.gridSize
        let occupied = Set(block.positions.map {
            GridPosition(row: position.row + $0.row, col: position.col + $0.col)
        })
        var count = 0
        for cell in occupied {
            let neighbors = [
                GridPosition(row: cell.row - 1, col: cell.col),
                GridPosition(row: cell.row + 1, col: cell.col),
                GridPosition(row: cell.row, col: cell.col - 1),
                GridPosition(row: cell.row, col: cell.col + 1)
            ]
            for n in neighbors where n.row >= 0 && n.row < size && n.col >= 0 && n.col < size {
                if !occupied.contains(n) && grid[n.row][n.col].isFilled {
                    count += 1
                }
            }
        }
        return count
    }

    /// Resolves the absolute grid cells affected by placing `block` at
    /// `position`, including the row / column / 3x3 footprint of special
    /// blocks. A special block's own shape is ignored — only `position`
    /// decides its footprint.
    ///
    /// The 3x3 area-clear footprint is clipped to the grid, since it is the
    /// only case that can overhang an edge from a legal placement. A normal
    /// block's cells are translated as they are: callers place it only where
    /// `canPlaceBlock` already said it fits, so every cell is in bounds.
    static func highlightedCells(for block: BlockShape, at position: GridPosition) -> [GridPosition] {
        let size = AppConfiguration.GameRules.gridSize
        switch block.type {
        case .normal:
            return block.positions.map {
                GridPosition(row: position.row + $0.row, col: position.col + $0.col)
            }
        case .horizontalClear:
            return (0..<size).map { GridPosition(row: position.row, col: $0) }
        case .verticalClear:
            return (0..<size).map { GridPosition(row: $0, col: position.col) }
        case .areaClear:
            var cells: [GridPosition] = []
            for rowOffset in -1...1 {
                for colOffset in -1...1 {
                    let r = position.row + rowOffset
                    let c = position.col + colOffset
                    if r >= 0, r < size, c >= 0, c < size {
                        cells.append(GridPosition(row: r, col: c))
                    }
                }
            }
            return cells
        }
    }

    // MARK: - Game Over Logic

    /// Checks if any of the current blocks can be placed on the grid
    static func isGameOver(currentBlocks: [BlockShape], grid: [[GridCell]]) -> Bool {
        for block in currentBlocks {
            if canPlaceAnyBlock(block, in: grid) {
                return false
            }
        }
        return true
    }
    
    /// Checks if a specific block can be placed anywhere on the grid
    private static func canPlaceAnyBlock(_ block: BlockShape, in grid: [[GridCell]]) -> Bool {
        for row in 0..<AppConfiguration.GameRules.gridSize {
            for col in 0..<AppConfiguration.GameRules.gridSize {
                let position = GridPosition(row: row, col: col)
                if canPlaceBlock(block, at: position, in: grid) {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Score Calculation
    
    /// Calculates score for placing a block
    static func calculateBlockScore(block: BlockShape) -> Int {
        switch block.type {
        case .horizontalClear, .verticalClear:
            // Special shapes give bonus points
            return AppConfiguration.GameRules.lineScore  // Same as clearing one line
        case .areaClear:
            // Area clear gives higher bonus points (equivalent to clearing 2 lines)
            return AppConfiguration.GameRules.lineScore * 2
        case .normal:
            return block.positions.count * AppConfiguration.GameRules.baseBlockScore
        }
    }
    
    /// Calculates score for clearing lines with combo bonus
    static func calculateLineScore(clearedRows: Int, clearedCols: Int) -> Int {
        let totalLines = clearedRows + clearedCols
        let baseScore = totalLines * AppConfiguration.GameRules.lineScore
        
        // Combo bonus for multiple lines
        let comboBonus = max(0, totalLines - 1) * AppConfiguration.GameRules.comboBonus
        
        return baseScore + comboBonus
    }
    
    // MARK: - Grid Utilities
    
    /// Creates an empty grid
    static func createEmptyGrid() -> [[GridCell]] {
        return Array(repeating: Array(repeating: GridCell(), count: AppConfiguration.GameRules.gridSize), count: AppConfiguration.GameRules.gridSize)
    }
    
    /// Fills grid with geometric patterns based on difficulty mode
    ///
    /// This method provides structured, visually appealing initial grid states by placing
    /// geometric patterns instead of random individual blocks. The strategy varies by difficulty:
    ///
    /// - **Easy**: Fewer, simpler patterns (8-10% fill) with smaller shapes
    /// - **Moderate**: Balanced patterns (12-15% fill) with mixed complexity
    /// - **Hard**: More, complex patterns (15-20% fill) with larger shapes
    ///
    /// - Parameter grid: The grid to fill with patterns (modified in place)
    /// - Parameter difficulty: The difficulty mode determining pattern strategy
    ///
    /// ## Available Patterns by Difficulty
    /// - **Easy**: Lines, diagonals, small corners
    /// - **Moderate**: All patterns with balanced distribution
    /// - **Hard**: Complex crosses, squares, zigzags, triangles
    ///
    /// - Note: Patterns avoid line completion and ensure solvability regardless of difficulty.
    static func randomlyFillGrid(_ grid: inout [[GridCell]], difficulty: DifficultyMode = .easy) {
        let difficultyConfig = DifficultyPatternConfig.forDifficulty(difficulty)

        fillGridWithGeometricPatterns(&grid,
                                    targetPercentage: difficultyConfig.targetFillPercentage,
                                    allowedPatterns: difficultyConfig.allowedPatterns,
                                    patternWeights: difficultyConfig.patternWeights)
    }
    
    /// Fills grid with geometric patterns for a more structured initial state
    static func fillGridWithGeometricPatterns(
        _ grid: inout [[GridCell]], 
        targetPercentage: Double = 0.15,
        allowedPatterns: [GeometricPattern] = GeometricPattern.allCases,
        patternWeights: [GeometricPattern: Double] = [:]
    ) {
        let totalCells = AppConfiguration.GameRules.gridSize * AppConfiguration.GameRules.gridSize
        let targetCells = Int(Double(totalCells) * targetPercentage)
        
        var cellsPlaced = 0
        var attemptCount = 0
        let maxAttempts = 25 // Increased attempts for more complex difficulty constraints
        
        while cellsPlaced < targetCells && attemptCount < maxAttempts {
            // Select a pattern based on weights and allowed patterns
            let pattern = selectWeightedPattern(from: allowedPatterns, weights: patternWeights)
            
            // Try to place the pattern at a random valid location
            if let placementResult = tryPlacePattern(pattern, in: &grid) {
                cellsPlaced += placementResult.cellsAdded

                #if DEBUG
                BuildConfiguration.log("Placed \(pattern.rawValue) pattern (\(pattern.size) cells) at (\(placementResult.position.row), \(placementResult.position.col))", level: .verbose)
                #endif
            }

            attemptCount += 1
        }

        #if DEBUG
        let fillPercentage = Double(cellsPlaced) / Double(totalCells) * 100
        BuildConfiguration.log("Pattern placement complete: \(cellsPlaced) cells placed (\(String(format: "%.1f", fillPercentage))% fill)", level: .debug)
        #endif
    }
    
    /// Selects a pattern based on weights, falling back to random selection
    private static func selectWeightedPattern(
        from allowedPatterns: [GeometricPattern], 
        weights: [GeometricPattern: Double]
    ) -> GeometricPattern {
        // If no weights provided, use random selection
        guard !weights.isEmpty else {
            return allowedPatterns.randomElement() ?? .line2
        }
        
        // Filter weights to only allowed patterns
        let filteredWeights = weights.filter { allowedPatterns.contains($0.key) }
        
        // If no valid weights after filtering, fall back to random
        guard !filteredWeights.isEmpty else {
            return allowedPatterns.randomElement() ?? .line2
        }
        
        // Weighted random selection
        let totalWeight = filteredWeights.values.reduce(0, +)
        let randomValue = Double.random(in: 0...totalWeight)
        
        var currentWeight: Double = 0
        for (pattern, weight) in filteredWeights {
            currentWeight += weight
            if randomValue <= currentWeight {
                return pattern
            }
        }
        
        // Fallback (shouldn't reach here)
        return allowedPatterns.randomElement() ?? .line2
    }
    
    /// Attempts to place a geometric pattern at a random valid location
    private static func tryPlacePattern(_ pattern: GeometricPattern, in grid: inout [[GridCell]]) -> (position: GridPosition, cellsAdded: Int)? {
        let patternPositions = pattern.positions
        let maxAttempts = 10
        
        for _ in 0..<maxAttempts {
            // Generate random placement position
            let baseRow = Int.random(in: 0..<AppConfiguration.GameRules.gridSize)
            let baseCol = Int.random(in: 0..<AppConfiguration.GameRules.gridSize)
            let basePosition = GridPosition(row: baseRow, col: baseCol)
            
            // Check if pattern can be placed without going out of bounds or overlapping
            var canPlace = true
            var testPositions: [GridPosition] = []
            
            for patternPos in patternPositions {
                let finalRow = basePosition.row + patternPos.row
                let finalCol = basePosition.col + patternPos.col
                
                // Check bounds
                if finalRow < 0 || finalRow >= AppConfiguration.GameRules.gridSize ||
                   finalCol < 0 || finalCol >= AppConfiguration.GameRules.gridSize {
                    canPlace = false
                    break
                }
                
                let finalPosition = GridPosition(row: finalRow, col: finalCol)
                
                // Check if cell is already filled
                if grid[finalRow][finalCol].isFilled {
                    canPlace = false
                    break
                }
                
                testPositions.append(finalPosition)
            }
            
            if canPlace {
                // Test if placing this pattern would create complete lines
                var tempGrid = grid
                let patternColor = BlockColor.allCases.randomElement() ?? .blue
                
                for position in testPositions {
                    tempGrid[position.row][position.col].isFilled = true
                    tempGrid[position.row][position.col].color = patternColor
                }
                
                // Only place if it doesn't create complete lines
                if !wouldCreateCompleteLines(in: tempGrid) {
                    // Place the pattern
                    for position in testPositions {
                        grid[position.row][position.col].isFilled = true
                        grid[position.row][position.col].color = patternColor
                    }
                    
                    return (position: basePosition, cellsAdded: testPositions.count)
                }
            }
        }
        
        return nil
    }
    
    /// Checks if placing cells would create complete lines
    private static func wouldCreateCompleteLines(in testGrid: [[GridCell]]) -> Bool {
        // Check rows
        for row in 0..<AppConfiguration.GameRules.gridSize {
            if testGrid[row].allSatisfy({ $0.isFilled }) {
                return true
            }
        }
        
        // Check columns
        for col in 0..<AppConfiguration.GameRules.gridSize {
            if (0..<AppConfiguration.GameRules.gridSize).allSatisfy({ testGrid[$0][col].isFilled }) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Solvability Validation
    
    /// Checks if all blocks in the given array can be placed on the grid simultaneously
    /// Uses optimized backtracking algorithm with performance limits
    static func canAllBlocksBePlaced(_ blocks: [BlockShape], in grid: [[GridCell]]) -> Bool {
        guard !blocks.isEmpty else { return true }
        
        // Quick check: ensure we have enough empty cells for all blocks
        let totalBlockCells = blocks.reduce(0) { $0 + $1.positions.count }
        let emptyCells = countEmptyCells(in: grid)
        
        if totalBlockCells > emptyCells {
            return false
        }
        
        // Sort blocks by constraint (largest first for better pruning)
        let sortedBlocks = blocks.sorted { $0.positions.count > $1.positions.count }
        
        // Use optimized backtracking with depth limit; budget lives in
        // AppConfiguration.Gameplay.placementBacktrackLimit so tuning doesn't
        // require editing the algorithm.
        var callCount = 0
        let maxCalls = AppConfiguration.Gameplay.placementBacktrackLimit

        var mutableGrid = grid
        return canPlaceBlocksOptimized(sortedBlocks, startingAt: 0, grid: &mutableGrid, callCount: &callCount, maxCalls: maxCalls)
    }
    
    /// Optimized recursive backtracking with performance limits and in-place grid modification
    private static func canPlaceBlocksOptimized(_ blocks: [BlockShape], startingAt index: Int, grid: inout [[GridCell]], callCount: inout Int, maxCalls: Int) -> Bool {
        callCount += 1
        if callCount > maxCalls {
            return false // Timeout protection
        }
        
        // Base case: all blocks have been placed successfully
        if index >= blocks.count {
            return true
        }
        
        let currentBlock = blocks[index]
        
        // Try placing the current block at each valid position (inline validation)
        for row in 0..<AppConfiguration.GameRules.gridSize {
            for col in 0..<AppConfiguration.GameRules.gridSize {
                let position = GridPosition(row: row, col: col)
                
                // Inline placement validation for better performance
                if canPlaceBlockInline(currentBlock, at: position, in: grid) {
                    // Place block in-place for better memory efficiency
                    let placedPositions = placeBlockInPlace(currentBlock, at: position, in: &grid)
                    
                    // Recursively try to place the remaining blocks
                    if canPlaceBlocksOptimized(blocks, startingAt: index + 1, grid: &grid, callCount: &callCount, maxCalls: maxCalls) {
                        // Restore grid state before returning success
                        removeBlockInPlace(at: placedPositions, in: &grid)
                        return true
                    }
                    
                    // Restore grid state for next attempt
                    removeBlockInPlace(at: placedPositions, in: &grid)
                }
            }
        }
        
        // No valid placement found for this block
        return false
    }
    
    /// Finds all valid positions where a block can be placed on the grid
    static func findValidPositions(for block: BlockShape, in grid: [[GridCell]]) -> [GridPosition] {
        var validPositions: [GridPosition] = []
        
        for row in 0..<AppConfiguration.GameRules.gridSize {
            for col in 0..<AppConfiguration.GameRules.gridSize {
                let position = GridPosition(row: row, col: col)
                if canPlaceBlock(block, at: position, in: grid) {
                    validPositions.append(position)
                }
            }
        }
        
        return validPositions
    }
    
    // MARK: - Optimized Helper Methods
    
    /// Efficient empty cell counting without creating intermediate arrays
    private static func countEmptyCells(in grid: [[GridCell]]) -> Int {
        var count = 0
        for row in grid {
            for cell in row {
                if !cell.isFilled {
                    count += 1
                }
            }
        }
        return count
    }
    
    /// Inline block placement validation without creating Position objects
    private static func canPlaceBlockInline(_ block: BlockShape, at gridPosition: GridPosition, in grid: [[GridCell]]) -> Bool {
        switch block.type {
        case .horizontalClear, .verticalClear, .areaClear:
            return isValidGridPosition(gridPosition)
            
        case .normal:
            for blockPos in block.positions {
                let finalRow = gridPosition.row + blockPos.row
                let finalCol = gridPosition.col + blockPos.col
                
                // Check bounds and occupancy in one step
                if finalRow < 0 || finalRow >= AppConfiguration.GameRules.gridSize || 
                   finalCol < 0 || finalCol >= AppConfiguration.GameRules.gridSize ||
                   grid[finalRow][finalCol].isFilled {
                    return false
                }
            }
            return true
        }
    }
    
    /// In-place block placement that returns affected positions for efficient restoration
    private static func placeBlockInPlace(_ block: BlockShape, at gridPosition: GridPosition, in grid: inout [[GridCell]]) -> [(Int, Int)] {
        var placedPositions: [(Int, Int)] = []
        
        switch block.type {
        case .horizontalClear:
            let targetRow = gridPosition.row
            if targetRow >= 0 && targetRow < AppConfiguration.GameRules.gridSize {
                for col in 0..<AppConfiguration.GameRules.gridSize {
                    if grid[targetRow][col].isFilled {
                        placedPositions.append((targetRow, col))
                        grid[targetRow][col] = GridCell()
                    }
                }
            }
            
        case .verticalClear:
            let targetCol = gridPosition.col
            if targetCol >= 0 && targetCol < AppConfiguration.GameRules.gridSize {
                for row in 0..<AppConfiguration.GameRules.gridSize {
                    if grid[row][targetCol].isFilled {
                        placedPositions.append((row, targetCol))
                        grid[row][targetCol] = GridCell()
                    }
                }
            }
            
        case .areaClear:
            let centerRow = gridPosition.row
            let centerCol = gridPosition.col
            
            for rowOffset in -1...1 {
                for colOffset in -1...1 {
                    let targetRow = centerRow + rowOffset
                    let targetCol = centerCol + colOffset
                    let targetPosition = GridPosition(row: targetRow, col: targetCol)
                    
                    if isValidGridPosition(targetPosition) && grid[targetRow][targetCol].isFilled {
                        placedPositions.append((targetRow, targetCol))
                        grid[targetRow][targetCol] = GridCell()
                    }
                }
            }
            
        case .normal:
            for blockPos in block.positions {
                let finalRow = gridPosition.row + blockPos.row
                let finalCol = gridPosition.col + blockPos.col
                
                placedPositions.append((finalRow, finalCol))
                grid[finalRow][finalCol].isFilled = true
                grid[finalRow][finalCol].color = block.color
            }
        }
        
        return placedPositions
    }
    
    /// Efficient restoration of grid state
    private static func removeBlockInPlace(at positions: [(Int, Int)], in grid: inout [[GridCell]]) {
        for (row, col) in positions {
            grid[row][col] = GridCell()
        }
    }
    
    /// Validates if a grid position is within valid bounds
    private static func isValidGridPosition(_ position: GridPosition) -> Bool {
        let size = AppConfiguration.GameRules.gridSize
        return position.row.isValidGridIndex(in: size) && position.col.isValidGridIndex(in: size)
    }
}