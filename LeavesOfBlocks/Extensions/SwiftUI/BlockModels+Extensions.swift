import SwiftUI

// MARK: - Block Model Extensions

extension BlockColor {
    var color: Color {
        switch self {
        case .blue: return GameTheme.Colors.blockBlue
        case .green: return GameTheme.Colors.blockGreen
        case .red: return GameTheme.Colors.blockRed
        case .yellow: return GameTheme.Colors.blockYellow
        case .purple: return GameTheme.Colors.blockPurple
        case .orange: return GameTheme.Colors.blockOrange
        case .pink: return GameTheme.Colors.blockPink
        }
    }
}

extension BlockShape: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
    
    /// Returns the bounding box of the block using a single-pass algorithm
    ///
    /// Efficiently calculates the minimum and maximum row/column positions of the block,
    /// as well as its width and height. This method is optimized for performance by
    /// using a single pass through the block's positions.
    ///
    /// - Returns: A tuple containing minRow, maxRow, minCol, maxCol, width, and height
    ///
    /// ## Performance Notes
    /// - Uses `reduce` for single-pass calculation
    /// - Time complexity: O(n) where n is the number of positions
    /// - Space complexity: O(1)
    func getBounds() -> (minRow: Int, maxRow: Int, minCol: Int, maxCol: Int, width: Int, height: Int) {
        guard let first = positions.first else {
            return (minRow: 0, maxRow: 0, minCol: 0, maxCol: 0, width: 0, height: 0)
        }
        
        // Single-pass calculation for better performance
        let bounds = positions.reduce((first.row, first.row, first.col, first.col)) { bounds, position in
            (min(bounds.0, position.row),    // minRow
             max(bounds.1, position.row),    // maxRow
             min(bounds.2, position.col),    // minCol
             max(bounds.3, position.col))    // maxCol
        }
        
        return (
            minRow: bounds.0,
            maxRow: bounds.1,
            minCol: bounds.2,
            maxCol: bounds.3,
            width: bounds.3 - bounds.2 + 1,
            height: bounds.1 - bounds.0 + 1
        )
    }
}