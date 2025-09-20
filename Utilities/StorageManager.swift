import Foundation

/// Manages persistence of groups using `UserDefaults`.
///
/// All groups are encoded as JSON and stored under a constant key.  When
/// reading, if decoding fails or there is no stored data, the `DummyData`
/// sample groups are returned instead.  This class is a singleton for
/// convenience.
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
    
    /// Load all previously saved groups, or return sample groups on first launch.
    func loadGroups() -> [Group] {
        guard let data = UserDefaults.standard.data(forKey: groupsKey) else {
            return DummyData.sampleGroups
        }
        do {
            return try JSONDecoder().decode([Group].self, from: data)
        } catch {
            print("Failed to decode groups: \(error)")
            return DummyData.sampleGroups
        }
    }
}
