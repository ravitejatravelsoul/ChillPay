import Foundation

class StorageManager {
    static let shared = StorageManager()
    private let groupsKey = "groups"

    func saveGroups(_ groups: [Group]) {
        if let data = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(data, forKey: groupsKey)
        }
    }

    func loadGroups() -> [Group] {
        guard let data = UserDefaults.standard.data(forKey: groupsKey),
              let groups = try? JSONDecoder().decode([Group].self, from: data) else {
            return DummyData.sampleGroups
        }
        return groups
    }
}
