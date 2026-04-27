import Foundation

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