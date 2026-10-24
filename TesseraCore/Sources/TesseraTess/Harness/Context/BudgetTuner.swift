import Foundation

/// A nightly eval question that came out wrong, traced to a section that should have held the answer.
public struct EvalMiss: Sendable, Equatable {
    public var agent: String
    public var model: BrainID
    public var section: ContextSection

    public init(agent: String, model: BrainID, section: ContextSection) {
        self.agent = agent
        self.model = model
        self.section = section
    }
}

/// One setting of the weekly eval sweep: the eval's score (0...100) with recall started at `recallStart`.
public struct SweepResult: Sendable, Equatable {
    public var agent: String
    public var model: BrainID
    public var recallStart: Int
    public var score: Double

    public init(agent: String, model: BrainID, recallStart: Int, score: Double) {
        self.agent = agent
        self.model = model
        self.recallStart = recallStart
        self.score = score
    }
}

/// One change the tuner made, for Developer mode's Budgets row.
public struct BudgetChange: Sendable, Equatable {
    public var agent: String
    public var model: BrainID
    public var what: String
    public var from: Double
    public var to: Double
    public var why: String
}

/// Moves the sizes every Sunday at 4 am (spec M3), page-fault style, aimed at right answers rather than savings.
///
/// - Faults: an agent that had to open or recall more than 0.3 times per run grows recall's start by half, up to twice
///   the shipped start, and its recall floor drops by 0.05 (never under 0.3), so the pack holds more of what it keeps
///   fetching.
/// - Misses: a nightly eval question missed because a section lacked the answer grows that section's start by half.
/// - Sweep: when the weekly sweep ran, recall's start becomes the smallest setting that scored the best. A section
///   only ever shrinks this way, on an equal score, so accuracy is never traded for size.
/// - Cost is not an input. The $100 cap still stops calls if a bug runs away; it never shapes a size.
public struct BudgetTuner: Sendable {
    public static let faultRate = 0.3
    public static let growth = 1.5
    public static let floorStep = 0.05
    public static let lowestFloor = 0.3
    /// Fewer runs than this in the week says too little to move anything on faults.
    public static let minimumRuns = 5

    public init() {}

    public func tune(_ table: BudgetTable, uses: [ContextUse], misses: [EvalMiss] = [],
                     sweeps: [SweepResult] = []) -> (table: BudgetTable, changes: [BudgetChange])
    {
        var table = table
        var changes: [BudgetChange] = []
        let keys = Set(uses.compactMap { use in BrainID(rawValue: use.model).map { Key(agent: use.agent, model: $0) } })
            .union(misses.map { Key(agent: $0.agent, model: $0.model) })
            .union(sweeps.map { Key(agent: $0.agent, model: $0.model) })

        for key in keys.sorted(by: { ($0.agent, $0.model.rawValue) < ($1.agent, $1.model.rawValue) }) {
            var row = table.row(agent: key.agent, model: key.model)
            let before = row
            let sweep = sweeps.filter { $0.agent == key.agent && $0.model == key.model }

            if let best = sweep.map(\.score).max() {
                let start = sweep.filter { $0.score >= best }.map(\.recallStart).min() ?? row.start(.recall)
                if start != row.start(.recall) {
                    changes.append(.init(agent: key.agent, model: key.model, what: "recall start",
                                         from: Double(row.start(.recall)), to: Double(start),
                                         why: "the smallest setting with the best eval score"))
                    row.starts[.recall] = start
                }
            } else {
                let runs = uses.filter { $0.agent == key.agent && $0.model == key.model.rawValue }
                let runCount = Set(runs.map(\.runID)).count
                let faults = runs.reduce(0) { $0 + $1.opens.count + $1.recalls }
                if runCount >= Self.minimumRuns, Double(faults) / Double(runCount) > Self.faultRate {
                    let grown = Self.grow(row.start(.recall), ceiling: BudgetRow.ceiling(.recall, model: key.model))
                    if grown != row.start(.recall) {
                        changes.append(.init(agent: key.agent, model: key.model, what: "recall start",
                                             from: Double(row.start(.recall)), to: Double(grown),
                                             why: "it kept fetching what the pack didn't hold"))
                        row.starts[.recall] = grown
                    }
                    let floor = max(Self.lowestFloor, ((row.recallFloor - Self.floorStep) * 100).rounded() / 100)
                    if floor != row.recallFloor {
                        changes.append(.init(agent: key.agent, model: key.model, what: "recall floor",
                                             from: row.recallFloor, to: floor, why: "let more related things in"))
                        row.recallFloor = floor
                    }
                }
            }

            let missed = Set(misses.filter { $0.agent == key.agent && $0.model == key.model }.map(\.section))
            for section in ContextSection.allCases where missed.contains(section) {
                // Expertise is never trimmed and holds its whole pack, so a miss there is a recipe fix, not a size.
                guard section != .expertise else { continue }
                if section == .recall, row.start(.recall) != before.start(.recall) { continue }
                let grown = Self.grow(row.start(section), ceiling: BudgetRow.ceiling(section, model: key.model))
                guard grown != row.start(section) else { continue }
                changes.append(.init(agent: key.agent, model: key.model, what: "\(section.rawValue) start",
                                     from: Double(row.start(section)), to: Double(grown),
                                     why: "an eval question was missed for want of it"))
                row.starts[section] = grown
            }

            if row != before {
                table.set(row, agent: key.agent, model: key.model)
            }
        }
        return (table, changes)
    }

    /// Half again, at least 1,000 tokens, never past `ceiling` (and never down, if a sweep already set it higher).
    /// A section that ships with a start of 0 never grows: its ceiling is twice 0. Give it a start to let it grow.
    static func grow(_ start: Int, ceiling: Int) -> Int {
        max(start, min(ceiling, max(1000, Int((Double(start) * growth).rounded()))))
    }

    private struct Key: Hashable {
        var agent: String
        var model: BrainID
    }
}
