import Foundation

/// Codable snapshot of an in-progress game, persisted to disk so the player can
/// resume after backgrounding, force-quitting, or navigating away.
///
/// Per-move analytics from `PlayerBehaviorTracker` are intentionally omitted —
/// resumed runs start the tracker fresh and accumulate metrics from the resume
/// point forward. Gameplay state (grid, blocks, score, timing) is fully restored.
struct InProgressGameSnapshot: Codable, Equatable {
    var grid: [[GridCell]]
    var currentBlocks: [BlockShape]
    var score: Int
    var linesCleared: Int
    var blocksPlaced: Int
    var longestCombo: Int
    var currentCombo: Int
    var specialShapesUsed: Int
    var difficulty: DifficultyMode
    var elapsedGameTime: TimeInterval
    var savedAt: Date
}

/// Abstract surface for the active-game store, so consumers (chiefly
/// `GameState`) can be tested against an in-memory fake instead of real
/// disk I/O. The production `InProgressGameStore` conforms; the test
/// target ships a `MockInProgressGameStore` that records call counts.
@MainActor
protocol InProgressGameStoring: AnyObject {
    var hasSavedGame: Bool { get }
    func load() -> InProgressGameSnapshot?
    func save(_ snapshot: InProgressGameSnapshot)
    func clear()
}

/// Single-slot, JSON-on-disk persistence for the active game.
///
/// The store holds at most one snapshot. Writing a new snapshot replaces the
/// previous one; `clear()` removes the file. The file URL is injectable so
/// tests can use a temporary directory.
@MainActor
final class InProgressGameStore: InProgressGameStoring {

    static let shared: InProgressGameStore = {
        let url = InProgressGameStore.defaultFileURL()
        return InProgressGameStore(fileURL: url)
    }()

    private let fileURL: URL
    private let fileManager: FileManager

    init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    var hasSavedGame: Bool {
        fileManager.fileExists(atPath: fileURL.path)
    }

    func load() -> InProgressGameSnapshot? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(InProgressGameSnapshot.self, from: data)
        } catch {
            BuildConfiguration.log("Failed to load in-progress game: \(error)", level: .error)
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }

    func save(_ snapshot: InProgressGameSnapshot) {
        do {
            let parent = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: parent.path) {
                try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
            }
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            BuildConfiguration.log("Failed to save in-progress game: \(error)", level: .error)
        }
    }

    func clear() {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            BuildConfiguration.log("Failed to clear in-progress game: \(error)", level: .error)
        }
    }

    private static func defaultFileURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.temporaryDirectory
        return base.appendingPathComponent("InProgressGame.json")
    }
}
