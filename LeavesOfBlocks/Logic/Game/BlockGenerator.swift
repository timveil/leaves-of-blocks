import Foundation

// MARK: - Solvability Logging Extensions

extension BuildConfiguration {
    /// Specialized logging for solvability detection and resolution with performance optimization
    static func logSolvability(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        // Early exit if logging level won't be displayed (performance optimization)
        guard level.rawValue >= currentLogLevel.rawValue else { return }
        
        let prefix = "[SOLVABILITY]"
        log("\(prefix) \(message)", level: level, file: file, function: function, line: line)
    }
}

// MARK: - Block Creation Utilities

extension BlockGenerator {
    /// Creates a single block with random color - reduces code duplication
    private static func createSingleBlock() -> BlockShape {
        let randomColor = BlockColor.allCases.randomElement()!
        return BlockShape(positions: [GridPosition(row: 0, col: 0)], color: randomColor)
    }
    
    /// Creates multiple single blocks efficiently
    private static func createSingleBlocks(count: Int) -> [BlockShape] {
        return (0..<count).map { _ in createSingleBlock() }
    }
}

// MARK: - Block Generator

struct BlockGenerator {
    
    // MARK: - Special Block Types
    
    /// Enumeration of available special block types for cleaner generation logic
    private enum SpecialBlockType: CaseIterable {
        case horizontal, vertical, area
        
        var blockShape: BlockShape {
            switch self {
            case .horizontal:
                return BlockShape.horizontalClearShape
            case .vertical:
                return BlockShape.verticalClearShape
            case .area:
                return BlockShape.areaClearShape
            }
        }
    }
    
    // MARK: - Difficulty-Based Block Generation
    
    // Special shape generation probabilities by difficulty
    private static let specialShapeProbability: [DifficultyMode: Double] = [
        .easy: 0.15,      // 15% chance in easy mode
        .moderate: 0.10,  // 10% chance in moderate mode
        .hard: 0.05       // 5% chance in hard mode
    ]
    
    // MARK: - Shape Variety Helpers
    
    enum ShapeOrientation: CaseIterable {
        case horizontal, vertical, square, lShape, tShape, irregular
    }
    
    private static func getShapeType(_ block: BlockShape) -> String {
        // Handle special shapes
        switch block.type {
        case .horizontalClear:
            return "horizontal_clear"
        case .verticalClear:
            return "vertical_clear"
        case .areaClear:
            return "area_clear"
        case .normal:
            let cellCount = block.positions.count
            
            switch cellCount {
            case 1: return "single"
            case 2: return "double"
            case 3: return "triple"
            case 4: return "quad"
            case 5: return "penta"
            case 6: return "hexa" 
            case 7: return "hepta"
            case 9: return "nona"
            default: return "other"
            }
        }
    }
    
    private static func getShapeOrientation(_ block: BlockShape) -> ShapeOrientation {
        let bounds = block.getBounds()
        
        let width = bounds.width
        let height = bounds.height
        
        if width == height {
            return .square
        } else if width > height {
            return .horizontal
        } else {
            return .vertical
        }
    }
    
    private static func generateVariedBlock(
        difficulty: DifficultyMode,
        excludeShapeTypes: [String],
        excludeOrientations: [ShapeOrientation]
    ) -> BlockShape {
        let blockWeights = getBlockWeights(for: difficulty)
        var filteredWeights: [BlockShape: Double] = [:]
        
        // Filter out shapes we want to avoid for variety
        for (block, weight) in blockWeights {
            let shapeType = getShapeType(block)
            let orientation = getShapeOrientation(block)
            
            // Avoid 3 of the same type
            let typeCount = excludeShapeTypes.filter { $0 == shapeType }.count
            let orientationCount = excludeOrientations.filter { $0 == orientation }.count
            
            if typeCount < 2 && orientationCount < 2 {
                filteredWeights[block] = weight
            } else {
                // Drastically reduce probability but don't eliminate entirely
                filteredWeights[block] = weight * 0.1
            }
        }
        
        // If we filtered too aggressively, fall back to full weights
        if filteredWeights.isEmpty {
            filteredWeights = blockWeights
        }
        
        let totalWeight = filteredWeights.values.reduce(0, +)
        let randomValue = Double.random(in: 0...totalWeight)
        
        var currentWeight: Double = 0
        
        for (block, weight) in filteredWeights {
            currentWeight += weight
            if randomValue <= currentWeight {
                let randomColor = BlockColor.allCases.randomElement()!
                return BlockShape(positions: block.positions, color: randomColor)
            }
        }
        
        // Fallback
        let randomColor = BlockColor.allCases.randomElement()!
        return BlockShape(positions: BlockShape.allShapes[0].positions, color: randomColor)
    }
    
    private static func getBlockWeights(for difficulty: DifficultyMode) -> [BlockShape: Double] {
        var weights: [BlockShape: Double] = [:]
        
        // Ensure we have weights for all shapes (now 22 total)
        for (index, shape) in BlockShape.allShapes.enumerated() {
            let cellCount = shape.positions.count
            
            switch difficulty {
            case .easy:
                weights[shape] = getEasyWeight(for: cellCount, index: index)
            case .moderate:
                weights[shape] = getModerateWeight(for: cellCount, index: index)
            case .hard:
                weights[shape] = getHardWeight(for: cellCount, index: index)
            }
        }
        
        return weights
    }
    
    private static func getEasyWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 3.0  // Single blocks common
        case 2: return 3.0  // 2-block shapes common
        case 3: return 2.5  // 3-block shapes moderate
        case 4: return 2.0  // 4-block shapes less common
        case 5: return 1.5  // 5-block shapes (new lines & L-shapes)
        case 6: return 1.0  // 6-block rectangles 
        case 7: return 0.8  // 7-block L-shapes
        case 9: return 0.5  // 9-block square rare
        default: return 1.0
        }
    }
    
    private static func getModerateWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 2.0  // Single blocks less common
        case 2: return 2.5  // 2-block shapes moderate
        case 3: return 3.0  // 3-block shapes common
        case 4: return 2.5  // 4-block shapes moderate
        case 5: return 2.0  // 5-block shapes moderate
        case 6: return 1.5  // 6-block rectangles
        case 7: return 1.2  // 7-block L-shapes
        case 9: return 1.0  // 9-block square moderate
        default: return 1.5
        }
    }
    
    private static func getHardWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 1.0  // Single blocks rare
        case 2: return 1.5  // 2-block shapes rare
        case 3: return 2.0  // 3-block shapes less common
        case 4: return 3.0  // 4-block shapes common
        case 5: return 3.5  // 5-block shapes very common
        case 6: return 3.0  // 6-block rectangles common
        case 7: return 2.5  // 7-block L-shapes common
        case 9: return 2.0  // 9-block square common
        default: return 2.0
        }
    }
    
    static func generateWeightedBlocks(count: Int = 3, difficulty: DifficultyMode = .easy, grid: [[GridCell]]) -> [BlockShape] {
        // Generate blocks using the current method
        let initialBlocks = generateInitialBlocks(count: count, difficulty: difficulty)
        
        // Validate solvability and apply fallback if necessary  
        return ensureSolvableBlocks(initialBlocks, difficulty: difficulty, grid: grid)
    }
    
    /// Generates initial blocks using the current weighted algorithm
    private static func generateInitialBlocks(count: Int, difficulty: DifficultyMode) -> [BlockShape] {
        var blocks: [BlockShape] = []
        var usedShapeTypes: [String] = []
        var usedOrientations: [ShapeOrientation] = []
        var hasSpecialShape = false
        
        for _ in 0..<count {
            // Check if we should generate a special shape
            let specialProbability = specialShapeProbability[difficulty] ?? 0.1
            let shouldGenerateSpecial = Double.random(in: 0...1) < specialProbability && !hasSpecialShape
            
            if shouldGenerateSpecial {
                // Generate a special shape (equal chance between all special types)
                let specialBlock = SpecialBlockType.allCases.randomElement()!.blockShape
                blocks.append(specialBlock)
                hasSpecialShape = true
            } else {
                // Generate a normal block
                let newBlock = generateVariedBlock(
                    difficulty: difficulty,
                    excludeShapeTypes: usedShapeTypes,
                    excludeOrientations: usedOrientations
                )
                
                blocks.append(newBlock)
                
                // Track what we've used to ensure variety
                let shapeType = getShapeType(newBlock)
                let orientation = getShapeOrientation(newBlock)
                
                usedShapeTypes.append(shapeType)
                usedOrientations.append(orientation)
            }
        }
        
        return blocks
    }
    
    /// Ensures the generated blocks are solvable, applying fallback strategy if needed
    /// Includes performance monitoring and comprehensive error handling
    private static func ensureSolvableBlocks(_ blocks: [BlockShape], difficulty: DifficultyMode, grid: [[GridCell]]) -> [BlockShape] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check if blocks can be placed as-is
        if GameLogic.canAllBlocksBePlaced(blocks, in: grid) {
            BuildConfiguration.logSolvability("Generated blocks are solvable without fallback", level: .debug)
            return blocks
        }
        
        // Log unsolvable situation detected with context
        let blockSizes = blocks.map { $0.positions.count }
        let emptyCells = grid.flatMap { $0 }.filter { !$0.isFilled }.count
        let totalBlockCells = blockSizes.reduce(0, +)
        
        BuildConfiguration.logSolvability("🚨 UNSOLVABLE BLOCKS DETECTED - Block sizes: \(blockSizes), Empty cells: \(emptyCells), Required cells: \(totalBlockCells), Difficulty: \(difficulty)", level: .warning)
        
        // Apply fallback strategy with retry limit
        let maxRetries = 3
        var currentBlocks = blocks
        
        for attempt in 0..<maxRetries {
            BuildConfiguration.logSolvability("Applying fallback strategy - Attempt \(attempt + 1)/\(maxRetries)", level: .info)
            currentBlocks = applyFallbackStrategy(currentBlocks, difficulty: difficulty, grid: grid)
            
            if GameLogic.canAllBlocksBePlaced(currentBlocks, in: grid) {
                let newBlockSizes = currentBlocks.map { $0.positions.count }
                let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                BuildConfiguration.logSolvability("✅ Fallback successful after \(attempt + 1) attempts - New block sizes: \(newBlockSizes), Time: \(String(format: "%.3f", elapsedTime))s", level: .info)
                return currentBlocks
            }
            
            BuildConfiguration.logSolvability("Fallback attempt \(attempt + 1) still unsolvable, trying again...", level: .debug)
        }
        
        // Final fallback: ensure at least single blocks that can fit
        BuildConfiguration.logSolvability("⚠️ All fallback attempts failed, using guaranteed solvable blocks (single blocks)", level: .warning)
        let guaranteedBlocks = generateGuaranteedSolvableBlocks(count: blocks.count, grid: grid)
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        BuildConfiguration.logSolvability("Generated \(guaranteedBlocks.count) guaranteed single blocks as final fallback, Total time: \(String(format: "%.3f", elapsedTime))s", level: .info)
        return guaranteedBlocks
    }
    
    /// Applies fallback strategy by replacing problematic blocks with smaller alternatives
    private static func applyFallbackStrategy(_ blocks: [BlockShape], difficulty: DifficultyMode, grid: [[GridCell]]) -> [BlockShape] {
        var modifiedBlocks = blocks
        
        // Sort blocks by size (largest first) to identify problematic ones
        let sortedIndices = blocks.indices.sorted { blocks[$0].positions.count > blocks[$1].positions.count }
        
        if BuildConfiguration.currentLogLevel.rawValue <= BuildConfiguration.LogLevel.debug.rawValue {
            BuildConfiguration.logSolvability("Analyzing blocks for replacement - Block sizes: \(blocks.map { $0.positions.count })", level: .debug)
        }
        
        // Replace the largest block that can't be placed anywhere
        for index in sortedIndices {
            let block = blocks[index]
            let validPositions = GameLogic.findValidPositions(for: block, in: grid)
            
            if BuildConfiguration.currentLogLevel.rawValue <= BuildConfiguration.LogLevel.verbose.rawValue {
                BuildConfiguration.logSolvability("Block at index \(index) (size: \(block.positions.count)) has \(validPositions.count) valid positions", level: .verbose)
            }
            
            if validPositions.isEmpty {
                // This block can't be placed anywhere, replace with a smaller one
                BuildConfiguration.logSolvability("🔄 Replacing impossible block at index \(index) (size: \(block.positions.count))", level: .info)
                let replacementBlock = generateSmallerAlternative(for: block, difficulty: difficulty, grid: grid)
                modifiedBlocks[index] = replacementBlock
                BuildConfiguration.logSolvability("Replaced with smaller block (size: \(replacementBlock.positions.count))", level: .info)
                break
            }
        }
        
        return modifiedBlocks
    }
    
    /// Generates a smaller alternative block that can fit on the grid
    private static func generateSmallerAlternative(for originalBlock: BlockShape, difficulty: DifficultyMode, grid: [[GridCell]]) -> BlockShape {
        let blockWeights = getBlockWeights(for: difficulty)
        
        BuildConfiguration.logSolvability("Searching for smaller alternative to replace block of size \(originalBlock.positions.count)", level: .debug)
        
        // Try progressively smaller blocks until we find one that fits
        let sizePreference = [1, 2, 3, 4] // Prefer smaller sizes for fallback
        
        for targetSize in sizePreference {
            let candidateBlocks = blockWeights.keys.filter { $0.positions.count == targetSize }
            BuildConfiguration.logSolvability("Trying \(candidateBlocks.count) candidates of size \(targetSize)", level: .verbose)
            
            for candidate in candidateBlocks.shuffled() {
                let validPositions = GameLogic.findValidPositions(for: candidate, in: grid)
                if !validPositions.isEmpty {
                    let randomColor = BlockColor.allCases.randomElement()!
                    BuildConfiguration.logSolvability("Found suitable replacement: size \(targetSize) with \(validPositions.count) valid positions", level: .debug)
                    return BlockShape(positions: candidate.positions, color: randomColor)
                }
            }
        }
        
        // Ultimate fallback: single block
        BuildConfiguration.logSolvability("⚠️ Using ultimate fallback: single block", level: .warning)
        return createSingleBlock()
    }
    
    /// Generates blocks that are guaranteed to be solvable as final fallback
    private static func generateGuaranteedSolvableBlocks(count: Int, grid: [[GridCell]]) -> [BlockShape] {
        let emptyPositions = findEmptyPositions(in: grid)
        BuildConfiguration.logSolvability("Generating guaranteed solvable blocks - Empty positions available: \(emptyPositions.count)", level: .info)
        
        // Generate single blocks up to the requested count
        let guaranteedBlocks = createSingleBlocks(count: count)
        
        if emptyPositions.count < count {
            BuildConfiguration.logSolvability("⚠️ Only \(emptyPositions.count) empty positions available for \(count) requested blocks", level: .warning)
        }
        
        return guaranteedBlocks
    }
    
    /// Helper function to find all empty positions in the grid
    private static func findEmptyPositions(in grid: [[GridCell]]) -> [GridPosition] {
        var emptyPositions: [GridPosition] = []
        
        for row in 0..<GameTheme.GameConfig.gridSize {
            for col in 0..<GameTheme.GameConfig.gridSize {
                if !grid[row][col].isFilled {
                    emptyPositions.append(GridPosition(row: row, col: col))
                }
            }
        }
        
        return emptyPositions
    }
    
    private static func generateWeightedBlock(difficulty: DifficultyMode) -> BlockShape {
        let blockWeights = getBlockWeights(for: difficulty)
        let totalWeight = blockWeights.values.reduce(0, +)
        let randomValue = Double.random(in: 0...totalWeight)
        
        var currentWeight: Double = 0
        
        for (block, weight) in blockWeights {
            currentWeight += weight
            if randomValue <= currentWeight {
                let randomColor = BlockColor.allCases.randomElement()!
                return BlockShape(positions: block.positions, color: randomColor)
            }
        }
        
        // Fallback to first block if something goes wrong
        let randomColor = BlockColor.allCases.randomElement()!
        return BlockShape(positions: BlockShape.allShapes[0].positions, color: randomColor)
    }
}