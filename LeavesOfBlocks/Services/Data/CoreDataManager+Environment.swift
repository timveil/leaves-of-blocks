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
///
/// `defaultValue` uses `MainActor.assumeIsolated` because:
///   - SwiftUI's `EnvironmentKey.defaultValue` is a nonisolated requirement.
///   - `CoreDataManager.shared` is `@MainActor`-isolated.
///   - SwiftUI only reads environment values during view rendering, which
///     runs on the main actor, so the assumption holds in practice.
/// Annotating `defaultValue` with `@MainActor` would violate the protocol
/// requirement (and is a Swift 6 error). The runtime check fails fast if
/// SwiftUI ever changes that contract.
private struct CoreDataManagerKey: EnvironmentKey {
    static var defaultValue: CoreDataManager {
        MainActor.assumeIsolated { CoreDataManager.shared }
    }
}

extension EnvironmentValues {
    var coreDataManager: CoreDataManager {
        get { self[CoreDataManagerKey.self] }
        set { self[CoreDataManagerKey.self] = newValue }
    }
}
