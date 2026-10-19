import Foundation

/// The calendar mount (M4 slice 1, docs/research/calendar-health-fixtures.md C01 to C19): his calendar mirrored as
/// read-only `Event` objects, one per occurrence EventKit returns. Pure Swift: the app turns `EKEvent`s into
/// `CalendarEventInput`s and runs `SyncCalendar`; nothing here imports EventKit.
public enum CalendarAccess: String, Codable, Sendable {
    case fullAccess, writeOnly, notDetermined, denied, restricted
}

public enum EventAttendance: String, Codable, Sendable {
    case accepted, tentative, pending, declined, unknown
}

public enum EventAvailability: String, Codable, Sendable {
    case busy, free, tentative, unavailable
}

/// One occurrence as EventKit hands it over.
public struct CalendarEventInput: Codable, Sendable, Equatable {
    public var externalID: String
    public var title: String
    public var start: Date
    public var end: Date
    public var occurrenceDate: Date?
    public var isAllDay: Bool
    public var timeZone: String?
    public var isRecurring: Bool
    public var isDetached: Bool
    public var isCancelled: Bool
    public var availability: EventAvailability
    public var calendarName: String
    public var calendarIsBirthday: Bool
    /// An owned calendar (he can edit it): another person's shared calendar is mirrored for reference only.
    public var calendarIsMine: Bool
    public var selfStatus: EventAttendance
    public var location: String?
    public var birthdayContactID: String?

    public init(externalID: String, title: String, start: Date, end: Date, occurrenceDate: Date? = nil,
                isAllDay: Bool = false, timeZone: String? = nil, isRecurring: Bool = false, isDetached: Bool = false,
                isCancelled: Bool = false, availability: EventAvailability = .busy, calendarName: String = "",
                calendarIsBirthday: Bool = false, calendarIsMine: Bool = true, selfStatus: EventAttendance = .unknown,
                location: String? = nil, birthdayContactID: String? = nil)
    {
        self.externalID = externalID
        self.title = title
        self.start = start
        self.end = end
        self.occurrenceDate = occurrenceDate
        self.isAllDay = isAllDay
        self.timeZone = timeZone
        self.isRecurring = isRecurring
        self.isDetached = isDetached
        self.isCancelled = isCancelled
        self.availability = availability
        self.calendarName = calendarName
        self.calendarIsBirthday = calendarIsBirthday
        self.calendarIsMine = calendarIsMine
        self.selfStatus = selfStatus
        self.location = location
        self.birthdayContactID = birthdayContactID
    }

    /// "standup-1@2026-10-20T16:30Z": the identifier shared by all occurrences plus the original occurrence in UTC.
    /// `occurrenceDate` survives an edit of one occurrence, so an edit is an update, not a delete and an insert (C02).
    public var key: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        return "\(externalID)@\(formatter.string(from: occurrenceDate ?? start))"
    }

    /// Mine: an owned calendar, or one he is invited on (a status other than "unknown").
    public var countsForMe: Bool {
        calendarIsMine || selfStatus != .unknown
    }

    /// Busy time: his, not declined, not cancelled, not free, not all-day (C03 to C05, C11, C16).
    public var isBusy: Bool {
        countsForMe && selfStatus != .declined && !isCancelled && availability != .free && !isAllDay
            && !calendarIsBirthday
    }
}

/// Mirrors the window into `Event` objects: inserts, updates by key, deletes what vanished inside the window, and
/// keeps what rolled out the back, frozen (C17). Written as the system, so it is never one of his actions.
public struct SyncCalendar: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "syncCalendar", summary: "Mirror the calendar window", parameters: [], isOfferedToModel: false
    )

    public struct Result: Equatable, Sendable {
        public var created = 0
        public var updated = 0
        public var deleted = 0
        public var access: CalendarAccess = .fullAccess
    }

    public var inputs: [CalendarEventInput]
    public var windowStart: Date
    public var windowEnd: Date
    public var access: CalendarAccess

    public init(inputs: [CalendarEventInput], windowStart: Date, windowEnd: Date,
                access: CalendarAccess = .fullAccess)
    {
        self.inputs = inputs
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.access = access
    }

    static func objectID(for key: String) -> UUID {
        SystemCatalog.stableID("event:\(key)")
    }

    /// One input per key: the copy that carries his own participant status wins, else the first (C15).
    static func deduplicated(_ inputs: [CalendarEventInput]) -> [CalendarEventInput] {
        var chosen: [String: CalendarEventInput] = [:]
        var order: [String] = []
        for input in inputs {
            let key = input.key
            if let held = chosen[key] {
                let better = (held.selfStatus == .unknown && input.selfStatus != .unknown)
                    || (!held.calendarIsMine && input.calendarIsMine && held.selfStatus == input.selfStatus)
                if better {
                    chosen[key] = input
                }
            } else {
                chosen[key] = input
                order.append(key)
            }
        }
        return order.compactMap { chosen[$0] }
    }

    public func apply(_ transaction: inout Transaction) throws -> Result {
        var result = Result()
        result.access = access
        // Not connected (write-only, denied, restricted, not asked): nothing is written, existing events stay frozen.
        guard access == .fullAccess else { return result }
        let eventClass = try transaction.classDef(.event)
        let current = Self.deduplicated(inputs)
        var seen = Set<UUID>()
        for input in current {
            let id = Self.objectID(for: input.key)
            seen.insert(id)
            let existing = transaction.store.object(id: id)
            let object: ObjectRecord
            if let existing, !existing.isDeleted {
                object = existing
            } else if existing != nil {
                continue // deleted by an earlier sync: stays gone
            } else {
                object = transaction.create(eventClass, title: input.title, id: id)
                result.created += 1
            }
            let before = transaction.ops.count
            if object.title != input.title {
                transaction.setTitle(input.title, on: object)
            }
            try write(input, on: object, in: &transaction)
            if existing != nil, transaction.ops.count > before {
                result.updated += 1
            }
        }
        // In-window absence is a delete; out-of-window objects are frozen, never deleted.
        for object in transaction.store.objects(of: eventClass) where !object.isDeleted && !seen.contains(object.id) {
            guard let start = transaction.store.value("start", of: object)?.dateValue else { continue }
            if start >= windowStart, start < windowEnd {
                transaction.delete(object)
                result.deleted += 1
            } else if transaction.store.value("frozen", of: object) != .bool(true) {
                try transaction.set("frozen", to: .bool(true), on: object)
            }
        }
        return result
    }

    @MainActor
    private func write(_ input: CalendarEventInput, on object: ObjectRecord, in transaction: inout Transaction) throws {
        let fields: [(String, FieldValue?)] = [
            ("start", .date(input.start)), ("end", .date(input.end)), ("allDay", .bool(input.isAllDay)),
            ("calendarName", .text(input.calendarName)), ("location", input.location.map(FieldValue.text)),
            ("isRecurring", .bool(input.isRecurring)), ("key", .text(input.key)), ("busy", .bool(input.isBusy)),
            ("attendance", .text(input.selfStatus.rawValue)), ("cancelled", .bool(input.isCancelled)),
            ("eventTimeZone", input.timeZone.map(FieldValue.text)),
            ("kind", .text(input.calendarIsBirthday ? "birthday" : "event")),
            ("contactId", input.birthdayContactID.map(FieldValue.text)), ("edited", .bool(input.isDetached)),
            ("countsForMe", .bool(input.countsForMe)),
            ("marker", .bool(input.end <= input.start && !input.isAllDay)), ("frozen", .bool(false)),
        ]
        for (key, value) in fields {
            try transaction.set(key, to: value, on: object)
        }
    }

    public var logsWhenEmpty: Bool {
        false
    }

    /// Calendar and Health values never reach the op log (nor, through it, a backup or an export).
    public var recordsOps: Bool {
        false
    }

    public func summary(in _: ObjectStore) -> String {
        "Synced the calendar"
    }
}

/// What the calendar says about a day: busy minutes as the union of the day's busy events (never double-counted),
/// split at local midnight in the device's zone, and the pairs that overlap (C07, C14).
@MainActor
public struct CalendarDay {
    public struct Conflict: Equatable {
        public let first: UUID
        public let second: UUID
    }

    public let busyMinutes: Int
    public let conflicts: [Conflict]
    public let events: [ObjectRecord]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], day: Date, calendar: Calendar) {
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86400)
        var clipped: [(start: Date, end: Date, id: UUID)] = []
        var shown: [ObjectRecord] = []
        for object in classes[.event].map({ store.objects(of: $0) }) ?? [] where !object.isDeleted {
            guard let start = store.value("start", of: object)?.dateValue,
                  let end = store.value("end", of: object)?.dateValue else { continue }
            let allDay = store.value("allDay", of: object) == .bool(true)
            let overlaps = allDay ? (start < dayEnd && max(end, start) >= dayStart) : (start < dayEnd && end > dayStart)
            if overlaps || (end == start && start >= dayStart && start < dayEnd) {
                shown.append(object)
            }
            guard store.value("busy", of: object) == .bool(true), end > start else { continue }
            let from = max(start, dayStart), to = min(end, dayEnd)
            if from < to {
                clipped.append((from, to, object.id))
            }
        }
        clipped.sort { $0.start < $1.start }
        var total: TimeInterval = 0
        var runStart: Date?
        var runEnd: Date?
        var pairs: [Conflict] = []
        for (index, item) in clipped.enumerated() {
            if let end = runEnd, item.start < end {
                runEnd = max(end, item.end)
            } else {
                if let runStart, let runEnd {
                    total += runEnd.timeIntervalSince(runStart)
                }
                runStart = item.start
                runEnd = item.end
            }
            for earlier in clipped[..<index] where earlier.end > item.start {
                pairs.append(Conflict(first: earlier.id, second: item.id))
            }
        }
        if let runStart, let runEnd {
            total += runEnd.timeIntervalSince(runStart)
        }
        busyMinutes = Int((total / 60).rounded())
        conflicts = pairs
        events = shown.sorted {
            (store.value("start", of: $0)?.dateValue ?? .distantPast)
                < (store.value("start", of: $1)?.dateValue ?? .distantPast)
        }
    }
}

/// Busy time inside a range: the union of the mirrored busy events clipped to it, never double-counted (slice 3).
@MainActor
public enum CalendarBusy {
    public static func minutes(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], from: Date,
                               to: Date) -> Double
    {
        guard to > from, let eventClass = classes[.event] else { return 0 }
        var spans: [(start: Date, end: Date)] = []
        for object in store.objects(of: eventClass) where !object.isDeleted {
            guard store.value("busy", of: object) == .bool(true),
                  let start = store.value("start", of: object)?.dateValue,
                  let end = store.value("end", of: object)?.dateValue else { continue }
            let clippedStart = max(start, from), clippedEnd = min(end, to)
            if clippedStart < clippedEnd {
                spans.append((clippedStart, clippedEnd))
            }
        }
        spans.sort { $0.start < $1.start }
        var total: TimeInterval = 0
        var current: (start: Date, end: Date)?
        for span in spans {
            if let held = current, span.start <= held.end {
                current = (held.start, max(held.end, span.end))
            } else {
                if let held = current {
                    total += held.end.timeIntervalSince(held.start)
                }
                current = span
            }
        }
        if let held = current {
            total += held.end.timeIntervalSince(held.start)
        }
        return total / 60
    }
}
