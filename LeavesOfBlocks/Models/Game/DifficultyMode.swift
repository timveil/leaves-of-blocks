import Foundation

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

    /// SF Symbol name representing this difficulty.
    var iconName: String {
        switch self {
        case .easy:
            return "leaf.fill"
        case .moderate:
            return "square.stack.3d.up.fill"
        case .hard:
            return "flame.fill"
        }
    }
}
