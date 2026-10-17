import Foundation

/// How often he buys an ingredient, read from the op log (the grocery rows are deleted at the shop's end, the ops
/// stay).
/// Only his own checks count (`.user`, `.tess`, `.intent`), never `.system` ones (SH26).
@MainActor
public struct BuyCadence {
    /// Fewest buys before a cadence is said (SL-I5: two buys is empty).
    public static let minimumBuys = 3

    /// The days he bought it on, oldest first, one per day.
    public let days: [Date]

    /// "About every N days": the mean gap between the first and last buy day, rounded to the nearest day; nil under
    /// three buys.
    public var everyDays: Int? {
        guard days.count >= Self.minimumBuys, let first = days.first, let last = days.last else { return nil }
        let calendar = calendar
        let span = calendar.dateComponents([.day], from: first, to: last).day ?? 0
        let gaps = Double(days.count - 1)
        return max(1, Int((Double(span) / gaps).rounded()))
    }

    /// "You buy it about every 9 days." Nil under three buys.
    public var line: String? {
        everyDays.map { "You buy it about every \($0) days." }
    }

    private let calendar: Calendar

    public init(of ingredient: ObjectRecord, engine: ActionEngine, calendar: Calendar = .current) {
        self.calendar = calendar
        let day = TesseraDay(calendar: calendar)
        // The grocery rows that are about this ingredient, deleted or not.
        let items = Set((ingredient.incomingLinks ?? []).compactMap { $0.from?.id })
        var seen = Set<Date>()
        var buys: [Date] = []
        for record in engine.store.context.all(OpRecord.self)
            where record.action == "checkListItem" && record.state == .committed
            && TaskStory.handActors.contains(record.actor)
            && record.objectIDs.contains(where: items.contains)
            && record.ops.contains(where: { op in
                if case let .setValue(_, _, _, new) = op, new == .bool(true) {
                    true
                } else {
                    false
                }
            })
        {
            let key = day.day(of: record.createdAt)
            if seen.insert(key).inserted {
                buys.append(key)
            }
        }
        days = buys.sorted()
    }
}
