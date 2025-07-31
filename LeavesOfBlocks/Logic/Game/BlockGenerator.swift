import Foundation

// MARK: - Block Generator

struct BlockGenerator {
    
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
        let minRow = block.positions.map(\.row).min() ?? 0
        let maxRow = block.positions.map(\.row).max() ?? 0
        let minCol = block.positions.map(\.col).min() ?? 0
        let maxCol = block.positions.map(\.col).max() ?? 0
        
        let width = maxCol - minCol + 1
        let height = maxRow - minRow + 1
        
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
    
    static func generateWeightedBlocks(count: Int = 3, difficulty: DifficultyMode = .easy) -> [BlockShape] {
        var blocks: [BlockShape] = []
        var usedShapeTypes: [String] = []
        var usedOrientations: [ShapeOrientation] = []
        var hasSpecialShape = false
        
        for _ in 0..<count {
            // Check if we should generate a special shape
            let specialProbability = specialShapeProbability[difficulty] ?? 0.1
            let shouldGenerateSpecial = Double.random(in: 0...1) < specialProbability && !hasSpecialShape
            
            if shouldGenerateSpecial {
                // Generate a special shape (50/50 between horizontal and vertical clear)
                let isHorizontal = Bool.random()
                let specialBlock = isHorizontal ? BlockShape.horizontalClearShape : BlockShape.verticalClearShape
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