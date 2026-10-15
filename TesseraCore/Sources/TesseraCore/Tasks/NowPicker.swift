import Foundation

/// What Now shows, and what's next. One ranker (`NowPicker.rank`, `NowRanker.swift`) so Home and Now never disagree:
/// a running process, then a timed task within 15 minutes, then a planned rest day, then re-entry, then the scored
/// rank (docs/research/context-packing.md §5, fixtures in docs/research/fixtures/ranker.md). `pick` reads it.
public struct NowItem: Identifiable {
    public enum Kind: String, Sendable {
        case process, task, workout
        /// The quiet "Rest day" line; `object` is the next routine, one tap away.
        case rest
        /// An offer such as Shop; `object` is what it opens.
        case offer
    }

    public let id: UUID
    public let kind: Kind
    /// The task or workout itself (for a process, its subject).
    public let object: ObjectRecord
    public let title: String
    /// When it starts (timed items), else nil.
    public let startsAt: Date?
    /// When it ends, for Now's draining bar: start + length for tasks, nil when open-ended.
    public let endsAt: Date?
    /// For processes: the one-line next step.
    public let nextStep: String?
}

@MainActor
public struct NowPicker {
    public let engine: ActionEngine

    public init(engine: ActionEngine) {
        self.engine = engine
    }

    var store: ObjectStore {
        engine.store
    }

    /// Now, then up to `count` next items: the ranker's first pick and the ones after it.
    public func pick(at now: Date = .now, next count: Int = 3,
                     calendar: Calendar = .current) -> (now: NowItem?, next: [NowItem])
    {
        let picks = rank(RankContext(now: now, calendar: calendar))
        return (picks.first?.item, picks.dropFirst().prefix(count).map(\.item))
    }

    /// The running process as Now's item. Cooking: the soonest timer is Now's draining bar and its line
    /// ("Pasta, 6 min").
    func runningItem(at now: Date) -> NowItem? {
        guard let running = ProcessTable(engine: engine).running(), let subject = running.subject else { return nil }
        let timer = CookLog(store: store, classes: engine.classes).timers()
            .first { $0.cook?.id == subject.id && $0.endsAt > now }
        return NowItem(
            id: subject.id,
            kind: .process,
            object: subject,
            title: store.displayTitle(of: subject),
            startsAt: timer?.startedAt ?? running.startedAt,
            endsAt: timer?.endsAt,
            nextStep: timer.map { "\($0.label), \(Int(($0.remaining(at: now) / 60).rounded(.up))) min" }
                ?? running.nextStep
        )
    }
}
