import Foundation
import SwiftUI

// MARK: - Test Utilities and Debug Tools

#if DEBUG || TESTING

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