import Foundation
import os

// MARK: - Build Configuration

enum BuildConfiguration {

    // MARK: - Debug Settings

    static let isDebugBuild: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    // MARK: - Logging

    /// Severity buckets for `log(_:level:)`. The order matters: each level
    /// includes itself and everything more severe.
    enum LogLevel: Int, CaseIterable {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
        case none = 5
    }

    /// Floor for what is emitted at runtime. Debug builds emit `.debug`
    /// and above; release builds emit `.warning` and above.
    static let currentLogLevel: LogLevel = isDebugBuild ? .debug : .warning

    /// Backing `os.Logger` shared by the app. Console.app filters on
    /// the subsystem and category.
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "timothy.veil.LeavesOfBlocks",
        category: "app"
    )

    /// Emits `message` to the unified logging system at the appropriate
    /// `OSLogType` for `level`.
    ///
    /// `file`/`function`/`line` are captured at the call site and prefixed
    /// to the message so log readers can locate the source.
    ///
    /// - Note: Messages are interpolated with `\(public:)` because game
    ///   telemetry doesn't contain user PII.
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue >= currentLogLevel.rawValue else { return }

        let filename = (file as NSString).lastPathComponent
        let prefix = "[\(filename):\(line)] \(function):"

        switch level {
        case .verbose, .debug:
            logger.debug("\(prefix, privacy: .public) \(message, privacy: .public)")
        case .info:
            logger.info("\(prefix, privacy: .public) \(message, privacy: .public)")
        case .warning:
            logger.warning("\(prefix, privacy: .public) \(message, privacy: .public)")
        case .error:
            logger.error("\(prefix, privacy: .public) \(message, privacy: .public)")
        case .none:
            break
        }
    }
}