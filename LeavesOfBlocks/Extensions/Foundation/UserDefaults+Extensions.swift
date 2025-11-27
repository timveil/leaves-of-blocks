import Foundation

extension UserDefaults {

    /// Safely retrieves a Codable object from UserDefaults
    func codableObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            BuildConfiguration.log("Failed to decode \(type) for key '\(key)': \(error.localizedDescription)", level: .warning)
            return nil
        }
    }

    /// Safely stores a Codable object in UserDefaults
    func setCodableObject<T: Codable>(_ object: T?, forKey key: String) {
        guard let object = object else {
            removeObject(forKey: key)
            return
        }

        do {
            let data = try JSONEncoder().encode(object)
            set(data, forKey: key)
        } catch {
            BuildConfiguration.log("Failed to encode object for key '\(key)': \(error.localizedDescription)", level: .warning)
        }
    }
}