import Foundation

/// Static convenience values used to populate the app with sample content on
/// first launch.  If no data is saved in `UserDefaults`, these values are
/// returned to give the user something to interact with.
struct DummyData {
    static let sampleUsers = [
        User(id: UUID(), name: "Alice"),
        User(id: UUID(), name: "Bob"),
        User(id: UUID(), name: "Charlie")
    ]
    
    /// Sample groups demonstrating a basic trip with three members.  Only
    /// the name and members are needed; optional properties fall back to
    /// default values defined in Group’s initializer.
    static let sampleGroups = [
        Group(
            name: "Trip to Goa",
            members: sampleUsers
        )
    ]
}
