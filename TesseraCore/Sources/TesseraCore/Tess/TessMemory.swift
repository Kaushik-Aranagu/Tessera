import CryptoKit
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
        /// The hash of a line he forgot, so a restored backup can't bring it back. Never shown, never packed.
        case forgotten
    }

    /// The group word on the What Tess knows page.
    public enum Area: String, Codable, Sendable, CaseIterable {
        case training, kitchen, people, days, about

        public var word: String {
            switch self {
            case .training: "Training"
            case .kitchen: "Kitchen"
            case .people: "People"
            case .days: "The last 14 days"
            case .about: "About you"
            }
        }
    }

    public static let maxTextLength = 80
    /// At most this many told lines; at the cap nothing is written and Tess says so (Design 49 addendum S7).
    public static let toldCap = 40
    public static let capLine = "I keep 40 things. Forget one and say it again."
    /// Day lines stop at 14 days; the week is computed live by WeekFacts, never stored (AI thread S1).
    public static let recentDays = 14

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
        case .recent, .forgotten: "from the day log"
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
        // His day, not the wall date: a cook at 12:30 am Oct 17 was on his Oct 16 (TW26).
        var style = Date.FormatStyle.dateTime.month(.abbreviated).day().locale(Locale(identifier: "en_US"))
        style.timeZone = calendar.timeZone
        return "on " + day.day(of: date).formatted(style)
    }
}

/// What memory never holds (architecture section 4): health values, money, merchants, note bodies, the key, and any
/// number the evidence does not account for. One screen, run before every write.
public enum TessMemoryScreen {
    /// Health words. A told line with one is kept private (addendum S6); a measured value is refused outright.
    public static let healthWords: Set<String> = ["sleep", "slept", "sleepy", "tired", "exhausted", "fatigue", "energy",
                                                  "rested", "recovery", "recover", "heart", "hrv", "sore", "sick",
                                                  "unwell", "drained", "burnout", "hurts", "hurt", "ache", "aches",
                                                  "pain", "tight", "weigh", "weighed", "weight", "kg", "lb", "lbs",
                                                  "bpm", "calories", "kcal", "bmi", "blood"]
    /// Measured health: never stored, private or not (QA F3 on #356).
    public static let healthValueWords: Set<String> = ["weigh", "weighed", "weight", "kg", "lb", "lbs", "bpm",
                                                       "calories", "kcal", "bmi", "blood", "hrv"]
    public static let moneyWords: Set<String> = ["$", "£", "€", "dollar", "dollars", "bucks", "paid", "spent", "cost",
                                                 "price", "rent", "salary", "venmo", "paypal", "invoice", "refund"]

    /// Places and shops are refused ("I don't keep places."): a shop is somewhere he goes.
    public static let placeWords: Set<String> = ["street", "avenue", "road", "boulevard", "address", "apartment", "apt",
                                                 "suite", "zip", "lives at", "live at", "located", "costco", "walmart",
                                                 "trader", "whole foods", "amazon", "ikea", "safeway", "kroger"]

    public enum Refusal: Equatable, Sendable {
        case empty, tooLong, health(String), money(String), place(String), unlicensedNumber(Int), looksLikeKey, capFull
        /// A password, PIN or code: "I don't keep passwords." (Research 134 SW3).
        case secret

        /// Tess's line when she won't keep it (Design 49 addendum S6, S7); nil for a shape problem.
        public var line: String? {
            switch self {
            case .money: "I don't keep sums of money."
            case .place: "I don't keep places."
            case .secret: "I don't keep passwords."
            case .capFull: TessMemory.capLine
            default: nil
            }
        }
    }

    /// Nil when the line may be kept. `numbers` are the digits the evidence licenses (a noticed line's counts).
    public static func refusal(for text: String, numbers: Set<Int> = []) -> Refusal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        guard trimmed.count <= TessMemory.maxTextLength else { return .tooLong }
        if trimmed.contains("sk-ant-") {
            return .looksLikeKey
        }
        if SecretWords.mentions(trimmed) {
            return .secret
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
        if let word = tokens.first(where: placeWords.contains) ?? placeWords
            .first(where: { $0.contains(" ") && lower.contains($0) })
        {
            return .place(word)
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
        // Only lines that could leave the phone are screened for health and money (Research F3): a private line, his
        // own body fact ("left shoulder") or one he marks private, is kept as said. His own words license their own
        // numbers. Length and the key are checked on every line.
        // Whole words only ("back from work" is not his back; QA F3).
        let words = Set(trimmed.lowercased().split { !$0.isLetter }.map(String.init))
        let bodyWords: Set = ["shoulder", "shoulders", "knee", "knees", "back", "hip", "hips", "elbow", "wrist",
                              "ankle", "neck"]
        let soreWords: Set = ["sore", "hurts", "hurt", "ache", "aches", "pain", "tight"]
        // A body word alone makes it private (QA F5; "back" still needs a sore word, "back from work" is not his back).
        let bodyFact = !words.isDisjoint(with: bodyWords.subtracting(["back"]))
            || (words.contains("back") && !words.isDisjoint(with: soreWords))
        var keepsPrivate = isPrivate ?? bodyFact
        // A measured value (a weight, a unit, a pulse) is never kept, private or not.
        // A measured value: a unit or weigh word, or a health word next to a number ("resting heart rate is 52"; S8).
        // "resting heart rate is 52" is measured; "my knee hurts after 3 sets" is not: the number has to sit within
        // three words of the health word (QA low on #356).
        let tokens = trimmed.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        // A feeling ("hurts", "sore", "tired") is never a measurement, whatever number sits near it.
        let feelings: Set = ["sore", "hurts", "hurt", "ache", "aches", "pain", "tight", "tired", "sleepy",
                             "exhausted", "drained", "sick", "unwell", "rested"]
        let measured = tokens.indices.contains { index in
            TessMemoryScreen.healthWords.contains(tokens[index]) && !feelings.contains(tokens[index])
                && tokens[max(0, index - 3) ... min(tokens.count - 1, index + 3)].contains { $0.allSatisfy(\.isNumber) }
        }
        if let value = words.first(where: TessMemoryScreen.healthValueWords.contains)
            ?? (measured ? words.first(where: TessMemoryScreen.healthWords.contains) : nil)
        {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: health(\"\(value)\")")
        }
        if let refusal = TessMemoryScreen.refusal(for: trimmed, numbers: Set(HomeLines.digits(in: trimmed))) {
            switch refusal {
            // A health word keeps the line private (addendum S6); money and places are refused outright.
            case .health: keepsPrivate = true
            case .unlicensedNumber: break
            default: throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: \(refusal)")
            }
        }
        // The engine wall (board 0ai): his weight is never kept, whoever asked, even as a bare number ("82.4"). Money
        // was refused by the screen above with its own line; a health line he tells stays private (Research F3).
        if PrivateFacts.isBareWeight(trimmed.lowercased(), lastWeightKg: BodyWeight.lastKg(in: transaction.store)) {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "refused: health(\"walled\")")
        }
        // At the cap nothing is written (addendum S7).
        let told = TessMemoryStore.records(store: transaction.store, classes: transaction.classes)
            .count { transaction.store.value("kind", of: $0) == .choice(TessMemory.Kind.told.rawValue) }
        guard told < TessMemory.toldCap else {
            throw ActionError.invalidArguments(action: Self.descriptor.name,
                                               reason: "refused: \(TessMemoryScreen.Refusal.capFull)")
        }
        let area = area ?? TessMemoryStore.guessArea(trimmed)
        // Stored in the second person, as the page and the pack read it (AI thread S4). Saying a forgotten line again
        // is his consent to keep it: its quiet hash object goes (QA F6), and the file's entry is older than this line.
        let stored = TessMemoryStore.secondPerson(trimmed)
        let hash = TessMemoryStore.hash(stored)
        for entry in try transaction.store.objects(of: transaction.classDef(.tessMemory))
            where transaction.store.value("kind", of: entry) == .choice(TessMemory.Kind.forgotten.rawValue)
            && entry.title == hash
        {
            transaction.delete(entry)
        }
        let memory = try transaction.create(transaction.classDef(.tessMemory), title: stored)
        try transaction.set("kind", to: .choice(TessMemory.Kind.told.rawValue), on: memory)
        try transaction.set("area", to: .choice(area.rawValue), on: memory)
        try transaction.set("isPrivate", to: .bool(keepsPrivate), on: memory)
        let objects = evidence.compactMap { transaction.store.object(id: $0) }
        if !objects.isEmpty {
            try transaction.setLinks("evidence", on: memory, to: objects)
        }
        return memory
    }

    public func summary(in _: ObjectStore) -> String {
        // A private line (a health word, or marked so) says where it stays (arch #357).
        let words = Set(text.lowercased().split { !$0.isLetter }.map(String.init))
        if isPrivate == true || !words.isDisjoint(with: TessMemoryScreen.healthWords) {
            return "Kept, on this phone only."
        }
        return "Kept. \(TessMemoryStore.secondPerson(text))"
    }

    /// Tess's line for a refusal, from the error the engine threw; nil when it wasn't one of hers.
    public static func refusalLine(_ error: any Error) -> String? {
        guard case let ActionError.invalidArguments(_, reason) = error,
              reason.hasPrefix("refused: ") else { return nil }
        if reason.contains("money") {
            return TessMemoryScreen.Refusal.money("").line
        }
        if reason.contains("place") {
            return TessMemoryScreen.Refusal.place("").line
        }
        if reason.contains("secret") {
            return TessMemoryScreen.Refusal.secret.line // Research BM11: "I don't keep passwords."
        }
        if reason.contains("capFull") {
            return TessMemory.capLine
        }
        return nil
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

    public func summary(in store: ObjectStore) -> String {
        // Written right after apply: the lines it just deleted are the ones gone in the last moments.
        let gone = TessMemoryStore.recentlyDeleted(store: store, within: 5).count
        return gone > 0 ? "Everything forgotten, \(gone) \(gone == 1 ? "thing" : "things")." : "Everything forgotten."
    }
}

/// Reads, packs and keeps the memory: the page's groups, the pack's block, the 04:00 turnover.
@MainActor
public struct TessMemoryStore {
    public let engine: ActionEngine
    public var calendar: Calendar
    /// The forget log outside the store (Application Support, never inside a .tessera backup), so a restored backup
    /// from before a forget still forgets it (QA F2b on #356). Nil keeps the log in the store only (tests).
    public var forgetLogURL: URL?

    public init(engine: ActionEngine, calendar: Calendar = .current, forgetLogURL: URL? = Self.defaultForgetLogURL) {
        self.engine = engine
        self.calendar = calendar
        self.forgetLogURL = forgetLogURL
    }

    /// Application Support/Tessera/tess-forgotten.json: hashes only, no words.
    public static var defaultForgetLogURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Tessera/tess-forgotten.json")
    }

    var store: ObjectStore {
        engine.store
    }

    static func records(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> [ObjectRecord] {
        guard let memoryClass = classes[.tessMemory] else { return [] }
        return store.objects(of: memoryClass)
            .filter { !$0.isDeleted && store.value("kind", of: $0) != .choice(TessMemory.Kind.forgotten.rawValue) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Memories deleted in the last `within` seconds.
    static func recentlyDeleted(store: ObjectStore, within seconds: TimeInterval) -> [ObjectRecord] {
        guard let memoryClass = store.classDef(named: "Memory") else { return [] }
        return (memoryClass.objects ?? []).filter { object in
            guard let deletedAt = object.deletedAt, object.title != TessMemoryStore.redacted,
                  store.value("kind", of: object) != .choice(TessMemory.Kind.forgotten.rawValue) else { return false }
            return Date.now.timeIntervalSince(deletedAt) < seconds
        }
    }

    /// The sweep after the UNDO window: every memory deleted more than 10 s ago gets its words scrubbed (QA F2), so a
    /// quit inside the window, or forget-everything, still ends in redaction. The turnover runs it; the page may too.
    @discardableResult
    public func sweepForgotten(now: Date = .now) -> Int {
        // Deleted objects too: the store's own list leaves them out.
        guard let memoryClass = engine.classes[.tessMemory] else { return 0 }
        let due = (memoryClass.objects ?? []).filter { object in
            guard let deletedAt = object.deletedAt, object.title != Self.redacted,
                  store.value("kind", of: object) != .choice(TessMemory.Kind.forgotten.rawValue) else { return false }
            return now.timeIntervalSince(deletedAt) > 10
        }
        for object in due {
            redact(object.id)
        }
        return due.count
    }

    /// Rules whose line he forgot (the object is gone but remembered as deleted): the turnover never writes them again
    /// (Research F1), and forget-everything stays forgotten.
    func suppressedRules() -> Set<String> {
        guard let memoryClass = engine.classes[.tessMemory] else { return [] }
        return Set((memoryClass.objects ?? []).filter(\.isDeleted)
            .compactMap { store.value("rule", of: $0)?.stringValue })
    }

    func read(_ object: ObjectRecord) -> TessMemory {
        TessMemory(id: object.id,
                   kind: store.value("kind", of: object)?.stringValue
                       .flatMap { TessMemory.Kind(rawValue: $0) } ?? .told,
                   area: store.value("area", of: object)?.stringValue.flatMap { TessMemory.Area(rawValue: $0) }
                       ?? .about,
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
        for area in [TessMemory.Area.training, .kitchen, .people, .about] {
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
        guard total > 0 else { return "Nothing kept yet." }
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
        guard !words.isEmpty, words != Self.redacted else { return }
        // The hash goes in the forget log, so a restored backup forgets it again (Research F2).
        logForgotten(words)
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

    /// The hash of forgotten words, kept as its own quiet object (no words, never shown or packed) and in the log
    /// file outside the store.
    func logForgotten(_ words: String) {
        guard let memoryClass = engine.classes[.tessMemory] else { return }
        let hash = Self.hash(words)
        var log = Self.readForgetLog(forgetLogURL)
        if log.forgotten[hash] == nil {
            log.forgotten[hash] = .now
            Self.writeForgetLog(log, to: forgetLogURL)
        }
        guard !storedForgottenHashes().contains(hash) else { return }
        let entry = store.create(memoryClass, title: hash)
        try? store.set("kind", to: .choice(TessMemory.Kind.forgotten.rawValue), on: entry)
        try? store.set("isPrivate", to: .bool(true), on: entry)
    }

    /// Hashes from the store and the file together.
    func forgottenHashes() -> Set<String> {
        storedForgottenHashes().union(Self.readForgetLog(forgetLogURL).forgotten.keys)
    }

    func storedForgottenHashes() -> Set<String> {
        guard let memoryClass = engine.classes[.tessMemory] else { return [] }
        return Set(store.objects(of: memoryClass)
            .filter { !$0.isDeleted && store.value("kind", of: $0) == .choice(TessMemory.Kind.forgotten.rawValue) }
            .map(\.title))
    }

    /// The log file: each hash with when he forgot it, and when forgets were last re-applied. Hashes only, no words.
    /// Not cleared by a reset of the store; "erase everything" has to delete it too.
    struct ForgetLog: Codable {
        var forgotten: [String: Date] = [:]
        var reappliedAt: Date?
    }

    static func readForgetLog(_ url: URL?) -> ForgetLog {
        guard let url, let data = try? Data(contentsOf: url) else { return ForgetLog() }
        if let log = try? JSONDecoder().decode(ForgetLog.self, from: data) {
            return log
        }
        // The first shape was a bare list of hashes; those count as forgotten long ago.
        let hashes = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        return ForgetLog(forgotten: Dictionary(uniqueKeysWithValues: hashes.map { ($0, Date.distantPast) }))
    }

    static func writeForgetLog(_ log: ForgetLog, to url: URL?) {
        guard let url, let data = try? JSONEncoder().encode(log) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    /// When each forgotten line was forgotten: the store's quiet objects and the file together.
    func forgottenAt() -> [String: Date] {
        var when = Self.readForgetLog(forgetLogURL).forgotten
        guard let memoryClass = engine.classes[.tessMemory] else { return when }
        for entry in store.objects(of: memoryClass)
            where !entry.isDeleted && store.value("kind", of: entry) == .choice(TessMemory.Kind.forgotten.rawValue)
        {
            when[entry.title] = min(when[entry.title] ?? .distantFuture, entry.createdAt)
        }
        return when
    }

    /// Forgets again every line whose words he forgot after it was written: what a restored backup brings back. A
    /// line he said again after forgetting it is newer than the forget, so it stays (QA F6 on #356).
    @discardableResult
    public func reapplyForgets() -> Int {
        let when = forgottenAt()
        guard !when.isEmpty else { return 0 }
        let back = all().filter { memory in
            when[Self.hash(memory.text)].map { memory.createdAt < $0 } ?? false
        }
        for memory in back {
            redact(memory.id)
        }
        return back.count
    }

    /// The first launch after a backup restore re-applies the forgets, once; every other launch does nothing.
    @discardableResult
    public func reapplyForgetsIfRestored(now: Date = .now) -> Int {
        guard let restored = TesseraBackup.restoredAt(for: store.context.url) else { return 0 }
        var log = Self.readForgetLog(forgetLogURL)
        guard (log.reappliedAt ?? .distantPast) < restored else { return 0 }
        let count = reapplyForgets()
        log.reappliedAt = now
        Self.writeForgetLog(log, to: forgetLogURL)
        return count
    }

    static func hash(_ words: String) -> String {
        SHA256.hash(data: Data(words.lowercased().utf8)).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Writes without ops (counted lines are weather, not something he did)

    @discardableResult
    func write(kind: TessMemory.Kind, area: TessMemory.Area, text: String, evidence: [UUID], day: Date?,
               numbers: Set<Int> = [], rule: String? = nil) -> ObjectRecord?
    {
        guard let memoryClass = engine.classes[.tessMemory],
              TessMemoryScreen.refusal(for: text, numbers: numbers.union(HomeLines.digits(in: day == nil ? nil : text)))
              == nil else { return nil }
        // A rule he forgot, or words he forgot, stay forgotten.
        if let rule, suppressedRules().contains(rule) {
            return nil
        }
        if forgottenHashes().contains(Self.hash(text)) {
            return nil
        }
        // A rule's line keeps its id across recomputes: updated in place.
        if let rule, let existing = Self.records(store: store, classes: engine.classes)
            .first(where: { store.value("rule", of: $0)?.stringValue == rule })
        {
            existing.title = text
            try? store.setLinks("evidence", on: existing, to: evidence.compactMap { store.object(id: $0) })
            return existing
        }
        let object = store.create(memoryClass, title: text)
        if let rule {
            try? store.set("rule", to: .text(rule), on: object)
        }
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

    /// Where a told line belongs, from its words (whole words: "espresso" is not a press, "weather" not a meal).
    static func guessArea(_ text: String) -> TessMemory.Area {
        let words = Set(text.lowercased().split { !$0.isLetter && $0 != "'" }.map { $0.replacingOccurrences(
            of: "'s",
            with: ""
        ) })
        let training: Set = ["train", "trains", "training", "workout", "workouts", "gym", "lift", "lifts",
                             "lifting", "bench", "squat", "squats", "deadlift", "deadlifts", "press", "rest",
                             "routine", "routines", "sets", "reps", "pr", "prs", "cardio", "run", "runs"]
        let kitchen: Set = ["cook", "cooks", "cooking", "recipe", "recipes", "grocery", "groceries", "dinner",
                            "lunch", "breakfast", "kitchen", "meal", "meals", "buy", "tacos", "chili", "pantry"]
        let people: Set = ["mom", "dad", "mother", "father", "wife", "husband", "partner", "brother", "sister",
                           "friend", "friends", "birthday", "anniversary", "kids", "son", "daughter"]
        if !words.isDisjoint(with: training) {
            return .training
        }
        if !words.isDisjoint(with: kitchen) {
            return .kitchen
        }
        if !words.isDisjoint(with: people) {
            return .people
        }
        return .about
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
        var words = text.trimmingCharacters(in: CharacterSet(charactersIn: ". ")).split(separator: " ")
        if let first = words.first, ["you", "your", "you're"].contains(first.lowercased()) {
            words.removeFirst()
        }
        let head = words.prefix(2).joined(separator: " ")
        return head.prefix(1).uppercased() + head.dropFirst()
    }
}
