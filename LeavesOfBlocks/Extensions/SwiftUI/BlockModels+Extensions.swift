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
}