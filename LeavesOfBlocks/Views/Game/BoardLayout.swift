import CoreGraphics
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

    /// Returns the cell-center coordinate (in grid-local space) for placing
    /// `block` at `position`. Used by `findOptimalPlacement` to score each
    /// candidate against the drag's `nearPoint`.
    ///
    /// Pure of view state — extracted from `BoardView.calculateBlockCenter`
    /// so the placement loop is testable.
    static func blockCenter(
        for block: BlockShape,
        at position: GridPosition,
        cellSize: CGFloat,
        cellSpacing: CGFloat,
        gridPadding: CGFloat
    ) -> CGPoint {
        let bounds = block.getBounds()
        let cellWithSpacing = cellSize + cellSpacing
        let centerRow = CGFloat(position.row) + CGFloat(bounds.maxRow + bounds.minRow) / 2.0
        let centerCol = CGFloat(position.col) + CGFloat(bounds.maxCol + bounds.minCol) / 2.0
        return CGPoint(
            x: centerCol * cellWithSpacing + cellSize / 2.0 + gridPadding,
            y: centerRow * cellWithSpacing + cellSize / 2.0 + gridPadding
        )
    }

    /// Finds the grid position whose placed-block center sits closest to
    /// `nearPoint`. Returns `nil` when the drag is off-grid (per
    /// `placementSearchRanges`) or when no candidate satisfies `canPlace`.
    ///
    /// Extracted from `BoardView.findOptimalPlacement` so the placement
    /// search loop — the site that crashed in 2.0.3 — is exercisable without
    /// a SwiftUI environment. Tests inject `canPlace` to model an empty /
    /// full / partially-filled grid without spinning up `GameState`.
    static func findOptimalPlacement(
        for block: BlockShape,
        nearPoint: CGPoint,
        cellSize: CGFloat,
        cellSpacing: CGFloat,
        gridSize: Int,
        maxDistance: CGFloat,
        gridPadding: CGFloat = 0,
        canPlace: (BlockShape, GridPosition) -> Bool
    ) -> GridPosition? {
        let cellWithSpacing = cellSize + cellSpacing
        let centerRow = Int(nearPoint.y / cellWithSpacing)
        let centerCol = Int(nearPoint.x / cellWithSpacing)
        let bounds = block.getBounds()
        let searchRadius = max(bounds.width, bounds.height) + 2

        guard let ranges = placementSearchRanges(
            centerRow: centerRow,
            centerCol: centerCol,
            searchRadius: searchRadius,
            gridSize: gridSize
        ) else {
            return nil
        }

        var bestPosition: GridPosition?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for row in ranges.rows {
            for col in ranges.cols {
                let position = GridPosition(row: row, col: col)
                guard canPlace(block, position) else { continue }

                let center = blockCenter(
                    for: block,
                    at: position,
                    cellSize: cellSize,
                    cellSpacing: cellSpacing,
                    gridPadding: gridPadding
                )
                let distance = hypot(center.x - nearPoint.x, center.y - nearPoint.y)

                if distance < bestDistance && distance <= maxDistance {
                    bestDistance = distance
                    bestPosition = position
                }
            }
        }

        return bestPosition
    }
}
