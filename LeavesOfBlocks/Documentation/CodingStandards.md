# Leaves of Blocks - Coding Standards

This document establishes the coding standards and conventions used throughout the Leaves of Blocks iOS game project.

## Table of Contents

1. [Swift Language Guidelines](#swift-language-guidelines)
2. [Code Organization](#code-organization)
3. [Naming Conventions](#naming-conventions)
4. [Documentation Standards](#documentation-standards)
5. [SwiftUI Conventions](#swiftui-conventions)
6. [Architecture Patterns](#architecture-patterns)
7. [Error Handling](#error-handling)
8. [Testing Standards](#testing-standards)

## Swift Language Guidelines

### Code Formatting

- **Indentation**: Use 4 spaces (no tabs)
- **Line Length**: Maximum 120 characters per line
- **Trailing Whitespace**: Remove all trailing whitespace
- **Final Newlines**: Ensure files end with a single newline

### Type Declarations

```swift
// Preferred
struct GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
}

// Avoid
struct GameState : ObservableObject {
    @Published var score:Int=0
    @Published var isGameOver:Bool=false
}
```

### Property Declarations

```swift
// Preferred - Explicit types when helpful for clarity
let gameService: GameService = GameService()
var currentBlocks: [BlockShape] = []

// Acceptable - Type inference when obvious
let score = 0
var isActive = true
```

## Code Organization

### File Structure

All Swift files should follow this structure:

```swift
//
//  FileName.swift
//  Leaves of Blocks
//
//  Created by [Author] on [Date].
//

import Foundation
import SwiftUI  // Additional imports in alphabetical order

// MARK: - Primary Types

// Main type declarations

// MARK: - Extensions

// Extensions to the main types

// MARK: - Preview

#Preview {
    // SwiftUI previews
}
```

### MARK Comments

Use MARK comments to organize code sections:

```swift
// MARK: - Published Properties
// MARK: - Private Properties  
// MARK: - Computed Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Protocol Conformance
```

### Directory Structure

- **Models/**: Data models and business logic types
- **Views/**: SwiftUI views organized by feature
- **Services/**: Service layer classes (networking, persistence, etc.)
- **Logic/**: Pure logic functions and algorithms
- **Extensions/**: Swift extensions organized by framework
- **Resources/**: Assets, themes, and configuration
- **Testing/**: Test utilities, mocks, and helpers

## Naming Conventions

### Types

- **Classes, Structs, Enums**: PascalCase
- **Protocols**: PascalCase, often ending in "Protocol" or describing capability

```swift
struct GameState { }
class GameService { }
enum DifficultyMode { }
protocol GameLogicProtocol { }
```

### Variables and Functions

- **Variables, Functions, Parameters**: camelCase
- **Constants**: camelCase (not SCREAMING_SNAKE_CASE)

```swift
let maxGridSize = 8
var currentScore = 0
func calculateBlockScore(block: BlockShape) -> Int { }
```

### File Naming

- Match the primary type name: `GameState.swift`
- Use descriptive names for files with multiple types: `BlockModels.swift`
- Extensions: `String+Extensions.swift`, `Color+Extensions.swift`

## Documentation Standards

### DocC Documentation

All public APIs must have DocC documentation:

```swift
/// Calculates the score for placing a block on the grid.
///
/// The scoring system awards 10 points per cell in the block.
/// Bonus points are awarded separately for line clearing.
///
/// - Parameter block: The `BlockShape` being placed
/// - Returns: The point value for placing this block
///
/// ## Example
/// ```swift
/// let score = GameLogic.calculateBlockScore(block: singleBlock)
/// // Returns: 10
/// ```
func calculateBlockScore(block: BlockShape) -> Int {
    return block.positions.count * 10
}
```

### Inline Comments

- Use `//` for single-line explanations
- Avoid obvious comments that repeat the code
- Focus on explaining "why" rather than "what"

```swift
// Good - Explains reasoning
// Haptic feedback provides tactile confirmation of successful placement
gameService.blockPlacementFeedback()

// Bad - States the obvious  
// Call the block placement feedback method
gameService.blockPlacementFeedback()
```

## SwiftUI Conventions

### View Structure

```swift
struct GameView: View {
    // MARK: - Properties
    
    @StateObject private var gameState = GameState()
    @State private var showingAlert = false
    
    // MARK: - View Body
    
    var body: some View {
        VStack {
            // View content
        }
        .navigationTitle("Game")
        .onAppear {
            // Setup code
        }
    }
    
    // MARK: - Private Methods
    
    private func startNewGame() {
        // Implementation
    }
}
```

### View Modifiers

- Apply view modifiers in a logical order:
  1. Layout modifiers (padding, frame, etc.)
  2. Appearance modifiers (background, foreground, etc.)
  3. Behavior modifiers (onAppear, gesture, etc.)

```swift
Text("Game Over")
    .font(.title)
    .padding()
    .background(Color.red)
    .cornerRadius(8)
    .onTapGesture {
        // Handle tap
    }
```

### State Management

- Use `@State` for local view state
- Use `@StateObject` for creating ObservableObject instances
- Use `@ObservedObject` for passed-in ObservableObject instances
- Use `@EnvironmentObject` for app-wide shared state

## Architecture Patterns

### Service-Oriented Architecture

The app follows a service-oriented architecture:

- **GameState**: ObservableObject for UI state management
- **GameLogic**: Static methods for pure game logic
- **GameService**: Infrastructure services (timing, haptics, persistence)

### Separation of Concerns

```swift
// Good - Separated concerns
struct GameView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        // UI only
    }
    
    private func placeBlock() {
        gameState.placeBlock(block, at: position) // Delegate to game state
    }
}

// Avoid - Mixed concerns
struct GameView: View {
    var body: some View {
        // Don't put game logic directly in views
    }
}
```

### Dependency Injection

Use dependency injection for testability:

```swift
class GameService {
    private let persistenceService: PersistenceServiceProtocol
    
    init(persistenceService: PersistenceServiceProtocol = CoreDataManager.shared) {
        self.persistenceService = persistenceService
    }
}
```

## Error Handling

### Error Types

Define meaningful error types:

```swift
enum GameError: LocalizedError {
    case invalidBlockPlacement
    case gameAlreadyOver
    case persistenceFailure(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidBlockPlacement:
            return "Block cannot be placed at this position"
        case .gameAlreadyOver:
            return "Game has already ended"
        case .persistenceFailure(let error):
            return "Data persistence failed: \(error.localizedDescription)"
        }
    }
}
```

### Error Handling Patterns

```swift
// Preferred - Graceful error handling with recovery
do {
    try persistenceService.saveGameRecord(record)
} catch {
    print("Failed to save game record: \(error)")
    // Attempt recovery or show user-friendly message
    showErrorAlert(message: "Unable to save game progress")
}

// Avoid - Silent failures
try? persistenceService.saveGameRecord(record)
```

## Testing Standards

### Test Organization

```swift
import Testing
@testable import LeavesOfBlocks

struct GameLogicTests {
    
    // MARK: - Block Placement Tests
    
    @Test("Block placement validation")
    func testBlockPlacement() {
        // Given
        let grid = GameLogic.createEmptyGrid()
        let block = BlockShape.allShapes[0]
        let position = GridPosition(row: 0, col: 0)
        
        // When
        let canPlace = GameLogic.canPlaceBlock(block, at: position, in: grid)
        
        // Then
        #expect(canPlace == true)
    }
}
```

### Test Naming

- Use descriptive test names that explain the scenario
- Follow the "should_ExpectedBehavior_When_StateUnderTest" pattern
- Use `@Test` attribute with descriptive display names

### Test Structure

- Follow Given-When-Then pattern
- Use `#expect` for assertions (Swift Testing)
- Group related tests using MARK comments

## Code Review Guidelines

### Before Submitting

1. Run all tests and ensure they pass
2. Build successfully with no warnings
3. Follow all naming conventions
4. Include appropriate documentation
5. Remove debug code and console logs (except in DEBUG builds)

### Review Checklist

- [ ] Code follows established patterns
- [ ] Public APIs have DocC documentation
- [ ] Error handling is appropriate
- [ ] Tests are included for new functionality
- [ ] Performance implications considered
- [ ] Security implications reviewed

## Performance Guidelines

### SwiftUI Performance

- Use `LazyVStack` and `LazyHStack` for large lists
- Minimize state updates and body re-evaluations
- Use `@StateObject` appropriately vs `@ObservedObject`

### Memory Management

- Avoid retain cycles in closures (use `[weak self]` when needed)
- Properly invalidate timers and cancel network requests
- Use value types (structs) when appropriate

### Computational Efficiency

- Prefer single-pass algorithms over multiple iterations
- Cache expensive computations when possible
- Use appropriate data structures for the use case

## Conclusion

These standards ensure code consistency, maintainability, and quality across the Leaves of Blocks project. When in doubt, prioritize clarity and maintainability over clever optimizations.

For questions or suggestions about these standards, please discuss with the team during code review or project planning sessions.