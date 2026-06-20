import Foundation

/// In-memory snapshot of every mutable `GameState` field plus the elapsed game
/// time and the saved `GameRecord` identifier (if any). Captured immediately
/// before each placement so `undoLastPlacement()` can restore the player to
/// exactly the state they were in before the move — including reversing a
/// game-over save when the placement caused it.
///
/// Deliberately distinct from `InProgressGameSnapshot`:
///   * lives in memory only (no Codable conformance — never written to disk)
///   * captures behavior-tracker state and `isGameOver` (which the
///     resume-from-disk snapshot intentionally drops)
///   * carries the saved `GameRecord.id` (a UUID) so undo deletes the exact
///     row, not "the most recent" (no race with later saves)
struct UndoSnapshot: Equatable {
    let grid: [[GridCell]]
    let currentBlocks: [BlockShape]
    let score: Int
    let isGameOver: Bool
    let linesCleared: Int
    let lastClearedCells: [ClearedCell]
    let blocksPlaced: Int
    let longestCombo: Int
    let currentCombo: Int
    let isNewHighScore: Bool
    let specialShapesUsed: Int
    let currentDifficulty: DifficultyMode
    let elapsedGameTime: TimeInterval
    let trackerState: PlayerBehaviorTracker.State
    let savedRecordID: UUID?
}
