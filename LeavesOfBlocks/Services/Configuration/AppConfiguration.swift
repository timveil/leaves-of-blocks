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
        static let enableDebugMode = Environment.current == .debug
    }

    // MARK: - Performance Settings

    struct Performance {
        static let maxFallingLeaves = 50
        static let animationFrameRate = 60.0
        static var dragUpdateThrottleInterval: TimeInterval { 1.0 / animationFrameRate }
    }
}

