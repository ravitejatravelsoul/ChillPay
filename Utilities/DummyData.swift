import Foundation

struct DummyData {
    static let sampleUsers: [User] = [
        User(id: "user-alice", name: "Alice"),
        User(id: "user-bob", name: "Bob"),
        User(id: "user-charlie", name: "Charlie")
    ]

    static let sampleGroups: [Group] = [
        Group(
            id: UUID().uuidString, // <-- id must be String, not UUID
            name: "Trip to Goa",
            members: sampleUsers,
            expenses: [],
            isPublic: false,
            budget: nil,
            activity: [],
            currency: .inr,
            colorName: "blue",
            iconName: "person.3.fill",
            adjustments: [],
            simplifyDebts: false
        )
    ]
}
