import SwiftUI

// MARK: - SwiftUI Environment Injection

/// EnvironmentKey for `CoreDataManager` so views can read persistence
/// dependencies the same way they read `\.scenePhase` or
/// `\.managedObjectContext` — without a hard reference to the singleton.
///
/// Production wiring lives in `LeavesOfBlocksApp.body`, which writes
/// `\.coreDataManager` once at the composition root. Views and previews
/// can override the value (e.g. `.environment(\.coreDataManager,
/// CoreDataManager.makeInMemoryForTests())`) to render with fixture data
/// or to test in isolation.
private struct CoreDataManagerKey: EnvironmentKey {
    @MainActor
    static let defaultValue: CoreDataManager = .shared
}

extension EnvironmentValues {
    var coreDataManager: CoreDataManager {
        get { self[CoreDataManagerKey.self] }
        set { self[CoreDataManagerKey.self] = newValue }
    }
}
