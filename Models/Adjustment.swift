import Foundation

struct Adjustment: Identifiable, Codable, Hashable {
    let id: UUID
    var from: User
    var to: User
    var amount: Double
    var date: Date

    /// Convert this adjustment into a dictionary suitable for storing in Firestore.
    func toDict() -> [String: Any] {
        return [
            "id": id.uuidString,
            "from": from.toDict(),
            "to": to.toDict(),
            "amount": amount,
            "date": date.timeIntervalSince1970
        ]
    }

    /// Recreate an adjustment from a Firestore dictionary.  Returns `nil` if
    /// mandatory fields cannot be parsed.
    static func fromDict(_ dict: [String: Any]) -> Adjustment? {
        guard
            let idString = dict["id"] as? String,
            let id = UUID(uuidString: idString),
            let fromDict = dict["from"] as? [String: Any],
            let fromUser = User.fromDict(fromDict),
            let toDict = dict["to"] as? [String: Any],
            let toUser = User.fromDict(toDict),
            let amount = dict["amount"] as? Double,
            let dateTs = dict["date"] as? Double
        else {
            return nil
        }
        return Adjustment(id: id, from: fromUser, to: toUser, amount: amount, date: Date(timeIntervalSince1970: dateTs))
    }
}
