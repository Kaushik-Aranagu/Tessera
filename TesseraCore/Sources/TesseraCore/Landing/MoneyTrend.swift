import Foundation

/// "October is running a little under September." The month so far against the same days of the last month, as a
/// clause and never a figure (Money landing, design 131). Only one currency is compared (spends in two currencies
/// never add up), and nothing is said before the month is a week old or the last month has fewer than three spends.
@MainActor
public struct MoneyTrend {
    public enum Direction: String, Sendable {
        case wellUnder, littleUnder, aboutTheSame, littleOver, wellOver

        /// What the ratio of this month so far to last month's same days says.
        static func of(ratio: Double) -> Direction {
            switch ratio {
            case ..<0.8: .wellUnder
            case ..<0.95: .littleUnder
            case ...1.05: .aboutTheSame
            case ...1.25: .littleOver
            default: .wellOver
            }
        }

        var phrase: String {
            switch self {
            case .wellUnder: "well under"
            case .littleUnder: "a little under"
            case .aboutTheSame: "about the same as"
            case .littleOver: "a little over"
            case .wellOver: "well over"
            }
        }
    }

    public struct Result: Sendable, Equatable {
        public let direction: Direction
        public let month: String
        public let previous: String

        /// "October is running a little under September" (no full stop; the sentence adds it).
        public var clause: String {
            "\(month) is running \(direction.phrase) \(previous)"
        }
    }

    public static let daysBeforeItSpeaks = 7
    public static let spendsNeededLastMonth = 3

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public func compare(now: Date, calendar: Calendar = .current) -> Result? {
        let day = TesseraDay(calendar: calendar)
        let thisMonth = day.month(containing: now)
        guard let lastStart = day.calendar.date(byAdding: .month, value: -1, to: thisMonth.start) else { return nil }
        let lastMonth = day.month(containing: lastStart)
        // The days so far, counted by logical days (04:00 edges).
        let elapsed = day.calendar.dateComponents([.day], from: thisMonth.start, to: day.start(of: now)).day ?? 0
        guard elapsed + 1 >= Self.daysBeforeItSpeaks,
              let cutoff = day.calendar.date(byAdding: .day, value: elapsed + 1, to: lastMonth.start),
              cutoff <= lastMonth.end else { return nil }
        let ledger = SpendLedger(store: store, classes: classes)
        let current = ledger.entries(inMonthOf: now, calendar: calendar).filter { $0.spentAt <= now }
        let before = ledger.entries(inMonthOf: lastStart, calendar: calendar).filter { $0.spentAt < cutoff }
        guard before.count >= Self.spendsNeededLastMonth else { return nil }
        // One currency across both, or nothing: no sums across currencies.
        guard Set((current + before).map { $0.currency ?? "" }).count == 1 else { return nil }
        let last = before.reduce(Decimal(0)) { $0 + $1.amount }
        guard last > 0 else { return nil }
        let now = current.reduce(Decimal(0)) { $0 + $1.amount }
        let ratio = (now as NSDecimalNumber).doubleValue / (last as NSDecimalNumber).doubleValue
        return Result(direction: .of(ratio: ratio), month: Self.monthName(thisMonth.start, day.calendar),
                      previous: Self.monthName(lastMonth.start, day.calendar))
    }

    static func monthName(_ date: Date, _ calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date)
    }
}
