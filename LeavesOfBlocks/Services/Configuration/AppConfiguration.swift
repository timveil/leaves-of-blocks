import Foundation
import UIKit

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
        static let dragUpdateThrottleInterval: TimeInterval = 1.0 / 60.0 // 60fps throttling
        static let previewCacheValidityDuration: TimeInterval = 0.1 // 100ms cache for expensive calculations
        static let enableReducedMotion = false // Could be tied to system settings
        static let enableLowPowerMode = false   // For older devices - reduced shadows and effects
        
        // Device-specific optimizations
        static var isOlderDevice: Bool {
            // Check for iPhone 12 Pro Max and older devices
            let deviceModel = UIDevice.current.model
            let systemVersion = UIDevice.current.systemVersion
            
            // Simple heuristic - could be enhanced with more detailed device detection
            return ProcessInfo.processInfo.processorCount < 6 || // Less than 6 CPU cores
                   ProcessInfo.processInfo.physicalMemory < 4_000_000_000 // Less than 4GB RAM
        }
        
        static var shouldUseLowPowerMode: Bool {
            return enableLowPowerMode || isOlderDevice || ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        
        // Performance monitoring flags
        static let enableFrameRateMonitoring = Environment.current == .debug
        static let enableMemoryMonitoring = Environment.current != .release
        static let logPerformanceMetrics = Environment.current == .debug
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