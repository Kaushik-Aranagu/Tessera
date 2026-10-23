import Foundation

/// Her last turn, as the opener needs it: when it was, and which objects it named. Ids and a time only: no words.
public struct TessLastTurn: Equatable, Sendable {
    public let at: Date
    public let about: [UUID]

    public init(at: Date, about: [UUID]) {
        self.at = at
        self.about = about
    }
}

/// The line she opens with when her layer opens, and at most three plain replies (sheet 215 rev 5). Made on the phone
/// and never sent to Claude unless asksClaude, which this does not use at all.
public struct TessOpening: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        /// Something she named has changed since her last turn.
        case sinceThen(UUID)
        /// The newest Today notice.
        case notice
    }

    public let line: String
    public let replies: [String]
    public let source: Source
}

@MainActor
public enum TessOpener {
    public static let maxReplies = 3

    /// The opening, or nil when it is quiet (quiet hours, or "quiet for an hour") or there is nothing to say.
    ///
    /// Rules, in order:
    /// 1. Quiet hours or a quiet hour: nothing.
    /// 2. Compare the objects named in her last turn with the op log since that turn. Only whether one changed, and its
    ///    shown label now, are read: never a value. If it changed (and she did not make the change herself), say
    ///    "Since then, X changed." with a conflict when another thing of the day runs into it.
    /// 3. If the changed object is money, health, body, calorie or calendar: no "Since then" line at all, not even a
    ///    neutral one; the newest Today notice opens instead.
    /// 4. Otherwise the newest Today notice.
    /// The line never offers an action on money and is judged by the walls like every line she stores.
    public static func opening(engine: ActionEngine, facts: MosaicFacts, plan: ObjectRecord?, lastTurn: TessLastTurn?,
                               quiet: QuietHours, quietUntil: Date? = nil, events: [HandsEvent] = [],
                               routines: HomeSentence.RoutinesPart? = nil, calendar: Calendar = .current)
        -> TessOpening?
    {
        let now = facts.now
        if quiet.contains(now, calendar: calendar) || (quietUntil.map { $0 > now } ?? false) {
            return nil
        }
        let store = engine.store, classes = engine.classes
        if let lastTurn, let changed = firstChange(since: lastTurn, engine: engine) {
            // Money, health, body, calorie and calendar: no "Since then" at all.
            if !TessAskRouter.isUnnameable(changed, classes: classes) {
                let name = shownName(changed, store: store, classes: classes)
                let conflict = conflictLine(for: name, in: events, now: now)
                let line = (["Since then, \(name) changed."] + (conflict.map { [$0] } ?? [])).joined(separator: " ")
                if passes(line, store: store) {
                    let replies = conflict == nil ? ["Show me", "Fine as it is"] : [
                        "Move it later",
                        "Leave it",
                        "Not now",
                    ]
                    return TessOpening(line: line, replies: Array(replies.prefix(maxReplies)),
                                       source: .sinceThen(changed.id))
                }
            }
        }
        guard let notice = HomeNotices.ranked(engine: engine, facts: facts, plan: plan, routines: routines,
                                              calendar: calendar, limit: 1).first,
            passes(notice.text, store: store) else { return nil }
        return TessOpening(line: notice.text, replies: ["Show me", "Not now"], source: .notice)
    }

    // MARK: Pieces

    /// The first object she named that has a change in the op log after her turn. Only the fact of a change is read.
    /// A change she made herself (an op by Tess) is hers, not news.
    static func firstChange(since turn: TessLastTurn, engine: ActionEngine) -> ObjectRecord? {
        for id in turn.about {
            guard let object = engine.store.object(id: id) else { continue }
            let changed = engine.history(of: id, limit: 50).contains { record in
                record.createdAt > turn.at && record.state == .committed && record.actor != .system
                    && record.actor != .tess
            }
            if changed || object.isDeleted {
                return object
            }
        }
        return nil
    }

    static func shownName(_ object: ObjectRecord, store: ObjectStore,
                          classes: [SystemCatalog.Key: ClassDef]) -> String
    {
        if let label = ObjectPrivacy.shownLabel(of: object, in: store, classes: classes) {
            return label
        }
        return AppSummaryLines.shown(object.title, in: store, classes: classes, of: object).text
    }

    /// "Stretch may run into it." when another timed thing of the day overlaps the changed one. Names only, no times.
    static func conflictLine(for name: String, in events: [HandsEvent], now: Date) -> String? {
        guard let mine = events.first(where: { $0.label == name && $0.end > now }) else { return nil }
        let other = events.first { event in
            event.label != name && event.end > now && event.start < mine.end && event.end > mine.start
        }
        return other.map { "\($0.label) may run into it." }
    }

    /// The walls, for a line she is about to say and store.
    static func passes(_ line: String, store: ObjectStore) -> Bool {
        !(SecretWords.mentions(line) || PrivateFacts.isWalled(line, lastWeightKg: BodyWeight.lastKg(in: store))
            || PrivateFacts.isCalorieShaped(line))
    }
}
