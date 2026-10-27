import Foundation

/// One tuning number (input-hygiene H9, docs/ai/harness/input-hygiene.md): what it is, what it ships as, how far it
/// may move, and which way is the safe way. Every number a tuner moves, or that he may set in Developer mode, is a
/// knob here, so one table shows them all and one log says who moved which and why.
public struct Knob: Sendable, Hashable, Identifiable {
    /// How a knob may move.
    public enum Guard: Sendable, Hashable {
        /// Either way, inside its range.
        case tunable
        /// A wall: a size cap, a retention window or a threshold that keeps something private or untrusted out.
        /// `tightensDown` says lower is stricter. Only he may loosen one; a tuner or Developer mode only tightens.
        case wall(tightensDown: Bool)
    }

    public let id: String
    /// Plain words for Developer mode.
    public let label: String
    public let shipped: Double
    public let range: ClosedRange<Double>
    public let guarded: Guard
    /// Whole numbers only (counts, characters, days).
    public let whole: Bool

    public init(_ id: String, _ label: String, shipped: Double, range: ClosedRange<Double>, guarded: Guard = .tunable,
                whole: Bool = false)
    {
        self.id = id
        self.label = label
        self.shipped = shipped
        self.range = range
        self.guarded = guarded
        self.whole = whole
    }

    /// Whether moving from `old` to `new` loosens a wall.
    func loosens(from old: Double, to new: Double) -> Bool {
        guard case let .wall(tightensDown) = guarded else { return false }
        return tightensDown ? new > old : new < old
    }
}

public extension Knob {
    // MARK: Context budgets (spec M3, `BudgetTuner`)

    static let budgetFaultRate = Knob("budget.faultRate", "Opens or recalls per run before recall grows",
                                      shipped: 0.3, range: 0.05 ... 1)
    static let budgetGrowth = Knob("budget.growth", "How much a section grows at once", shipped: 1.5,
                                   range: 1.1 ... 3)
    static let budgetFloorStep = Knob("budget.floorStep", "How far the recall floor drops at once", shipped: 0.05,
                                      range: 0.01 ... 0.2)
    static let budgetLowestFloor = Knob("budget.lowestFloor", "The lowest the recall floor goes", shipped: 0.3,
                                        range: 0.1 ... 0.9)
    static let budgetMinimumRuns = Knob("budget.minimumRuns", "Runs in a week before faults move anything",
                                        shipped: 5, range: 1 ... 50, whole: true)

    /// Every knob, in the order Developer mode lists them.
    static let all: [Knob] = [budgetFaultRate, budgetGrowth, budgetFloorStep, budgetLowestFloor, budgetMinimumRuns]
}

/// Who moved a knob.
public enum KnobSetter: String, Codable, Sendable {
    /// Kaushik, from Developer mode. The only one who may loosen a wall.
    case owner
    /// A tuner, at night.
    case tuner
    /// Developer mode's own reset or a test run.
    case developer
}

/// One move of a knob: kept in the table's log, newest last.
public struct KnobChange: Codable, Sendable, Equatable {
    public var knob: String
    public var from: Double
    public var to: Double
    public var by: KnobSetter
    public var why: String
    public var at: Date
}

/// The knobs as set, in `Application Support/Tessera/tess-knobs.json` (excluded from backups). It holds only what was
/// moved and the log of moves; a knob never moved reads as shipped.
public struct KnobTable: Codable, Sendable, Equatable {
    public static let fileName = "tess-knobs.json"
    /// The most moves the log keeps.
    public static let logLimit = 500

    public enum Refusal: String, Error, Sendable {
        case outOfRange = "That is outside the knob's range."
        case loosensAWall = "Only Kaushik can loosen a wall."
        case notWhole = "That knob takes whole numbers."
    }

    public private(set) var values: [String: Double]
    public private(set) var log: [KnobChange]

    public init(values: [String: Double] = [:], log: [KnobChange] = []) {
        self.values = values
        self.log = log
    }

    /// What the knob reads now: its set value when that is still in range, else what it shipped as.
    public func value(_ knob: Knob) -> Double {
        values[knob.id].flatMap { knob.range.contains($0) ? $0 : nil } ?? knob.shipped
    }

    public func int(_ knob: Knob) -> Int {
        Int(value(knob).rounded())
    }

    /// Moves a knob, or says why not. A move to where it already is changes nothing and logs nothing. Moving back to
    /// the shipped value clears it from the file but is logged like any move.
    public mutating func set(_ knob: Knob, to new: Double, by setter: KnobSetter, why: String,
                             at date: Date = .now) throws(Refusal)
    {
        guard knob.range.contains(new) else { throw .outOfRange }
        guard !knob.whole || new == new.rounded() else { throw .notWhole }
        let old = value(knob)
        guard new != old else { return }
        guard setter == .owner || !knob.loosens(from: old, to: new) else { throw .loosensAWall }
        values[knob.id] = new == knob.shipped ? nil : new
        log.append(KnobChange(knob: knob.id, from: old, to: new, by: setter, why: why, at: date))
        if log.count > Self.logLimit {
            log.removeFirst(log.count - Self.logLimit)
        }
    }

    /// Every moved knob back to shipped, each move logged. Walls a reset would loosen stay where he set them.
    public mutating func reset(by setter: KnobSetter, at date: Date = .now) {
        for knob in Knob.all where values[knob.id] != nil {
            try? set(knob, to: knob.shipped, by: setter, why: "reset", at: date)
        }
    }

    public static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "Tessera/\(fileName)")
    }

    /// The stored table, or an empty one (everything shipped) when there is no file or it can't be read.
    public static func load(from url: URL? = defaultURL) -> KnobTable {
        guard let url, let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode(KnobTable.self, from: data) else { return KnobTable() }
        return table
    }

    public func save(to url: URL? = KnobTable.defaultURL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let url, let data = try? encoder.encode(self) else { return }
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
