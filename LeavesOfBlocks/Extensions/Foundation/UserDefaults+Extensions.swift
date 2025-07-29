import Foundation

extension UserDefaults {
    
    /// Safely retrieves a Codable object from UserDefaults
    func codableObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    /// Safely stores a Codable object in UserDefaults
    func setCodableObject<T: Codable>(_ object: T?, forKey key: String) {
        guard let object = object else {
            removeObject(forKey: key)
            return
        }
        
        if let data = try? JSONEncoder().encode(object) {
            set(data, forKey: key)
        }
    }
}