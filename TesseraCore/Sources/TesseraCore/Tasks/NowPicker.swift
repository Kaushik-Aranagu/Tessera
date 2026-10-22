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

    /// Now, then up to `count` next items: the ranker's first pick and the ones after it. It fills the whole context
    /// (last action and days away from the op log) so no caller gets a context-free pick (QA N2).
    public func pick(at now: Date = .now, next count: Int = 3, plan: ObjectRecord? = nil,
                     sessionsPerWeek: Int? = nil, incumbent: UUID? = nil,
                     calendar: Calendar = .current) -> (now: NowItem?, next: [NowItem])
    {
        let picks = rank(RankContext(now: now, calendar: calendar, plan: plan, sessionsPerWeek: sessionsPerWeek,
                                     incumbent: incumbent, lastAction: lastAction(),
                                     daysAway: max(0, daysAway(at: now, calendar: calendar))))
        return (picks.first?.item, picks.dropFirst().prefix(count).map(\.item))
    }

    /// The running process as Now's item. Cooking: the soonest timer is Now's draining bar and its line
    /// ("Pasta, 6 min").
    func runningItem(at now: Date) -> NowItem? {
        guard let running = ProcessTable(engine: engine).running(), let subject = running.subject else {
            return sessionItem(at: now)
        }
        let timer = CookLog(store: store, classes: engine.classes).timers()
            .first { $0.cook?.id == subject.id && $0.endsAt > now }
        // The lock screen's rule: a private word, or any timer of a private recipe's cook, is just "Timer" here.
        let timerName = timer
            .map { KitchenTimerAlerts.hidesLabel($0.label, cook: subject, in: store) ? "Timer" : $0.label }
        return NowItem(
            id: subject.id,
            kind: .process,
            object: subject,
            title: store.displayTitle(of: subject),
            startsAt: timer?.startedAt ?? running.startedAt,
            endsAt: timer?.endsAt,
            nextStep: timer.map { "\(timerName ?? $0.label), \(Int(($0.remaining(at: now) / 60).rounded(.up))) min" }
                ?? running.nextStep
        )
    }

    /// A multi-dish cook under way is Now when no process is: "Cooking A and B, 12 min left. Go on." The soonest timer
    /// drains the bar, as for a single cook. Private dishes read "Private recipe".
    func sessionItem(at now: Date) -> NowItem? {
        let book = CookSessionBook(store: store, classes: engine.classes)
        guard let session = book.sessions().filter({ book.status(of: $0) == "running" })
            .max(by: { $0.createdAt < $1.createdAt }),
            let live = book.live(of: session, now: now) else { return nil }
        return NowItem(id: session.id, kind: .process, object: session, title: live.title,
                       startsAt: store.value("startedAt", of: session)?.dateValue, endsAt: live.soonestEndsAt,
                       nextStep: live.line)
    }
}
