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
        // Handle potential corruption by checking if the value is actually an integer
        let value = UserDefaults.standard.object(forKey: highScoreKey)
        if let intValue = value as? Int, intValue >= 0 {
            highScore = intValue
        } else {
            // If the value is corrupted or invalid, default to 0 and clear the corrupted entry
            highScore = 0
            UserDefaults.standard.removeObject(forKey: highScoreKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: highScoreKey)
        UserDefaults.standard.synchronize()
    }
}