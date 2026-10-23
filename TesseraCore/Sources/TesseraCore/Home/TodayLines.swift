import Foundation

/// What a line of Today's day is: one of his items (an app's, or a task's: nil app), or the sun.
public enum TodayKind: Equatable, Sendable {
    case item(AppID?)
    case sunrise
    case sunset
}

/// One line of the day on Today: a name, a time and a kind. Calendar events are lines too (`isCalendar`), and calendar
/// text is phone only: a calendar line is drawn on Today and goes nowhere else, not to Claude, a backup, a log, a
/// widget or one of Tess's Claude lines (a test scans for these types in those places).
public struct TodayLine: Equatable, Sendable {
    /// A title as shown: "Private" for anything private, walled or secret.
    public let name: String
    public let time: Date
    public let kind: TodayKind
    public let isCalendar: Bool
    public let isPrivate: Bool
    /// The time has passed (his item is behind him).
    public let isPast: Bool
}

/// The day, in order, and the one line about it: "Three things left, the next at 6:30 pm".
public struct TodayFacts: Equatable, Sendable {
    public let lines: [TodayLine]
    /// His items still ahead (the sun is not one).
    public let left: Int
    public let factLine: String

    static let words = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]

    static func factLine(left: Int, next: Date?, calendar: Calendar) -> String {
        guard left > 0, let next else { return "Nothing left today" }
        let clock = HouseTime.clock(next, calendar: calendar)
        if left == 1 {
            return "One thing left, at \(clock)"
        }
        let count = left <= words.count ? words[left - 1] : "\(left)"
        return "\(count) things left, the next at \(clock)"
    }
}

@MainActor
public extension TodayFacts {
    /// Tasks, training, routines, calendar events and the sun, by time. `events` are the day's hands events (workout,
    /// routines); a cook is not a line. Every title is masked the way the landings mask them.
    static func make(engine: ActionEngine, facts: MosaicFacts, events: [HandsEvent] = [],
                     calendar: Calendar = .current) -> TodayFacts
    {
        let store = engine.store, classes = engine.classes
        let now = facts.now
        let interval = TesseraDay(calendar: calendar).interval(of: now)
        func inDay(_ date: Date) -> Bool {
            interval.contains(date)
        }
        var lines: [TodayLine] = []
        func add(_ title: String, at time: Date, kind: TodayKind, calendarEvent: Bool = false,
                 object: ObjectRecord? = nil, masked: String? = nil)
        {
            let name = masked ?? AppSummaryLines.shown(title, in: store, classes: classes, of: object).text
            lines.append(TodayLine(name: name, time: time, kind: kind, isCalendar: calendarEvent,
                                   isPrivate: name == "Private" || name.hasPrefix("Private "), isPast: time < now))
        }
        if let taskClass = classes[.task] {
            for task in store.objects(of: taskClass) where !task.isDeleted
                && store.value("isDone", of: task) != .bool(true)
            {
                guard let when = store.value("startsAt", of: task)?.dateValue, inDay(when) else { continue }
                // A task about a recipe is a cook, which is not one of these lines.
                if store.linkedObjects("about", of: task).contains(where: { $0.classDef?.id == classes[.recipe]?.id }) {
                    continue
                }
                add(task.title, at: when, kind: .item(nil), object: task)
            }
        }
        for event in events where (event.app == .training || event.app == .routines) && inDay(event.start) {
            let masked = event.isPrivate ? event.label : nil
            add(event.label, at: event.start, kind: .item(event.app), masked: masked)
        }
        if let eventClass = classes[.event] {
            for event in store.objects(of: eventClass) where !event.isDeleted
                && store.value("cancelled", of: event) != .bool(true) && store.value("allDay", of: event) != .bool(true)
            {
                guard let when = store.value("start", of: event)?.dateValue, inDay(when) else { continue }
                add(event.title, at: when, kind: .item(nil), calendarEvent: true, object: event)
            }
        }
        add("Sunrise", at: facts.sunrise, kind: .sunrise, masked: "Sunrise")
        add("Sunset", at: facts.sunset, kind: .sunset, masked: "Sunset")
        lines.sort { ($0.time, $0.name) < ($1.time, $1.name) }
        let ahead = lines.filter { $0.kind != .sunrise && $0.kind != .sunset && !$0.isPast }
        return TodayFacts(lines: lines, left: ahead.count,
                          factLine: factLine(left: ahead.count, next: ahead.first?.time, calendar: calendar))
    }
}
