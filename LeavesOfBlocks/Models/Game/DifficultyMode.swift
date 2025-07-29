import Foundation
import SwiftUI

enum DifficultyMode: String, CaseIterable, Codable {
    case easy = "Easy"
    case moderate = "Moderate" 
    case hard = "Hard"
    
    var description: String {
        switch self {
        case .easy:
            return "Lots of small blocks, perfect for beginners"
        case .moderate:
            return "Balanced mix of small and large blocks"
        case .hard:
            return "Many large blocks, a real challenge!"
        }
    }
    
    var icon: String {
        switch self {
        case .easy:
            return "leaf.fill"
        case .moderate:
            return "square.stack.3d.up.fill"
        case .hard:
            return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .easy:
            return GameTheme.Colors.blockGreen
        case .moderate:
            return GameTheme.Colors.blockYellow
        case .hard:
            return GameTheme.Colors.blockRed
        }
    }
}