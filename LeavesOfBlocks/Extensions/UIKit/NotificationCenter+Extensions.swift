import Foundation

extension NotificationCenter {
    
    /// Posts a game state change notification
    func postGameStateChange() {
        post(name: AppConstants.NotificationNames.gameStateChanged, object: nil)
    }
    
    /// Posts a high score update notification
    func postHighScoreUpdate(newScore: Int) {
        post(
            name: AppConstants.NotificationNames.highScoreUpdated,
            object: nil,
            userInfo: ["newScore": newScore]
        )
    }
}