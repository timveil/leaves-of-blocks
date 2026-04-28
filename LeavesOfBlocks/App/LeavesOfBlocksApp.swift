import SwiftUI

@main
struct Main: App {
    @State private var showLaunchScreen = true
    @State private var gameState = GameState()
    let coreDataManager = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                GameTheme.Gradients.background
                    .ignoresSafeArea()

                if showLaunchScreen {
                    LaunchScreen()
                        .transition(.opacity)
                } else {
                    ContentView(gameState: gameState)
                        .transition(.opacity)
                        .environment(\.managedObjectContext, coreDataManager.viewContext)
                }
            }
            .task {
                if AppConfiguration.Runtime.isUITesting {
                    showLaunchScreen = false

                    if AppConfiguration.Runtime.isScreenshotMode {
                        await ScreenshotFixtures.install(into: coreDataManager)
                    }
                } else {
                    try? await Task.sleep(for: .seconds(2.5))
                    showLaunchScreen = false
                }
            }
        }
    }
}
