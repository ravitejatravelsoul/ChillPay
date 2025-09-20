import Foundation

class GroupViewModel: ObservableObject {
    @Published var groups: [Group] = [] {
        didSet {
            StorageManager.shared.saveGroups(groups)
        }
    }

    init() {
        self.groups = StorageManager.shared.loadGroups()
    }
    
    func addGroup(_ group: Group) {
        groups.append(group)
    }
    
    func updateGroup(_ group: Group) {
        if let idx = groups.firstIndex(where: { $0.id == group.id }) {
            groups[idx] = group
        }
    }
}
