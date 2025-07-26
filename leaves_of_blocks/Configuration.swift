import Foundation

// MARK: - Application Configuration

struct AppConfiguration {
    
    // MARK: - Environment
    
    enum Environment {
        case debug
        case release
        case testing
        
        static var current: Environment {
            #if DEBUG
            return .debug
            #elseif TESTING
            return .testing
            #else
            return .release
            #endif
        }
    }
    
    // MARK: - Feature Flags
    
    struct FeatureFlags {
        static let enableAnimations = true
        static let enableSoundEffects = false  // Future feature
        static let enableHapticFeedback = true // Future feature
        static let enableDebugMode = Environment.current == .debug
        static let enablePerformanceMonitoring = Environment.current != .release
        static let enableAnalytics = Environment.current == .release
    }
    
    // MARK: - Game Settings
    
    struct GameSettings {
        static let defaultDifficulty = Difficulty.normal
        static let enableAutoSave = true
        static let maxHighScores = 10
        static let enableTutorial = true
    }
    
    // MARK: - Performance Settings
    
    struct Performance {
        static let maxFallingLeaves = 50
        static let animationFrameRate = 60.0
        static let enableReducedMotion = false // Could be tied to system settings
        static let enableLowGameMode = false   // For older devices
    }
    
    // MARK: - Accessibility
    
    struct Accessibility {
        static let enableVoiceOver = true
        static let enableHighContrast = false
        static let enableLargeText = false
        static let minimumTouchTarget: CGFloat = 44.0
    }
}

// MARK: - Difficulty Levels

enum Difficulty: String, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    case expert = "Expert"
    
    var description: String {
        switch self {
        case .easy:
            return "Larger blocks, slower pace"
        case .normal:
            return "Balanced gameplay"
        case .hard:
            return "Smaller blocks, faster pace"
        case .expert:
            return "Complex shapes, maximum challenge"
        }
    }
    
    var blockGenerationWeights: [Double] {
        switch self {
        case .easy:
            return [4.0, 3.0, 2.0, 1.5, 1.0, 0.5] // Favor smaller blocks
        case .normal:
            return [3.0, 2.5, 2.0, 1.5, 1.0, 0.5] // Balanced
        case .hard:
            return [2.0, 2.0, 2.0, 2.0, 1.5, 1.0] // More even distribution
        case .expert:
            return [1.0, 1.5, 2.0, 2.5, 2.5, 3.0] // Favor complex blocks
        }
    }
}

// MARK: - User Preferences

@MainActor
class UserPreferences: ObservableObject {
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let difficulty = "user_difficulty"
        static let soundEnabled = "sound_enabled"
        static let hapticEnabled = "haptic_enabled"
        static let tutorialCompleted = "tutorial_completed"
        static let gamesPlayed = "games_played"
        static let lastPlayDate = "last_play_date"
    }
    
    // MARK: - Published Properties
    
    @Published var difficulty: Difficulty = .normal {
        didSet {
            UserDefaults.standard.set(difficulty.rawValue, forKey: Keys.difficulty)
        }
    }
    
    @Published var soundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }
    
    @Published var hapticEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(hapticEnabled, forKey: Keys.hapticEnabled)
        }
    }
    
    @Published var tutorialCompleted: Bool = false {
        didSet {
            UserDefaults.standard.set(tutorialCompleted, forKey: Keys.tutorialCompleted)
        }
    }
    
    // MARK: - Computed Properties
    
    var gamesPlayed: Int {
        get { UserDefaults.standard.integer(forKey: Keys.gamesPlayed) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.gamesPlayed) }
    }
    
    var lastPlayDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastPlayDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastPlayDate) }
    }
    
    // MARK: - Initialization
    
    init() {
        loadPreferences()
    }
    
    // MARK: - Methods
    
    private func loadPreferences() {
        if let difficultyString = UserDefaults.standard.string(forKey: Keys.difficulty),
           let loadedDifficulty = Difficulty(rawValue: difficultyString) {
            difficulty = loadedDifficulty
        }
        
        soundEnabled = UserDefaults.standard.bool(forKey: Keys.soundEnabled)
        hapticEnabled = UserDefaults.standard.bool(forKey: Keys.hapticEnabled)
        tutorialCompleted = UserDefaults.standard.bool(forKey: Keys.tutorialCompleted)
    }
    
    func recordGamePlayed() {
        gamesPlayed += 1
        lastPlayDate = Date()
    }
    
    func resetAllPreferences() {
        difficulty = .normal
        soundEnabled = true
        hapticEnabled = true
        tutorialCompleted = false
        
        // Clear UserDefaults
        for key in [Keys.difficulty, Keys.soundEnabled, Keys.hapticEnabled, Keys.tutorialCompleted, Keys.gamesPlayed, Keys.lastPlayDate] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

// MARK: - App Constants

struct AppConstants {
    
    // MARK: - App Information
    
    static let appName = "Leaves of Blocks"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - External Links
    
    struct URLs {
        static let appStore = URL(string: "https://apps.apple.com/app/leaves-of-blocks")
        static let support = URL(string: "mailto:support@nineforty.one")
        static let privacy = URL(string: "https://nineforty.one/privacy")
        static let github = URL(string: "https://github.com/timveil/leaves-of-blocks")
    }
    
    // MARK: - Notifications
    
    struct NotificationNames {
        static let gameStateChanged = Notification.Name("gameStateChanged")
        static let highScoreUpdated = Notification.Name("highScoreUpdated")
        static let preferencesChanged = Notification.Name("preferencesChanged")
    }
    
    // MARK: - File Paths
    
    struct FilePaths {
        static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        static let savedGamesDirectory = documentsDirectory.appendingPathComponent("SavedGames")
        static let configDirectory = documentsDirectory.appendingPathComponent("Config")
    }
}

// MARK: - Build Configuration

struct BuildConfiguration {
    
    // MARK: - Debug Settings
    
    static let isDebugBuild: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    static let isTestBuild: Bool = {
        #if TESTING
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Logging
    
    enum LogLevel: Int, CaseIterable {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
        case none = 5
        
        var description: String {
            switch self {
            case .verbose: return "VERBOSE"
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            case .none: return "NONE"
            }
        }
    }
    
    static let currentLogLevel: LogLevel = {
        if isDebugBuild {
            return .debug
        } else {
            return .warning
        }
    }()
    
    // MARK: - Logging Helper
    
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue >= currentLogLevel.rawValue else { return }
        
        let filename = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        
        print("[\(timestamp)] [\(level.description)] [\(filename):\(line)] \(function): \(message)")
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}