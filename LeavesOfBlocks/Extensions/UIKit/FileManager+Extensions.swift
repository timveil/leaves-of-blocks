import Foundation

extension FileManager {
    
    /// Returns the app's documents directory URL
    var documentsDirectory: URL {
        return urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Returns the app's caches directory URL
    var cachesDirectory: URL {
        return urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    /// Creates a directory if it doesn't exist
    func createDirectoryIfNeeded(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// Returns the size of a file in bytes
    func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
}