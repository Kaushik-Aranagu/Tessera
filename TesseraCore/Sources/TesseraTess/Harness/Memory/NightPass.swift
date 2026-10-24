import Foundation
import TesseraCore

/// Memory spec M5: the rules half of the 4 am night pass, as a pure planner. It reads the open beliefs, the typed
/// series behind usual-time beliefs, the day's items and the notebooks, and returns the steps to take. The store
/// side runs each step through its action (`ConfirmBelief`, `ReviseBelief`, a summary object, a notebook delete),
/// so every change lands in the op log and Undo works.
///
/// Rules, in order:
/// 1. **Merge** open beliefs that say the same thing (same subject, key and value): keep the one he kept, then the
///    one he told, then the most confirmed, then the oldest. The others close, replaced by it. A key that holds one
///    value at a time (`usualTime`, `cadence`) also merges two open beliefs that disagree (I7): his kept or told one
///    wins, then the newest. Other keys may hold several values at once (he prefers rice and beans), so only exact
///    duplicates merge there. A belief he told or kept never closes here, and when two of his disagree nothing in
///    that group closes: he settles it, not the night.
/// 2. **Close what changed:** a usual time whose last 4 events have 3 off the old pattern (more than 90 minutes
///    away) is revised to the median of the off-pattern times, with those events as evidence.
/// 3. **Verify noticed beliefs:** a noticed or inferred usual time, not yet a fact, with 3 of its last 4 events on
///    the pattern and a new one on the closing day, is confirmed (two confirmations make it a fact, M1).
/// 4. **Summaries:** the day that just closed, and on Sundays its week, as plain lines with counts and shown names.
/// 5. **Prune** notebooks over their limit, oldest unused file first.
/// 6. **Refresh** the expertise packs whose hash moved (M4).
/// 7. **Reflect:** one call per agent whose room had activity that day (Sonnet, through the Door and its policy). It
///    reads the day's items for its room plus its beliefs, and may propose up to 5 inferred beliefs with evidence.
///
/// What he told her or kept is never revised by a rule: his words win until he says otherwise. A second run on the
/// same night plans nothing.
public struct NightPass: Sendable {
    /// One dated event in a typed series ("a workout started at 18:30").
    public struct Event: Sendable, Equatable {
        public var id: UUID
        public var at: Date
        /// The class it belongs to: it feeds the beliefs about that class (and about him).
        public var classID: UUID
        /// The verb for the words: "train", "cook".
        public var verb: String

        public init(id: UUID, at: Date, classID: UUID, verb: String) {
            self.id = id
            self.at = at
            self.classID = classID
            self.verb = verb
        }
    }

    /// One thing that happened on the day. The caller passes shown names only: a private thing arrives as its label
    /// ("Private workout"), and a kind whose title may be his own words (a note) arrives with an empty name, so it is
    /// counted and never named. The planner writes `name` into the summary as it is and does not check it again.
    public struct DayItem: Sendable, Equatable {
        /// The class word, singular: "workout", "task done", "spend".
        public var kind: String
        public var name: String
        public var at: Date
        /// The agent room it belongs to (`AgentSpec.room`): "training", "today".
        public var room: String

        public init(kind: String, name: String, at: Date, room: String) {
            self.kind = kind
            self.name = name
            self.at = at
            self.room = room
        }
    }

    public struct NotebookFile: Sendable, Equatable {
        public var path: String
        public var bytes: Int
        public var lastUsed: Date

        public init(path: String, bytes: Int, lastUsed: Date) {
            self.path = path
            self.bytes = bytes
            self.lastUsed = lastUsed
        }

        /// "/memories/training" for "/memories/training/bench.md".
        var folder: String {
            path.split(separator: "/").prefix(2).map(String.init).reduce("") { $0 + "/" + $1 }
        }
    }

    public enum Step: Sendable, Equatable {
        case merge(keep: UUID, close: UUID)
        case revise(belief: UUID, words: String, value: String, evidence: [UUID])
        case confirm(belief: UUID)
        case summary(path: String, text: String)
        case prune(path: String)
        case refresh(AgentSpec.Expertise)
        case reflect(agent: String)
    }

    public static let offPatternMinutes = 90.0
    public static let notebookLimit = 32000
    /// The most inferred beliefs one reflect call may propose.
    public static let reflectLimit = 5
    /// Keys that hold one value at a time, so two open beliefs that disagree are a contradiction.
    static let singleValued: Set<TessBelief.Key> = [.usualTime, .cadence]
    /// Day-item kinds only lab may summarize (money, body, calendar): under strict they stay out of the summary
    /// lines and wake no agent, like the rooms of the lab-only agents.
    public static let labOnlyKinds: Set<String> = [
        "spend", "money in", "pool move", "sleep", "steps", "resting heart rate", "weigh-in", "event",
    ]
    static let labOnlyRooms: Set<String> = Set(AgentSpec.shipped.filter(\.labOnly).map(\.room))

    /// What he told her or kept: the night never closes or revises it.
    static func isHis(_ belief: TessBelief) -> Bool {
        belief.kept || belief.source == .told
    }

    public var calendar: Calendar
    public var now: Date

    public init(calendar: Calendar = .current, now: Date = .now) {
        self.calendar = calendar
        self.now = now
    }

    // MARK: The night

    /// The day that closed at the last 4 am turnover.
    public var closingDay: Date {
        let today = calendar.startOfDay(for: now.addingTimeInterval(-4 * 3600))
        return calendar.date(byAdding: .day, value: -1, to: today) ?? today
    }

    /// The night's name, "2026-10-23": a run records it, and a second run with the same name plans nothing.
    public var night: String {
        MemoryEval.stamp(closingDay, calendar: calendar)
    }

    /// When the closing day began: 4 am.
    var dayStart: Date {
        calendar.date(byAdding: .hour, value: 4, to: closingDay) ?? closingDay
    }

    /// - Parameters:
    ///   - packs: each pack's hash now, and the hash its cache was built with (nil when never built).
    ///   - agents: the agents the policy allows (`AgentSpec.available(under:)`).
    ///   - policy: the Door's policy. Strict drops the lab-only kinds from the summaries and the reflect rooms.
    public func plan(beliefs: [TessBelief], series: [Event], day allDay: [DayItem], week allWeek: [DayItem] = [],
                     notebooks: [NotebookFile] = [], packs: [AgentSpec.Expertise: (now: String, built: String?)] = [:],
                     agents: [AgentSpec] = [], lastNight: String? = nil, policy: DoorPolicy = .strict) -> [Step]
    {
        guard lastNight != night else { return [] }
        let day = Self.allowed(allDay, under: policy)
        let week = Self.allowed(allWeek, under: policy)
        let open = beliefs.filter(\.isOpen)
        let merges = merged(open)
        let closing = Set(merges.compactMap { step -> UUID? in
            if case let .merge(_, close) = step { return close }
            return nil
        })
        var steps = merges
        for belief in open where !closing.contains(belief.id) {
            if let step = usualTime(belief, series: series) {
                steps.append(step)
            }
        }
        steps += summaries(day: day, week: week)
        steps += pruned(notebooks)
        let moved: [AgentSpec.Expertise] = packs.compactMap { entry in
            entry.value.now == entry.value.built ? nil : entry.key
        }
        steps += moved.sorted { $0.rawValue < $1.rawValue }.map { Step.refresh($0) }
        let rooms = Set(day.map(\.room))
        let active: [AgentSpec] = agents.filter { rooms.contains($0.room) || ($0.room == "tess" && !rooms.isEmpty) }
        steps += active.map { Step.reflect(agent: $0.name) }
        return steps
    }

    // MARK: Merge

    func merged(_ open: [TessBelief]) -> [Step] {
        let groups = Dictionary(grouping: open) { belief in
            let value = Self.singleValued.contains(belief.key) ? "" : normalized(belief.value)
            return "\(subjectKey(belief.subject))|\(belief.key.rawValue)|\(value)"
        }
        var steps: [Step] = []
        for key in groups.keys.sorted() {
            guard let group = groups[key], group.count > 1 else { continue }
            let ranked = group.sorted { lhs, rhs in
                if lhs.kept != rhs.kept { return lhs.kept }
                if (lhs.source == .told) != (rhs.source == .told) { return lhs.source == .told }
                if normalized(lhs.value) != normalized(rhs.value) {
                    // A disagreement: the newer belief is the newer information.
                    return lhs.validFrom > rhs.validFrom
                }
                if lhs.confirmations != rhs.confirmations { return lhs.confirmations > rhs.confirmations }
                return lhs.validFrom < rhs.validFrom
            }
            // Two of his own that disagree: nothing in the group closes until he says which.
            let his: Set<String> = Set(group.filter(Self.isHis).map { normalized($0.value) })
            guard his.count < 2 else { continue }
            for other in ranked.dropFirst() where !Self.isHis(other) {
                steps.append(.merge(keep: ranked[0].id, close: other.id))
            }
        }
        return steps
    }

    /// The items a policy may summarize: lab all of them, strict none of money, body or calendar.
    static func allowed(_ items: [DayItem], under policy: DoorPolicy) -> [DayItem] {
        guard policy == .strict else { return items }
        return items.filter { !labOnlyKinds.contains($0.kind) && !labOnlyRooms.contains($0.room) }
    }

    func subjectKey(_ subject: TessBelief.Subject) -> String {
        switch subject {
        case .you: "you"
        case let .classDef(id): "class:\(id.uuidString)"
        case let .object(id): "object:\(id.uuidString)"
        }
    }

    func normalized(_ value: String) -> String {
        guard let data = value.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data),
              let sorted = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let text = String(data: sorted, encoding: .utf8)
        else { return value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        return text.lowercased()
    }

    // MARK: Usual times

    /// The hour a usual-time value holds: `{"hour": 18}` or `{"hour": 18.5}`.
    static func hour(of value: String) -> Double? {
        guard let data = value.data(using: .utf8),
              let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        return (object["hour"] as? NSNumber)?.doubleValue
    }

    func minutes(_ date: Date) -> Double {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return Double((parts.hour ?? 0) * 60 + (parts.minute ?? 0))
    }

    /// Minutes between two times of day, the short way round midnight.
    static func gap(_ one: Double, _ other: Double) -> Double {
        let raw = abs(one - other).truncatingRemainder(dividingBy: 1440)
        return min(raw, 1440 - raw)
    }

    func usualTime(_ belief: TessBelief, series: [Event]) -> Step? {
        guard belief.key == .usualTime, belief.source != .told, !belief.kept,
              let hour = Self.hour(of: belief.value) else { return nil }
        // A usual time is checked against the class it is about. One about him with no class (from a memory line)
        // can't be told apart from cooks and errands, so no rule touches it.
        let events = series.filter { event in
            switch belief.subject {
            case let .classDef(id): event.classID == id
            case .you, .object: false
            }
        }
        .filter { $0.at > belief.validFrom && $0.at < now }
        .sorted { $0.at < $1.at }
        .suffix(4)
        guard events.count == 4 else { return nil }
        let off = events.filter { Self.gap(minutes($0.at), hour * 60) > Self.offPatternMinutes }
        if off.count >= 3 {
            let times = off.map { minutes($0.at) }.sorted()
            let median = times.count % 2 == 1 ? times[times.count / 2]
                : (times[times.count / 2 - 1] + times[times.count / 2]) / 2
            let newHour = ((median / 30).rounded() / 2).truncatingRemainder(dividingBy: 24)
            let verb = off.last?.verb ?? "do this"
            return .revise(belief: belief.id, words: "You usually \(verb) around \(Self.clock(newHour)).",
                           value: "{\"hour\":\(MemoryEval.plain(newHour))}", evidence: off.map(\.id))
        }
        let unproven = belief.source == .noticed || belief.source == .inferred
        if events.count - off.count >= 3, unproven, belief.confirmations < TessBelief.confirmationsForFact,
           let newest = events.last, newest.at >= dayStart
        {
            return .confirm(belief: belief.id)
        }
        return nil
    }

    /// "6 pm", "6:30 am", "noon".
    static func clock(_ hour: Double) -> String {
        let whole = Int(hour) % 24
        let half = hour - Double(Int(hour)) >= 0.5
        if whole == 12, !half {
            return "noon"
        }
        let shown = whole % 12 == 0 ? 12 : whole % 12
        return "\(shown)\(half ? ":30" : "") \(whole < 12 ? "am" : "pm")"
    }

    // MARK: Summaries

    func summaries(day: [DayItem], week: [DayItem]) -> [Step] {
        var steps = [Step.summary(path: "/summaries/day/\(night)", text: Self.lines(day, empty: "A quiet day."))]
        if calendar.component(.weekday, from: closingDay) == 1 {
            var iso = Calendar(identifier: .iso8601)
            iso.timeZone = calendar.timeZone
            let parts = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: closingDay)
            let name = String(format: "%04d-W%02d", parts.yearForWeekOfYear ?? 0, parts.weekOfYear ?? 0)
            steps.append(.summary(path: "/summaries/week/\(name)", text: Self.lines(week, empty: "A quiet week.")))
        }
        return steps
    }

    /// One line per kind, most first: "3 workouts: Push Day, Leg Day, Private workout". At most 3 names, by time; a
    /// kind whose items carry no name is a count alone ("2 notes").
    static func lines(_ items: [DayItem], empty: String) -> String {
        guard !items.isEmpty else { return empty }
        let kinds: [String: [DayItem]] = Dictionary(grouping: items, by: \.kind)
        let ranked: [(kind: String, items: [DayItem])] = kinds.map { (kind: $0.key, items: $0.value) }
            .sorted { lhs, rhs in
                lhs.items.count != rhs.items.count ? lhs.items.count > rhs.items.count : lhs.kind < rhs.kind
            }
        var out: [String] = []
        for group in ranked {
            let names: [String] = group.items.sorted { $0.at < $1.at }.map(\.name)
            var unique: [String] = []
            for name in names where !name.isEmpty && !unique.contains(name) {
                unique.append(name)
            }
            let count = group.items.count == 1 ? "1 \(group.kind)" : "\(group.items.count) \(plural(group.kind))"
            out.append(unique.isEmpty ? count : "\(count): \(unique.prefix(3).joined(separator: ", "))")
        }
        return out.joined(separator: "\n")
    }

    /// "workout" to "workouts", "task done" to "tasks done".
    static func plural(_ kind: String) -> String {
        var words = kind.split(separator: " ").map(String.init)
        guard let first = words.first else { return kind }
        words[0] = first.hasSuffix("s") ? first : first + "s"
        return words.joined(separator: " ")
    }

    // MARK: Notebooks

    func pruned(_ files: [NotebookFile]) -> [Step] {
        var steps: [Step] = []
        for (_, folder) in Dictionary(grouping: files, by: \.folder).sorted(by: { $0.key < $1.key }) {
            var total = folder.reduce(0) { $0 + $1.bytes }
            let oldestFirst = folder.sorted {
                $0.lastUsed != $1.lastUsed ? $0.lastUsed < $1.lastUsed : $0.path < $1.path
            }
            for file in oldestFirst where total > Self.notebookLimit {
                steps.append(.prune(path: file.path))
                total -= file.bytes
            }
        }
        return steps
    }
}
