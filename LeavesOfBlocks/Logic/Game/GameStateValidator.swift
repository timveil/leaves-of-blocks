import Foundation

// MARK: - Game State Validator

struct GameStateValidator {
    
    // MARK: - Validation Rules
    
    static func validateGameState(_ gameState: GameState) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Validate grid size
        if gameState.grid.count != GameTheme.GameConfig.gridSize {
            errors.append(.invalidGridSize(expected: GameTheme.GameConfig.gridSize, actual: gameState.grid.count))
        }
        
        // Validate grid columns
        for (index, row) in gameState.grid.enumerated() {
            if row.count != GameTheme.GameConfig.gridSize {
                errors.append(.invalidRowSize(row: index, expected: GameTheme.GameConfig.gridSize, actual: row.count))
            }
        }
        
        // Validate score
        if gameState.score < 0 {
            errors.append(.negativeScore(gameState.score))
        }
        
        // Validate current blocks
        if gameState.currentBlocks.isEmpty && !gameState.isGameOver {
            errors.append(.noCurrentBlocks)
        }
        
        return errors
    }
}

// MARK: - Validation Errors

enum ValidationError: Error, CustomStringConvertible {
    case invalidGridSize(expected: Int, actual: Int)
    case invalidRowSize(row: Int, expected: Int, actual: Int)
    case negativeScore(Int)
    case noCurrentBlocks
    
    var description: String {
        switch self {
        case .invalidGridSize(let expected, let actual):
            return "Invalid grid size: expected \(expected), got \(actual)"
        case .invalidRowSize(let row, let expected, let actual):
            return "Invalid row \(row) size: expected \(expected), got \(actual)"
        case .negativeScore(let score):
            return "Negative score: \(score)"
        case .noCurrentBlocks:
            return "No current blocks available"
        }
    }
}