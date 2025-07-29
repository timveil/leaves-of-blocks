import Foundation

// MARK: - Performance Monitor

struct PerformanceMonitor {
    
    // MARK: - Performance Metrics
    
    static func measureExecutionTime<T>(operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result: result, time: timeElapsed)
    }
    
    static func logPerformanceWarning(operation: String, time: TimeInterval, threshold: TimeInterval = 0.016) {
        if time > threshold {
            print("⚠️ Performance Warning: \(operation) took \(String(format: "%.3f", time))s (threshold: \(String(format: "%.3f", threshold))s)")
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
struct GameDebug {
    
    static func printGameState(_ gameState: GameState) {
        print("=== Game State ===")
        print("Score: \(gameState.score)")
        print("Lines Cleared: \(gameState.linesCleared)")
        print("Game Over: \(gameState.isGameOver)")
        print("Current Blocks: \(gameState.currentBlocks.count)")
        print("==================")
    }
    
    static func printGrid(_ grid: [[GridCell]]) {
        print("=== Grid State ===")
        for row in grid {
            let rowString = row.map { $0.isFilled ? "■" : "□" }.joined()
            print(rowString)
        }
        print("==================")
    }
}
#endif