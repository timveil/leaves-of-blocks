import Foundation

class HighScoreManager: ObservableObject {
    @Published var highScore: Int = 0
    
    private let highScoreKey = "LeaveOfBlocksHighScore"
    
    init() {
        loadHighScore()
    }
    
    func updateHighScore(_ score: Int) {
        if score > highScore {
            highScore = score
            saveHighScore()
        }
    }
    
    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: highScoreKey)
    }
    
    private func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: highScoreKey)
    }
}