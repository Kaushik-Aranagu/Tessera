import Foundation

/// One short line Tess knows about him (docs/ai/architecture.md section 4; Design 49). Stored as an object so it
/// follows
/// every rule objects follow: op log, undo, backup. Never a health value, a weight, money, a merchant, a place or a
/// note's words: `TessMemoryScreen` refuses those before anything is written.
public struct TessMemory: Identifiable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        /// He said to remember it; kept until he deletes it. His words.
        case told
        /// A pattern counted on the phone from the ledger, never by Claude; recomputed weekly, replaced not piled up.
        case noticed
        /// One line per day from the Day log, counts only; 14 days, then folded into a week line kept 8 weeks.
        case recent
    }

    /// The group word on the What Tess knows page.
    public enum Area: String, Codable, Sendable, CaseIterable {
        case training, kitchen, people, days, other

        public var word: String {
            switch self {
            case .training: "Training"
            case .kitchen: "Kitchen"
            case .people: "People"
            case .days: "The last 14 days"
            case .other: "Other"
            }
        }
    }

    public static let maxTextLength = 80
    /// At most this many told lines; at the cap the oldest one not used in 90 days drops at the 04:00 turnover.
    public static let toldCap = 40
    public static let unusedDropAfter: TimeInterval = 90 * 86400
    public static let recentDays = 14
    public static let weekLinesKept = 8

    public let id: UUID
    public let kind: Kind
    public let area: Area
    public let text: String
    /// The objects behind it (the workouts counted, the capture that said it).
    public let evidence: [UUID]
    public let createdAt: Date
    public let lastUsedAt: Date?
    public let pinned: Bool
    /// Never leaves the phone, in any pack ("stays on this phone").
    public let isPrivate: Bool
    /// For a recent line: the day it tells, or the week's Monday.
    public let day: Date?

    /// The source line under it: "you said so on Oct 9, used today", "from 14 workouts", "from 6 weeks".
    public func sourceLine(now: Date, calendar: Calendar = .current) -> String {
        var line: String = switch kind {
        case .told: "you said so \(Self.when(createdAt, now: now, calendar: calendar))"
        case .noticed: evidence.isEmpty ? "noticed" : "from \(evidence.count) \(Self.evidenceWord(area, evidence.count))"
        case .recent: "from the day log"
        }
        if let lastUsedAt, kind != .recent {
            line += ", used \(Self.when(lastUsedAt, now: now, calendar: calendar))"
        }
        if isPrivate {
            line += ", stays on this phone"
        }
        return line
    }

    static func evidenceWord(_ area: Area, _ count: Int) -> String {
        let word = switch area {
        case .training: "workout"
        case .kitchen: "cook"
        default: "thing"
        }
        return count == 1 ? word : word + "s"
    }

    /// "today", "yesterday", "on Oct 9".
    static func when(_ date: Date, now: Date, calendar: Calendar) -> String {
        let day = TesseraDay(calendar: calendar)
        if day.isSameDay(date, now) {
            return "today"
        }
        if day.isSameDay(date, day.adding(days: -1, to: now)) {
            return "yesterday"
        }
        return "on " + date.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "en_US")))
    }
}

/// What memory never holds (architecture section 4): health values, money, merchants, note bodies, the key, and any
/// number the evidence does not account for. One screen, run before every write.
public enum TessMemoryScreen {
    public static let healthWords: Set<String> = ["sleep", "slept", "sleepy", "tired", "exhausted", "fatigue", "energy",
                                                  "rested", "recovery", "recover", "heart", "hrv", "steps", "sore",
                                                  "sick", "unwell", "drained", "burnout", "weigh", "weighed", "weight",
                                                  "kg", "lb", "lbs", "bpm", "calories", "kcal", "bmi", "blood"]
    public static let moneyWords: Set<String> = ["$", "£", "€", "dollar", "dollars", "bucks", "paid", "spent", "cost",
                                                 "price", "rent", "salary", "card", "bank", "venmo", "paypal", "amazon",
                                                 "costco", "walmart", "target", "trader", "whole foods"]

    public enum Refusal: Equatable, Sendable {
        case empty, tooLong, health(String), money(String), unlicensedNumber(Int), looksLikeKey
    }

    /// Nil when the line may be kept. `numbers` are the digits the evidence licenses (a noticed line's counts).
    public static func refusal(for text: String, numbers: Set<Int> = []) -> Refusal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        guard trimmed.count <= TessMemory.maxTextLength else { return .tooLong }
        if trimmed.contains("sk-ant-") {
            return .looksLikeKey
        }
        let lower = trimmed.lowercased()
        let tokens = lower.split { !$0.isLetter && $0 != "$" && $0 != "£" && $0 != "€" }.map(String.init)
        if let word = tokens.first(where: healthWords.contains) {
            return .health(word)
        }
        if let word = tokens.first(where: moneyWords.contains)
            ?? moneyWords.first(where: { $0.contains(" ") && lower.contains($0) })
            ?? ["$", "£", "€"].first(where: lower.contains)
        {
            return .money(word)
        }
        for match in trimmed.matches(of: /\d+/) {
            if let number = Int(match.output), !numbers.contains(number) {
                return .unlicensedNumber(number)
            }
        }
        return nil
    }
}

/// Tess remembers: he says so (`RememberFact`), as a pending ghost like any capture.
public struct RememberFact: EngineAction {
    public static let descriptor = ActionDescriptor(name: "rememberFact", summary: "Keep a line about him",
                                                    parameters: [
                                                        .init("text", .string, "The line, his words, 80 characters"),
                                                        .init("area", .string, "training, kitchen, people or other",
                                                              required: false),
                                                        .init("evidence", .json, "Object ids behind it",
                                                              required: false),
                                                        .init("isPrivate", .boolean, "Never leaves the phone",
                                                              required: false),
                                                    ])

    public var text: String
    public var area: TessMemory.Area?
    public var evidence: [UUID]
    public var isPrivate: Bool?

    public init(text: String, area: TessMemory.Area? = nil, evidence: [UUID] = [], isPrivate: Bool? = nil) {
        self.text = text
        self.area = area
        self.evidence = evidence
        self.isPrivate = isPrivate
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // His own body facts are kept but private; health values and money are refused outright.
        let bodyWords = ["shoulder", "knee", "back", "hip", "elbow", "wrist", "ankle", "neck"]
        // His own words license their own numbers ("mom's birthday is the 9th"); health and money are still refused.
        let refusal = TessMemoryScreen.refusal(for: trimmed, numbers: Set(HomeLines.digits(in: trimmed)))
        if let refusal, case .health = refusal, bodyWords.contains(where: { trimmed.lowercased().contains($0) }) {
            // "my left shoulder gets sore on overhead pressing": his words, marked private.
        } else if let refusal {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: \(refusal)")
        }
        let area = area ?? TessMemoryStore.guessArea(trimmed)
        let bodyFact = bodyWords.contains { trimmed.lowercased().contains($0) }
        let memory = try transaction.create(transaction.classDef(.tessMemory), title: trimmed)
        try transaction.set("kind", to: .choice(TessMemory.Kind.told.rawValue), on: memory)
        try transaction.set("area", to: .choice(area.rawValue), on: memory)
        try transaction.set("isPrivate", to: .bool(isPrivate ?? bodyFact), on: memory)
        let objects = evidence.compactMap { transaction.store.object(id: $0) }
        if !objects.isEmpty {
            try transaction.setLinks("evidence", on: memory, to: objects)
        }
        return memory
    }

    public func summary(in _: ObjectStore) -> String {
        "Kept. \(TessMemoryStore.secondPerson(text))"
    }
}

/// Forgets one line: the object goes, and after the UNDO window `TessMemoryStore.redact` scrubs its words from history.
public struct ForgetMemory: EngineAction {
    public static let descriptor = ActionDescriptor(name: "forgetMemory", summary: "Forget one thing Tess knows",
                                                    parameters: [.init("memory", .object, "The line")])

    public var memory: UUID

    public init(memory: UUID) {
        self.memory = memory
    }

    public func apply(_ transaction: inout Transaction) throws {
        try transaction.delete(transaction.object(memory, is: .tessMemory))
    }

    public func summary(in store: ObjectStore) -> String {
        "\(store.object(id: memory).map { TessMemoryStore.thing(of: $0.title) } ?? "That"), forgotten."
    }
}

/// Forgets everything, one op, one UNDO: "Everything forgotten, 12 things."
public struct ForgetAllMemory: EngineAction {
    public static let descriptor = ActionDescriptor(name: "forgetAllMemory", summary: "Forget everything Tess knows",
                                                    parameters: [])

    public init() {}

    public func apply(_ transaction: inout Transaction) throws -> Int {
        let memories = TessMemoryStore.records(store: transaction.store, classes: transaction.classes)
        for memory in memories {
            transaction.delete(memory)
        }
        return memories.count
    }

    public func summary(in _: ObjectStore) -> String {
        "Everything forgotten."
    }
}

/// Reads, packs and keeps the memory: the page's groups, the pack's block, the 04:00 turnover.
@MainActor
public struct TessMemoryStore {
    public let engine: ActionEngine
    public var calendar: Calendar

    public init(engine: ActionEngine, calendar: Calendar = .current) {
        self.engine = engine
        self.calendar = calendar
    }

    var store: ObjectStore {
        engine.store
    }

    static func records(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> [ObjectRecord] {
        guard let memoryClass = classes[.tessMemory] else { return [] }
        return store.objects(of: memoryClass).filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    func read(_ object: ObjectRecord) -> TessMemory {
        TessMemory(id: object.id,
                   kind: store.value("kind", of: object)?.stringValue.flatMap(TessMemory.Kind.init) ?? .told,
                   area: store.value("area", of: object)?.stringValue.flatMap(TessMemory.Area.init) ?? .other,
                   text: object.title, evidence: store.linkedObjects("evidence", of: object).map(\.id),
                   createdAt: object.createdAt, lastUsedAt: store.value("lastUsedAt", of: object)?.dateValue,
                   pinned: store.value("pinned", of: object) == .bool(true),
                   isPrivate: store.value("isPrivate", of: object) == .bool(true),
                   day: store.value("day", of: object)?.dateValue)
    }

    /// Everything, oldest first.
    public func all() -> [TessMemory] {
        Self.records(store: store, classes: engine.classes).map(read)
    }

    public func lines(of kind: TessMemory.Kind) -> [TessMemory] {
        all().filter { $0.kind == kind }
    }

    /// The page's groups, in Design 49's order: Training, Kitchen, People, Other, then The last 14 days. A group
    /// exists only when it has a line; told and noticed lines newest first, recent lines by day, newest first.
    public func grouped() -> [(area: TessMemory.Area, lines: [TessMemory])] {
        let all = all()
        var groups: [(TessMemory.Area, [TessMemory])] = []
        for area in [TessMemory.Area.training, .kitchen, .people, .other] {
            let lines = all.filter { $0.kind != .recent && $0.area == area }.sorted { $0.createdAt > $1.createdAt }
            if !lines.isEmpty {
                groups.append((area, lines))
            }
        }
        let recent = all.filter { $0.kind == .recent }.sorted { ($0.day ?? $0.createdAt) > ($1.day ?? $1.createdAt) }
        if !recent.isEmpty {
            groups.append((.days, recent))
        }
        return groups
    }

    /// "12 things. 4 you told me, 8 I noticed." Recent day lines aren't counted; they're the day log's.
    public func countLine() -> String {
        let told = lines(of: .told).count, noticed = lines(of: .noticed).count
        let total = told + noticed
        guard total > 0 else { return "Nothing yet." }
        return "\(total) \(total == 1 ? "thing" : "things"). \(told) you told me, \(noticed) I noticed."
    }

    /// Settings' value word: "12 things", or "Nothing yet".
    public func countWord() -> String {
        let total = lines(of: .told).count + lines(of: .noticed).count
        return total == 0 ? "Nothing yet" : "\(total) \(total == 1 ? "thing" : "things")"
    }

    // MARK: The pack

    /// Which kinds a job reads (architecture section 6).
    public struct Reads: Sendable {
        public var told = false, noticed = false, recent = false
        /// Noticed lines are kept to this area when set.
        public var area: TessMemory.Area?

        public init(told: Bool = false, noticed: Bool = false, recent: Bool = false, area: TessMemory.Area? = nil) {
            self.told = told
            self.noticed = noticed
            self.recent = recent
            self.area = area
        }
    }

    /// About 1,200 tokens at most (characters over 4).
    public static let packBudget = 1200 * 4

    /// The memory block for a pack: told lines first (never private ones), then up to 10 noticed lines for the job's
    /// area, then the last 7 recent lines, trimmed to the budget. Nothing private ever leaves here.
    public func pack(_ reads: Reads, now _: Date = .now) -> [TessMemory] {
        var chosen: [TessMemory] = []
        let all = all().filter { !$0.isPrivate }
        if reads.told {
            chosen += all.filter { $0.kind == .told }
                .sorted { ($0.lastUsedAt ?? $0.createdAt) > ($1.lastUsedAt ?? $1.createdAt) }
        }
        if reads.noticed {
            chosen += all.filter { memory in
                memory.kind == .noticed && (reads.area.map { $0 == memory.area } ?? true)
            }.prefix(10)
        }
        if reads.recent {
            chosen += all.filter { $0.kind == .recent }.sorted { ($0.day ?? $0.createdAt) > ($1.day ?? $1.createdAt) }
                .prefix(7)
        }
        var used = 0
        return chosen.filter { memory in
            used += memory.text.count + 1
            return used <= Self.packBudget
        }
    }

    /// Marks lines as used by a job, so the source line can say "used today" and the cap keeps the live ones.
    public func markUsed(_ ids: [UUID], at now: Date = .now) {
        for id in ids {
            guard let object = store.object(id: id) else { continue }
            try? store.set("lastUsedAt", to: .date(now), on: object)
        }
    }

    // MARK: Forgetting

    /// After the 10 s UNDO window: scrubs the line's words from every op that carried them, so history can't bring
    /// them back, and blanks the object itself. Idempotent.
    public func redact(_ id: UUID) {
        guard let object = store.object(id: id) else { return }
        let words = object.title
        guard !words.isEmpty else { return }
        for record in store.context.operations.values where record.objectIDs.contains(id) {
            var changed = false
            let ops = record.ops.map { op -> Op in
                switch op {
                case let .create(target, classID, parent, title) where target == id && title == words:
                    changed = true
                    return .create(object: target, classID: classID, parent: parent, title: Self.redacted)
                case let .setTitle(target, old, new) where target == id:
                    changed = true
                    return .setTitle(object: target, old: old == words ? Self.redacted : old,
                                     new: new == words ? Self.redacted : new)
                default:
                    return op
                }
            }
            if changed {
                record.opsData = try? JSONEncoder().encode(ops)
            }
            // The receipt said it in the second person ("Kept. You train after work."); scrub that form too.
            for form in [words, String(Self.secondPerson(words).dropLast()), Self.thing(of: words)]
                where !form.isEmpty && record.summary.contains(form)
            {
                record.summary = record.summary.replacingOccurrences(of: form, with: Self.redacted)
            }
        }
        object.title = Self.redacted
        if !object.isDeleted {
            store.softDelete(object)
        }
    }

    public static let redacted = "[forgotten]"

    // MARK: Writes without ops (counted lines are weather, not something he did)

    @discardableResult
    func write(kind: TessMemory.Kind, area: TessMemory.Area, text: String, evidence: [UUID], day: Date?,
               numbers: Set<Int> = []) -> ObjectRecord?
    {
        guard let memoryClass = engine.classes[.tessMemory],
              TessMemoryScreen.refusal(for: text, numbers: numbers.union(HomeLines.digits(in: day == nil ? nil : text)))
              == nil else { return nil }
        let object = store.create(memoryClass, title: text)
        try? store.set("kind", to: .choice(kind.rawValue), on: object)
        try? store.set("area", to: .choice(area.rawValue), on: object)
        try? store.set("isPrivate", to: .bool(false), on: object)
        if let day {
            try? store.set("day", to: .date(day), on: object)
        }
        let objects = evidence.compactMap { store.object(id: $0) }
        if !objects.isEmpty {
            try? store.setLinks("evidence", on: object, to: objects)
        }
        return object
    }

    func remove(_ id: UUID) {
        guard let object = store.object(id: id), !object.isDeleted else { return }
        store.softDelete(object)
    }

    // MARK: Words

    /// Where a told line belongs, from its words.
    static func guessArea(_ text: String) -> TessMemory.Area {
        let lower = text.lowercased()
        if ["train", "workout", "gym", "lift", "bench", "squat", "deadlift", "press", "rest day", "routine", "set"]
            .contains(where: lower.contains)
        {
            return .training
        }
        if ["cook", "recipe", "grocer", "eat", "dinner", "lunch", "breakfast", "kitchen", "meal", "buy"]
            .contains(where: lower.contains)
        {
            return .kitchen
        }
        if ["mom", "dad", "wife", "brother", "sister", "friend", "means", "birthday", "call"]
            .contains(where: lower.contains)
        {
            return .people
        }
        return .other
    }

    /// "I train after work" → "You train after work." for Tess's lines and the page.
    static func secondPerson(_ text: String) -> String {
        var words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let swaps: [(String, String)] = [("I'm ", "You're "), ("I am ", "You are "), ("I ", "You "), ("my ", "your "),
                                         ("My ", "Your "), ("me ", "you "), (" I'm ", " you're "), (" I ", " you "),
                                         (" my ", " your "), (" me ", " you "), (" me.", " you.")]
        for (from, to) in swaps where words.hasPrefix(from) || from.hasPrefix(" ") {
            words = words.hasPrefix(from) ? to + words.dropFirst(from.count) : words.replacingOccurrences(
                of: from,
                with: to
            )
        }
        words = words.prefix(1).uppercased() + words.dropFirst()
        return words.hasSuffix(".") ? words : words + "."
    }

    /// The thing a line is about, for "Left shoulder, forgotten.": its first few words.
    static func thing(of text: String) -> String {
        let words = text.trimmingCharacters(in: CharacterSet(charactersIn: ". ")).split(separator: " ")
        let head = words.prefix(3).joined(separator: " ")
        return head.prefix(1).uppercased() + head.dropFirst()
    }
}
