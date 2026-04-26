import Foundation
import SwiftUI

enum DifficultyMode: String, CaseIterable, Codable {
    case easy = "Easy"
    case moderate = "Moderate" 
    case hard = "Hard"
    
    var displayName: String {
        switch self {
        case .easy: return "difficulty_gentle".localized
        case .moderate: return "difficulty_bold".localized
        case .hard: return "difficulty_wild".localized
        }
    }

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
    
    var localizedDescription: String {
        switch self {
        case .easy:
            return "difficulty_easy_desc".localized
        case .moderate:
            return "difficulty_moderate_desc".localized
        case .hard:
            return "difficulty_hard_desc".localized
        }
    }

    var acornCount: Int {
        switch self {
        case .easy: return 1
        case .moderate: return 2
        case .hard: return 3
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