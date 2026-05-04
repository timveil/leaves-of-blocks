import AVFoundation
import SwiftUI

@main
struct Main: App {
    @State private var showLaunchScreen = true
    @State private var gameState = GameState()
    @Environment(\.scenePhase) private var scenePhase
    let coreDataManager = CoreDataManager.shared

    init() {
        // .ambient lets background audio (Apple Music, Spotify, Podcasts) keep
        // playing while the game is open. SpriteKit otherwise claims the
        // session with .soloAmbient and silences other apps.
        try? AVAudioSession.sharedInstance()
            .setCategory(.ambient, options: [.mixWithOthers])
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                GameTheme.Gradients.background
                    .ignoresSafeArea()

                if showLaunchScreen {
                    LaunchScreen(onComplete: dismissLaunchScreen)
                        .transition(.opacity)
                } else {
                    ContentView(gameState: gameState)
                        .transition(.opacity)
                        .environment(\.managedObjectContext, coreDataManager.viewContext)
                        .environment(\.coreDataManager, coreDataManager)
                }
            }
            .task {
                // Authenticate with Game Center if (and only if) the user has
                // opted in. Apple recommends authenticating once on launch.
                GameCenterService.shared.authenticateIfEnabled()

                guard AppConfiguration.Runtime.isUITesting else { return }
                // UI tests skip the branding splash so they reach the home
                // screen immediately; LaunchScreen's onComplete still runs in
                // the non-UI-testing path.
                showLaunchScreen = false
                if AppConfiguration.Runtime.isScreenshotMode {
                    await ScreenshotFixtures.install(into: coreDataManager)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    gameState.persistInProgressGame()
                }
            }
        }
    }

    private func dismissLaunchScreen() {
        withAnimation(.easeOut(duration: 0.25)) {
            showLaunchScreen = false
        }
    }
}
