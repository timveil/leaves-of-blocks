import SwiftUI
import SpriteKit

// MARK: - SpriteKit Game View

/// A SwiftUI wrapper that embeds the SpriteKit game scene for grid rendering.
///
/// `SpriteKitGameView` replaces the SwiftUI `GameGridView` when the SpriteKit
/// renderer is enabled. It displays the 8x8 game grid using SpriteKit while
/// keeping all surrounding UI (score, holding area, overlays) in SwiftUI.
///
/// ## Integration
/// This view is used inside `BoardView` as a drop-in replacement for `GameGridView`.
/// The `GameSceneBridge` manages communication between the SwiftUI drag system
/// and the SpriteKit scene's preview rendering.
///
/// ## Usage
/// ```swift
/// SpriteKitGameView(bridge: sceneBridge)
///     .frame(width: gameWidth, height: gameWidth)
/// ```
struct SpriteKitGameView: View {

    /// The bridge coordinating SwiftUI and SpriteKit communication
    @ObservedObject var bridge: GameSceneBridge

    var body: some View {
        SpriteView(scene: bridge.scene, options: [.allowsTransparency])
            .accessibilityIdentifier("spritekit_game_grid")
    }
}

#Preview {
    let gameState = GameState()
    let bridge = GameSceneBridge(gameState: gameState)
    SpriteKitGameView(bridge: bridge)
        .frame(width: 373, height: 373)
}
