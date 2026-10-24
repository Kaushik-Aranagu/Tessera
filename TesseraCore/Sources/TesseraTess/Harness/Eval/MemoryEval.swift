import Foundation

// The nightly memory eval (memory spec M6, checks.md I5 and I6). Questions are written from the store with their
// right answers, so nobody labels anything: the store is the answer key. Each night about 50 run through the real
// compiler on Haiku and on Sonnet, are scored exactly, and the scores move the sizes (BudgetTuner) and the rungs
// (pickRung). This file is the pure part: the questions, the scoring and the night's record. An adapter on the store
// side turns objects into `MemoryEvalFacts`.

/// The five abilities LongMemEval tests, in our words.
public enum EvalKind: String, Codable, Sendable, CaseIterable, CodingKeyRepresentable {
    /// One thing on one day: "What did I bench on Oct 3?"
    case find
    /// A count across days: "How many times did I cook chili this month?"
    case acrossDays
    /// A date: "When did I start Push Pull Legs?"
    case when
    /// The current belief after a change: "When do I usually train now?"
    case changed
    /// Nothing is kept: the right answer is "I don't know yet."
    case dontKnow

    /// The pack section that should have held the answer, for the tuner. A wrong "don't know" is a behavior miss,
    /// not a size miss.
    public var section: ContextSection? {
        switch self {
        case .find, .acrossDays, .when: .recall
        case .changed: .core
        case .dontKnow: nil
        }
    }
}

/// What the store adapter hands the generator. Names are shown names: a private object arrives under its label
/// ("Private workout") or not at all, so no walled title ever becomes a question.
public struct MemoryEvalFacts: Sendable {
    public struct SetFact: Sendable {
        public var exercise: String
        public var day: Date
        public var weight: Double
        public var unit: String
        public var reps: Int

        public init(exercise: String, day: Date, weight: Double, unit: String, reps: Int) {
            self.exercise = exercise
            self.day = day
            self.weight = weight
            self.unit = unit
            self.reps = reps
        }
    }

    /// A dated thing that can be counted or dated: a cook of a recipe, a workout of a routine.
    public struct Event: Sendable {
        public var name: String
        /// "cook" or "do", for the wording: "cook chili", "do Push Day".
        public var verb: String
        public var day: Date

        public init(name: String, verb: String, day: Date) {
            self.name = name
            self.verb = verb
            self.day = day
        }
    }

    /// A belief that was closed and replaced: the question asks for the current one.
    public struct Change: Sendable {
        /// The question as he'd ask it: "When do I usually train?"
        public var question: String
        public var old: String
        public var current: String

        public init(question: String, old: String, current: String) {
            self.question = question
            self.old = old
            self.current = current
        }
    }

    public var sets: [SetFact]
    public var events: [Event]
    public var changes: [Change]
    /// Questions about keys with no belief at all ("What's my favorite cuisine?").
    public var unknowns: [String]

    public init(sets: [SetFact] = [], events: [Event] = [], changes: [Change] = [], unknowns: [String] = []) {
        self.sets = sets
        self.events = events
        self.changes = changes
        self.unknowns = unknowns
    }
}

public struct EvalQuestion: Codable, Sendable, Equatable {
    public enum Expected: Codable, Sendable, Equatable {
        case number(Double, unit: String?)
        case day(Date)
        case text(String)
        case dontKnow
    }

    /// Stable across nights for the same fact, so a miss can be kept and asked again.
    public var id: String
    public var kind: EvalKind
    public var text: String
    public var expected: Expected

    /// The kind a question id names by its first part ("find/...", "count/...").
    public static func kind(ofID id: String) -> EvalKind? {
        switch id.split(separator: "/").first.map(String.init) ?? "" {
        case "find": .find
        case "count": .acrossDays
        case "when": .when
        case "changed": .changed
        case "unknown": .dontKnow
        default: nil
        }
    }
}

public struct MemoryEval: Sendable {
    public static let perNight = 50

    public var calendar: Calendar
    public var now: Date

    public init(calendar: Calendar = .current, now: Date = .now) {
        self.calendar = calendar
        self.now = now
    }

    // MARK: Questions

    /// Up to `count` questions, an even spread over the kinds the facts allow, kept misses first. The same facts
    /// and night always give the same questions.
    public func questions(from facts: MemoryEvalFacts, night: String, count: Int = MemoryEval.perNight,
                          keep: [EvalQuestion] = []) -> [EvalQuestion]
    {
        var pools: [EvalKind: [EvalQuestion]] = [
            .find: finds(facts), .acrossDays: counts(facts), .when: starts(facts),
            .changed: facts.changes.map(changed), .dontKnow: facts.unknowns.map(unknown),
        ]
        var random = SplitMix(seed: Self.seed(night))
        for kind in EvalKind.allCases {
            pools[kind] = random.shuffled(pools[kind] ?? [])
        }
        var picked = Array(keep.prefix(count))
        var seen = Set(picked.map(\.id))
        while picked.count < count {
            var added = false
            for kind in EvalKind.allCases where picked.count < count {
                guard var pool = pools[kind], !pool.isEmpty else { continue }
                let next = pool.removeFirst()
                pools[kind] = pool
                if seen.insert(next.id).inserted {
                    picked.append(next)
                    added = true
                }
            }
            if !added, pools.values.allSatisfy(\.isEmpty) { break }
        }
        return picked
    }

    func finds(_ facts: MemoryEvalFacts) -> [EvalQuestion] {
        facts.sets.map { set in
            let day = Self.dayText(set.day, calendar: calendar)
            return EvalQuestion(id: "find/\(set.exercise)/\(Self.stamp(set.day, calendar: calendar))/\(set.reps)",
                                kind: .find,
                                text: "What weight did I do for \(set.reps) on \(set.exercise) on \(day)?",
                                expected: .number(set.weight, unit: set.unit))
        }
        // Two sets of one exercise and reps on one day make the question ambiguous: keep only the heaviest.
        .reduce(into: [String: EvalQuestion]()) { best, question in
            if case let .number(weight, _) = question.expected,
               case let .number(kept, _)? = best[question.id]?.expected, kept >= weight
            {
                return
            }
            best[question.id] = question
        }
        .values.sorted { $0.id < $1.id }
    }

    func counts(_ facts: MemoryEvalFacts) -> [EvalQuestion] {
        guard let month = calendar.dateInterval(of: .month, for: now) else { return [] }
        let monthName = Self.monthText(now, calendar: calendar)
        let inMonth = facts.events.filter { month.contains($0.day) }
        return Dictionary(grouping: inMonth, by: { "\($0.verb)|\($0.name)" }).map { key, events in
            let first = events[0]
            return EvalQuestion(id: "count/\(key)/\(Self.stamp(month.start, calendar: calendar))", kind: .acrossDays,
                                text: "How many times did I \(first.verb) \(first.name) in \(monthName)?",
                                expected: .number(Double(events.count), unit: nil))
        }
        .sorted { $0.id < $1.id }
    }

    func starts(_ facts: MemoryEvalFacts) -> [EvalQuestion] {
        Dictionary(grouping: facts.events, by: { "\($0.verb)|\($0.name)" }).compactMap { key, events in
            guard let first = events.map(\.day).min() else { return nil }
            let verb = events[0].verb, name = events[0].name
            return EvalQuestion(id: "when/\(key)", kind: .when,
                                text: "When did I first \(verb) \(name)?", expected: .day(first))
        }
        .sorted { $0.id < $1.id }
    }

    func changed(_ change: MemoryEvalFacts.Change) -> EvalQuestion {
        EvalQuestion(id: "changed/\(change.question)", kind: .changed, text: change.question,
                     expected: .text(change.current))
    }

    func unknown(_ question: String) -> EvalQuestion {
        EvalQuestion(id: "unknown/\(question)", kind: .dontKnow, text: question, expected: .dontKnow)
    }

    // MARK: Scoring

    static let abstentions = ["don't know", "do not know", "not sure", "no record", "nothing kept", "haven't logged",
                              "can't find", "couldn't find", "no data", "don't have"]

    /// Exact scoring: the right number (in either unit), the right day, the current text and not the old one, or a
    /// plain "I don't know". A guess where the answer is "I don't know" is wrong, and so is "I don't know" where the
    /// store has the answer.
    public func isRight(_ answer: String, for question: EvalQuestion, old: String? = nil) -> Bool {
        let lower = answer.lowercased()
        let abstained = Self.abstentions.contains { lower.contains($0) }
        switch question.expected {
        case .dontKnow:
            return abstained
        case let .number(value, unit):
            guard !abstained else { return false }
            // The answer must say the number (in either unit). Other numbers around it (reps, a date) don't matter.
            let wanted = AnswerCheck.claims(in: "\(Self.plain(value)) \(unit ?? "")")
            return AnswerCheck.claims(in: answer).contains { AnswerCheck.supported($0, by: wanted) }
        case let .day(day):
            guard !abstained else { return false }
            return Self.dayForms(day, calendar: calendar).contains { Self.says(lower, $0) }
        case let .text(text):
            guard !abstained, lower.contains(text.lowercased()) else { return false }
            return old.map { !lower.contains($0.lowercased()) } ?? true
        }
    }

    // MARK: Words

    /// Whether `text` holds `form` not followed by another digit ("sep 2" is not in "sep 28").
    static func says(_ text: String, _ form: String) -> Bool {
        var start = text.startIndex
        while let range = text.range(of: form, range: start ..< text.endIndex) {
            if range.upperBound == text.endIndex || !text[range.upperBound].isNumber {
                return true
            }
            start = range.upperBound
        }
        return false
    }

    static func plain(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    static func stamp(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func formatter(_ format: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }

    /// "Oct 3", the way the app writes a day.
    static func dayText(_ date: Date, calendar: Calendar) -> String {
        formatter("MMM d", calendar: calendar).string(from: date)
    }

    static func monthText(_ date: Date, calendar: Calendar) -> String {
        formatter("MMMM", calendar: calendar).string(from: date)
    }

    /// Ways an answer may name the day, lowercased: "oct 3", "october 3", "3 oct", "3 october", "2026-10-03", "10/3".
    static func dayForms(_ date: Date, calendar: Calendar) -> [String] {
        ["MMM d", "MMMM d", "d MMM", "d MMMM", "yyyy-MM-dd", "M/d"].map {
            formatter($0, calendar: calendar).string(from: date).lowercased()
        }
    }

    static func seed(_ night: String) -> UInt64 {
        // FNV-1a: stable across launches, unlike Hasher.
        night.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }
}

// MARK: - Nights

/// One night's run on one model: how many of each kind were asked and answered right, and which missed.
public struct EvalNight: Codable, Sendable, Equatable {
    public var night: String
    public var model: String
    public var asked: [EvalKind: Int]
    public var right: [EvalKind: Int]
    public var missed: [String]

    public init(night: String, model: String, asked: [EvalKind: Int] = [:], right: [EvalKind: Int] = [:],
                missed: [String] = [])
    {
        self.night = night
        self.model = model
        self.asked = asked
        self.right = right
        self.missed = missed
    }

    /// Percent right over every question asked (0...100), or nil when nothing was asked.
    public var score: Double? {
        let total = asked.values.reduce(0, +)
        return total == 0 ? nil : Double(right.values.reduce(0, +)) / Double(total) * 100
    }

    public mutating func record(_ question: EvalQuestion, right isRight: Bool) {
        asked[question.kind, default: 0] += 1
        if isRight {
            right[question.kind, default: 0] += 1
        } else {
            missed.append(question.id)
        }
    }
}

/// The eval's memory, in `Application Support/Tessera/memory-eval.json` (excluded from backups): the last 60 nights,
/// and every missed question, asked again each night until it has been right 7 nights running (checks.md I5).
/// Questions hold shown names only, never his words or a walled title.
public struct MemoryEvalRecord: Codable, Sendable, Equatable {
    public static let fileName = "memory-eval.json"
    public static let keepNights = 60
    public static let clearAfter = 7

    public var nights: [EvalNight]
    public var kept: [EvalQuestion]
    public var streaks: [String: Int]

    public init(nights: [EvalNight] = [], kept: [EvalQuestion] = [], streaks: [String: Int] = [:]) {
        self.nights = nights
        self.kept = kept
        self.streaks = streaks
    }

    /// Adds a night: misses join the kept list; a kept question right again moves its streak on, and leaves the list
    /// after 7 right nights in a row. A night that ran on two models counts a question right only if both got it.
    public mutating func add(_ runs: [EvalNight], questions: [EvalQuestion]) {
        nights.append(contentsOf: runs)
        if nights.count > Self.keepNights * 2 {
            nights.removeFirst(nights.count - Self.keepNights * 2)
        }
        let missed = Set(runs.flatMap(\.missed))
        for question in questions {
            if missed.contains(question.id) {
                if !kept.contains(where: { $0.id == question.id }) {
                    kept.append(question)
                }
                streaks[question.id] = 0
            } else if kept.contains(where: { $0.id == question.id }) {
                let streak = (streaks[question.id] ?? 0) + 1
                if streak >= Self.clearAfter {
                    kept.removeAll { $0.id == question.id }
                    streaks[question.id] = nil
                } else {
                    streaks[question.id] = streak
                }
            }
        }
    }

    /// Percent right per kind for one model over its last `nights` nights (I6: the scores pick the rung).
    public func kindScores(model: String, nights count: Int = 7) -> [EvalKind: Double] {
        let recent = nights.filter { $0.model == model }.suffix(count)
        var scores: [EvalKind: Double] = [:]
        for kind in EvalKind.allCases {
            let asked = recent.reduce(0) { $0 + ($1.asked[kind] ?? 0) }
            let right = recent.reduce(0) { $0 + ($1.right[kind] ?? 0) }
            if asked > 0 {
                scores[kind] = Double(right) / Double(asked) * 100
            }
        }
        return scores
    }

    /// Last night's misses as the tuner reads them: each kind's section, once per section.
    public func tunerMisses(agent: String, model: BrainID) -> [EvalMiss] {
        guard let last = nights.last(where: { $0.model == model.rawValue }) else { return [] }
        let kinds = Set(last.missed.compactMap(EvalQuestion.kind(ofID:)))
        let sections = Set(kinds.compactMap(\.section))
        return ContextSection.allCases.filter { sections.contains($0) }
            .map { EvalMiss(agent: agent, model: model, section: $0) }
    }

    public static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Tessera/\(fileName)")
    }

    public static func load(from url: URL? = defaultURL) -> MemoryEvalRecord {
        guard let url, let data = try? Data(contentsOf: url),
              let record = try? JSONDecoder().decode(MemoryEvalRecord.self, from: data)
        else { return MemoryEvalRecord() }
        return record
    }

    public func save(to url: URL? = MemoryEvalRecord.defaultURL) {
        guard let url, let data = try? JSONEncoder().encode(self) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        #if os(iOS)
            try? data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
            try? data.write(to: url, options: [.atomic])
        #endif
        var excluded = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
    }
}

/// A small seeded generator, so a night's questions are the same every time they're drawn.
struct SplitMix {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    mutating func shuffled<T>(_ items: [T]) -> [T] {
        var items = items
        guard items.count > 1 else { return items }
        for index in stride(from: items.count - 1, to: 0, by: -1) {
            let other = Int(next() % UInt64(index + 1))
            items.swapAt(index, other)
        }
        return items
    }
}
