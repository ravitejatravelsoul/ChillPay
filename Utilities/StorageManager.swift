import Foundation

/// Manages persistence of groups using `UserDefaults`.
///
/// All groups are encoded as JSON and stored under a constant key.
class StorageManager {
    static let shared = StorageManager()
    private let groupsKey = "groups"
    
    private init() {}
    
    /// Persist the supplied array of groups to `UserDefaults`.
    func saveGroups(_ groups: [Group]) {
        do {
            let data = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(data, forKey: groupsKey)
        } catch {
            print("Failed to save groups: \(error)")
        }
    }
    
    /// Load all previously saved groups, or return an empty array if none.
    func loadGroups() -> [Group] {
        guard let data = UserDefaults.standard.data(forKey: groupsKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([Group].self, from: data)
        } catch {
            print("Failed to decode groups: \(error)")
            return []
        }
    }
}
