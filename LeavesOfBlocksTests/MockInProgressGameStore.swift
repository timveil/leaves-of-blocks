//
//  MockInProgressGameStore.swift
//  LeavesOfBlocksTests
//
//  In-memory fake of the in-progress game store so GameState behavior
//  tests don't need to round-trip JSON through a temp directory.
//

import Foundation
@testable import LeavesOfBlocks

@MainActor
final class MockInProgressGameStore: InProgressGameStoring {

    // MARK: - Configuration

    /// Snapshot returned from `load()`. Defaults to nil (no saved game).
    var loadResult: InProgressGameSnapshot?

    // MARK: - Captured Calls

    private(set) var saveCallCount = 0
    private(set) var clearCallCount = 0
    private(set) var savedSnapshots: [InProgressGameSnapshot] = []

    init(loadResult: InProgressGameSnapshot? = nil) {
        self.loadResult = loadResult
    }

    // MARK: - InProgressGameStoring

    var hasSavedGame: Bool { loadResult != nil }

    func load() -> InProgressGameSnapshot? {
        loadResult
    }

    func save(_ snapshot: InProgressGameSnapshot) {
        saveCallCount += 1
        savedSnapshots.append(snapshot)
        loadResult = snapshot
    }

    func clear() {
        clearCallCount += 1
        loadResult = nil
    }
}
