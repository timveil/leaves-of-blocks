import Foundation

// MARK: - Board Layout Helpers

/// Pure-logic helpers for `BoardView` drag/placement geometry. Lifted out of
/// the view so they can be exercised without a SwiftUI environment.
enum BoardLayout {

    /// Computes the row/column scan ranges for `findOptimalPlacement` given
    /// the drag's projected center in grid-cell units. Returns `nil` when the
    /// drag has wandered far enough off the grid that no clamped range can
    /// contain a valid placement — the caller should treat that as "no
    /// candidate position" and skip the search entirely.
    ///
    /// The previous inline form clamped `startRow`/`endRow` (and the column
    /// pair) to the grid edges *independently*. A deeply-negative or deeply-
    /// positive `centerRow` would leave `endRow < startRow`, and building
    /// `startRow...endRow` would trap with `Range requires lowerBound <=
    /// upperBound`. Production crash log
    /// `2026-05-10_02-57-06.1411_+0800-...crash` reproduced this in 2.0.3
    /// when a drag carried `nearPoint.y` deep below the grid.
    static func placementSearchRanges(
        centerRow: Int,
        centerCol: Int,
        searchRadius: Int,
        gridSize: Int
    ) -> (rows: ClosedRange<Int>, cols: ClosedRange<Int>)? {
        let lowerRow = max(0, centerRow - searchRadius)
        let upperRow = min(gridSize - 1, centerRow + searchRadius)
        let lowerCol = max(0, centerCol - searchRadius)
        let upperCol = min(gridSize - 1, centerCol + searchRadius)
        guard lowerRow <= upperRow, lowerCol <= upperCol else { return nil }
        return (lowerRow...upperRow, lowerCol...upperCol)
    }
}
