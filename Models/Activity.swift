import Foundation

struct Activity: Identifiable, Codable, Hashable {
    let id: UUID
    var text: String
    var date: Date

    /// Convert this Activity into a dictionary suitable for storing in Firestore.
    /// Dates are stored as Unix timestamps and the UUID is saved as a string.
    func toDict() -> [String: Any] {
        return [
            "id": id.uuidString,
            "text": text,
            "date": date.timeIntervalSince1970
        ]
    }

    /// Recreate an Activity from a Firestore dictionary.  Returns `nil` if
    /// mandatory fields cannot be parsed.
    static func fromDict(_ dict: [String: Any]) -> Activity? {
        guard
            let idString = dict["id"] as? String,
            let id = UUID(uuidString: idString),
            let text = dict["text"] as? String,
            let dateTs = dict["date"] as? Double
        else {
            return nil
        }
        return Activity(id: id, text: text, date: Date(timeIntervalSince1970: dateTs))
    }
}
