import SwiftUI
import SpriteKit

// MARK: - SpriteKit Game View

/// A SwiftUI wrapper that embeds the SpriteKit game scene for grid rendering.
///
/// Displays the 8×8 game grid using SpriteKit while keeping all surrounding UI
/// (score, holding area, overlays) in SwiftUI.
///
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
    let size = GameScene.sceneSize()
    SpriteKitGameView(bridge: bridge)
        .frame(width: size.width, height: size.height)
}
