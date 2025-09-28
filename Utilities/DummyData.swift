import Foundation

struct DummyData {
    static let sampleUsers: [User] = [
        User(id: UUID(), name: "Alice"),
        User(id: UUID(), name: "Bob"),
        User(id: UUID(), name: "Charlie")
    ]

    static let sampleGroups: [Group] = [
        Group(
            id: UUID(),
            name: "Trip to Goa",
            members: sampleUsers,
            expenses: [],
            isPublic: false,
            budget: nil,
            activity: [],
            currency: .inr,
            colorName: "blue",
            iconName: "person.3.fill",
            adjustments: []
        )
    ]
}
