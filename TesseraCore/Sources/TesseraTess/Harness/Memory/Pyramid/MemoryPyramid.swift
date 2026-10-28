import Foundation

// P1 of the memory pyramid (docs/ai/harness/memory-pyramid.md): memory as levels, from leaves kept word for word up
// to a year. Each level keeps the exact totals of what is under it (the engine's numbers, never a model's) and, for
// each child, the one or two lines that make it differ from its siblings: its residual. Reading a node and its
// residuals gives every child's distinct point without opening one, so Tess zooms only as deep as an ask needs.
//
// This slice is the time axis, built from plain leaves so the test world can drive it before the store does. The
// words (a gist per node) come in a later slice from a model; everything here is exact and deterministic.

/// One thing that happened, word for word: a set of lifts, a meal, a spend. A private thing is `deviceOnly`; its `text`
/// is its own words while Claude sees everything (`ClaudeSees`), its shown label otherwise.
public struct PyramidLeaf: Sendable, Equatable {
    public var id: String
    public var at: Date
    /// A short kind word: workout, cook, spend, note...
    public var kind: String
    public var text: String
    /// What the text may do: money, body and calendar leaves are `deviceOnly`.
    public var taint: Taint
    /// What it adds to the totals above it, by `PyramidStats` key.
    public var stats: [String: Double]

    public init(id: String, at: Date, kind: String, text: String, taint: Taint = .claudeSafe,
                stats: [String: Double] = [:])
    {
        self.id = id
        self.at = at
        self.kind = kind
        self.text = text
        self.taint = taint
        self.stats = stats
    }
}

/// One line of a node and what it may do.
public struct PyramidLine: Sendable, Equatable {
    public var text: String
    public var taint: Taint
}

/// What makes each child of a node differ from its siblings, for one policy.
public struct PyramidResiduals: Sendable, Equatable {
    /// Best first, by child path.
    public var lines: [String: [PyramidLine]] = [:]
    /// The children with a residual, the one that stands out most first: the order a zoom lists them.
    public var ranked: [String] = []
}

public struct PyramidNode: Sendable, Equatable {
    public enum Level: String, Sendable {
        case leaf, day, week, month, year, root
    }

    /// The residuals a policy reads.
    public func residualsSeen(by policy: DoorPolicy) -> PyramidResiduals {
        policy == .lab ? residuals : strictResiduals
    }

    public var path: String
    public var level: Level
    /// How a reader names it: "October 2026", "Week 43, 2026", "Fri, Oct 23, 2026".
    public var title: String
    /// The primary children: a year's months, a month's or a week's days, a day's leaves.
    public var children: [String]
    /// The other chain it sits on: a day's week, a year's weeks.
    public var also: [String]
    /// Exact totals of everything under it.
    public var stats: [String: Double]
    /// What makes each child differ from all its siblings, over every total: what lab reads.
    public var residuals: PyramidResiduals
    /// The same over only the siblings strict can see and only claude-safe totals, so a walled sibling never shapes
    /// a "most" or "fewest" (or its rank) that strict shows.
    public var strictResiduals: PyramidResiduals
    /// A fingerprint of everything under it: one edit below changes exactly its own chain of ancestors.
    public var hash: UInt64
    /// A leaf's own words.
    public var text: PyramidLine?
    /// How many claude-safe leaves are under it: under strict, a node with none is not there at all, so a day that
    /// holds only a spend or a night's sleep is never named, listed or counted.
    public var safeLeaves: Int
}

/// The totals a node keeps, how each reads, and what it may do.
public enum PyramidStats {
    struct Shown: Sendable {
        let key: String
        let label: String
        let taint: Taint
        let value: @Sendable ([String: Double]) -> Double?
    }

    static func sum(_ key: String) -> @Sendable ([String: Double]) -> Double? {
        { stats in stats[key].flatMap { $0 > 0 ? $0 : nil } }
    }

    static func average(_ total: String, over count: String) -> @Sendable ([String: Double]) -> Double? {
        { stats in
            guard let count = stats[count], count > 0, let total = stats[total] else { return nil }
            return total / count
        }
    }

    /// In the order a node lists them. Money, sleep, weight and the calendar stay on the phone under strict.
    static let shown: [Shown] = [
        Shown(key: "workouts", label: "workouts", taint: .claudeSafe, value: sum("workouts")),
        Shown(key: "sets", label: "sets", taint: .claudeSafe, value: sum("sets")),
        // Whole kilograms: a decimal beside "kg" reads as his body weight to the strict wall ("38437.5 kg lifted").
        Shown(key: "volumeKg", label: "kg lifted", taint: .claudeSafe,
              value: { stats in sum("volumeKg")(stats).map { $0.rounded() } }),
        Shown(key: "cooks", label: "meals cooked", taint: .claudeSafe, value: sum("cooks")),
        Shown(key: "chores", label: "chores done", taint: .claudeSafe, value: sum("chores")),
        Shown(key: "tasks", label: "tasks done", taint: .claudeSafe, value: sum("tasks")),
        Shown(key: "habits", label: "habit check-ins", taint: .claudeSafe, value: sum("habits")),
        Shown(key: "notes", label: "notes", taint: .claudeSafe, value: sum("notes")),
        Shown(key: "told", label: "things he told you", taint: .claudeSafe, value: sum("told")),
        Shown(key: "events", label: "calendar events", taint: .deviceOnly, value: sum("events")),
        Shown(key: "spentUSD", label: "dollars spent", taint: .deviceOnly, value: sum("spentUSD")),
        Shown(key: "spentEUR", label: "euros spent", taint: .deviceOnly, value: sum("spentEUR")),
        Shown(key: "spentGBP", label: "pounds spent", taint: .deviceOnly, value: sum("spentGBP")),
        Shown(key: "spentINR", label: "rupees spent", taint: .deviceOnly, value: sum("spentINR")),
        Shown(key: "earnedUSD", label: "dollars in", taint: .deviceOnly, value: sum("earnedUSD")),
        Shown(key: "earnedEUR", label: "euros in", taint: .deviceOnly, value: sum("earnedEUR")),
        Shown(key: "earnedGBP", label: "pounds in", taint: .deviceOnly, value: sum("earnedGBP")),
        Shown(key: "earnedINR", label: "rupees in", taint: .deviceOnly, value: sum("earnedINR")),
        Shown(key: "sleep", label: "hours of sleep a night", taint: .deviceOnly,
              value: average("sleepHours", over: "nights")),
        Shown(key: "weight", label: "kg body weight on average", taint: .deviceOnly,
              value: average("weightKg", over: "weighIns")),
        Shown(key: "steps", label: "steps", taint: .deviceOnly, value: sum("steps")),
        Shown(key: "restingBpm", label: "bpm resting heart rate on average", taint: .deviceOnly,
              value: average("restingBpm", over: "heartDays")),
    ]

    /// The totals strict shows. Only a claude-safe leaf adds to them.
    static let safeKeys = Set(shown.filter { $0.taint == .claudeSafe }.map(\.key))

    /// A number as a line shows it: whole numbers plain, others to one place.
    static func format(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
    }
}

public struct MemoryPyramid: Sendable {
    public static let root = "/time"
    /// The most one zoom answer holds.
    public static let maxCharacters = 1200
    /// The most children a zoom lists by their residual; the rest are counted.
    static let maxListed = 8
    /// The most residual lines a child keeps.
    static let maxResiduals = 2

    public private(set) var nodes: [String: PyramidNode] = [:]

    public init(leaves: [PyramidLeaf], calendar: Calendar) {
        let format = { (template: String, date: Date) -> String in
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = template
            return formatter.string(from: date)
        }
        var days: [String: (title: String, leaves: [PyramidLeaf])] = [:]
        var dayParents: [String: (week: String, month: String)] = [:]
        var weekTitles: [String: String] = [:], monthTitles: [String: String] = [:]
        for leaf in leaves {
            let parts = calendar.dateComponents([.year, .month, .day, .yearForWeekOfYear, .weekOfYear], from: leaf.at)
            let year = parts.year ?? 0, month = parts.month ?? 0, day = parts.day ?? 0
            let monthPath = "\(Self.root)/\(year)/\(Self.two(month))"
            let dayPath = "\(monthPath)/\(Self.two(day))"
            let weekYear = parts.yearForWeekOfYear ?? year, week = parts.weekOfYear ?? 0
            let weekPath = "\(Self.root)/\(weekYear)/w\(Self.two(week))"
            days[dayPath, default: (format("EEE, MMM d, yyyy", leaf.at), [])].leaves.append(leaf)
            dayParents[dayPath] = (weekPath, monthPath)
            weekTitles[weekPath] = "Week \(week), \(weekYear)"
            if monthTitles[monthPath] == nil {
                monthTitles[monthPath] = format("MMMM yyyy", leaf.at)
            }
        }

        // Leaves and days.
        var monthDays: [String: [String]] = [:], weekDays: [String: [String]] = [:]
        for (dayPath, day) in days {
            let sorted = day.leaves.sorted { ($0.at, $0.id) < ($1.at, $1.id) }
            // An opaque path: a kind would say there is a spend or a weigh-in even where its words are walled, and a
            // number counted over every leaf would leave a gap where a walled one sits. Safe leaves take theirs first,
            // so a walled leaf can never shift one.
            var named = [String?](repeating: nil, count: sorted.count)
            let safeFirst = sorted.indices.filter { sorted[$0].taint == .claudeSafe }
                + sorted.indices.filter { sorted[$0].taint != .claudeSafe }
            for index in safeFirst {
                named[index] = Self.leafPath(dayPath, sorted[index].id, taken: named.compactMap { $0 })
            }
            var paths: [String] = []
            for (index, leaf) in sorted.enumerated() {
                let path = named[index] ?? Self.leafPath(dayPath, leaf.id, taken: paths)
                paths.append(path)
                let print = ([leaf.kind, String(leaf.at.timeIntervalSince1970), leaf.text]
                    + leaf.stats.keys.sorted().map { "\($0)=\(leaf.stats[$0] ?? 0)" }).joined(separator: "|")
                // A walled leaf counts for nothing a strict total shows: its "notes 1" would tell strict it was there.
                let stats = leaf.taint == .claudeSafe ? leaf.stats
                    : leaf.stats.filter { !PyramidStats.safeKeys.contains($0.key) }
                nodes[path] = PyramidNode(path: path, level: .leaf, title: leaf.kind, children: [], also: [],
                                          stats: stats, residuals: PyramidResiduals(),
                                          strictResiduals: PyramidResiduals(), hash: Self.fnv(print),
                                          text: PyramidLine(text: leaf.text, taint: leaf.taint),
                                          safeLeaves: leaf.taint == .claudeSafe ? 1 : 0)
            }
            guard let parents = dayParents[dayPath] else { continue }
            add(dayPath, .day, day.title, children: paths, also: [parents.week])
            monthDays[parents.month, default: []].append(dayPath)
            weekDays[parents.week, default: []].append(dayPath)
        }

        // Weeks and months, then years and the root.
        var yearMonths: [String: [String]] = [:], yearWeeks: [String: [String]] = [:]
        for (path, children) in weekDays {
            add(path, .week, weekTitles[path] ?? path, children: children.sorted(), also: [])
            yearWeeks[Self.parent(path), default: []].append(path)
        }
        for (path, children) in monthDays {
            add(path, .month, monthTitles[path] ?? path, children: children.sorted(), also: [])
            yearMonths[Self.parent(path), default: []].append(path)
        }
        // A week that starts in December can belong to next year's weeks while its days sit in this year's months.
        for year in Set(yearMonths.keys).union(yearWeeks.keys) {
            add(year, .year, String(year.split(separator: "/").last ?? ""),
                children: (yearMonths[year] ?? []).sorted(), also: (yearWeeks[year] ?? []).sorted())
        }
        add(Self.root, .root, "Everything", children: Set(yearMonths.keys).union(yearWeeks.keys).sorted(), also: [])
    }

    /// Adds a node over children already built: exact totals, residuals and the hash.
    private mutating func add(_ path: String, _ level: PyramidNode.Level, _ title: String, children: [String],
                              also: [String])
    {
        let kids = children.compactMap { nodes[$0] }
        var stats: [String: Double] = [:]
        for kid in kids {
            stats.merge(kid.stats, uniquingKeysWith: +)
        }
        let hash = Self.fnv(([path] + kids.map { String($0.hash) }).joined(separator: "|"))
        let lab = level == .day ? PyramidResiduals() : Self.residuals(kids, PyramidStats.shown)
        let strict = level == .day ? PyramidResiduals()
            : Self.residuals(kids.filter { $0.safeLeaves > 0 }, PyramidStats.shown.filter { $0.taint == .claudeSafe })
        nodes[path] = PyramidNode(path: path, level: level, title: title, children: children, also: also,
                                  stats: stats, residuals: lab, strictResiduals: strict, hash: hash, text: nil,
                                  safeLeaves: kids.reduce(0) { $0 + $1.safeLeaves })
    }

    // MARK: Residuals

    /// For each child, what makes it differ from its siblings: the most or fewest of a total among them, ranked by
    /// how far it sits from their mean. Exact numbers, so a residual can't drift from the leaves.
    static func residuals(_ kids: [PyramidNode], _ totals: [PyramidStats.Shown]) -> PyramidResiduals {
        guard kids.count >= 3 else { return PyramidResiduals() }
        var out: [String: [(line: PyramidLine, score: Double)]] = [:]
        for shown in totals {
            let values = kids.map { shown.value($0.stats) ?? 0 }
            let mean = values.reduce(0, +) / Double(values.count)
            guard mean > 0 else { continue }
            let spread = (values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)).squareRoot()
            guard spread > 0, let high = values.max(), let low = values.min() else { continue }
            for (kid, value) in zip(kids, values) {
                let word: String
                if value == high, values.count(where: { $0 == high }) == 1 {
                    word = "most"
                } else if value == low, values.count(where: { $0 == low }) == 1 {
                    word = "fewest"
                } else {
                    continue
                }
                let text = "\(word) \(shown.label) (\(PyramidStats.format(value)))"
                out[kid.path, default: []].append((PyramidLine(text: text, taint: shown.taint),
                                                   abs(value - mean) / spread))
            }
        }
        let best = out.mapValues { lines in lines.sorted { $0.score > $1.score }.prefix(maxResiduals) }
        let score = best.mapValues { $0.first?.score ?? 0 }
        return PyramidResiduals(lines: best.mapValues { $0.map(\.line) },
                                ranked: best.keys.sorted { a, b in
                                    let left = score[a] ?? 0, right = score[b] ?? 0
                                    return left == right ? a < b : left > right
                                })
    }

    // MARK: Reading

    /// One node as Tess reads it: its title, its gist when a fresh one was written under this policy, its totals, then
    /// each child with what sets it apart, best first. Under strict, money, body and calendar things are not there at
    /// all: no total, no residual, no leaf, no path, no count. The facts `promotions` shows at the node's level come
    /// right after the totals, each computed exactly.
    public func zoom(_ path: String, policy: DoorPolicy, gists: PyramidGists = PyramidGists(),
                     promotions: PyramidPromotions? = nil) -> (text: String, isError: Bool)
    {
        let key = path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
        func visible(_ path: String) -> Bool {
            policy == .lab || (nodes[path]?.safeLeaves ?? 0) > 0
        }
        guard let node = nodes[key], visible(key) else { return ("Nothing there.", true) }
        func allows(_ taint: Taint) -> Bool {
            policy == .lab || taint == .claudeSafe
        }
        func allowed(_ line: PyramidLine) -> Bool {
            allows(line.taint)
        }
        if let text = node.text {
            return (text.text, false)
        }
        var lines = ["\(node.title) (\(node.path))"]
        let gist = (gists.fresh(key, policy: policy, in: self)?.sentences ?? []).filter { allows($0.taint) }
        if !gist.isEmpty {
            lines.append("In short: " + gist.map(\.text).joined(separator: " "))
        }
        let totals = PyramidStats.shown.compactMap { shown -> String? in
            guard let value = shown.value(node.stats), allows(shown.taint) else {
                return nil
            }
            return "\(shown.label) \(PyramidStats.format(value))"
        }
        if !totals.isEmpty {
            lines.append("Totals: " + totals.joined(separator: ", "))
        }
        for fact in promotions?.facts(at: node.level) ?? [] {
            if let line = factLine(fact, at: key, policy: policy), allowed(line) {
                lines.append(line.text)
            }
        }
        if node.level == .day {
            // A day lists its leaves word for word.
            for child in node.children {
                guard let leaf = nodes[child]?.text, allowed(leaf) else { continue }
                lines.append("\(child): \(leaf.text)")
            }
        } else {
            var listed = 0
            let residuals = node.residualsSeen(by: policy)
            for child in residuals.ranked where visible(child) {
                let shown = (residuals.lines[child] ?? []).filter(allowed).map(\.text)
                guard !shown.isEmpty, listed < Self.maxListed else { continue }
                lines.append("\(child): \(shown.joined(separator: "; "))")
                listed += 1
            }
            let children = node.children.filter(visible)
            if let first = children.first, children.count > listed {
                lines.append("\(children.count - listed) more under it: zoom one by its path, like \(first)")
            }
        }
        let also = node.also.filter(visible)
        if !also.isEmpty {
            lines.append("Also: \(also.prefix(3).joined(separator: ", "))\(also.count > 3 ? "…" : "")")
        }
        var text = lines.joined(separator: "\n")
        if text.count > Self.maxCharacters {
            text = String(text.prefix(Self.maxCharacters - 1)) + "…"
        }
        return (text, false)
    }

    /// The paths whose fingerprint differs from `old`: what a change made stale, and nothing else.
    public func stale(since old: MemoryPyramid) -> [String] {
        Set(nodes.keys).union(old.nodes.keys).filter { nodes[$0]?.hash != old.nodes[$0]?.hash }.sorted()
    }

    /// Every leaf under a node.
    public func leaves(under path: String) -> [PyramidNode] {
        guard let node = nodes[path] else { return [] }
        if node.level == .leaf {
            return [node]
        }
        return node.children.flatMap { leaves(under: $0) }
    }

    // MARK: Helpers

    /// A leaf's path: a short fingerprint of its id, so it says nothing of its kind, its place or its neighbors.
    static func leafPath(_ day: String, _ id: String, taken: [String]) -> String {
        var salt = 0
        while true {
            let print = String(fnv("leaf|\(id)|\(salt)") & 0xFFFF_FFFF, radix: 16)
            let path = "\(day)/leaf-\(String(repeating: "0", count: max(0, 8 - print.count)))\(print)"
            if !taken.contains(path) {
                return path
            }
            salt += 1
        }
    }

    static func two(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }

    static func parent(_ path: String) -> String {
        path.split(separator: "/").dropLast().reduce("") { $0 + "/" + $1 }
    }

    /// FNV-1a: a fixed, fast fingerprint for staleness (not for security).
    static func fnv(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }
}
