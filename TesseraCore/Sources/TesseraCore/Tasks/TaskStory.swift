import Foundation

/// A task's story, read from the op log (Research drawn-sides-acceptance, section 5, Q4 to Q6). The side page draws it;
/// this only counts and orders.
///
/// - A **move** is `moveTask` by `.user`, `.tess` or `.intent` (a move asked through Tess or Siri is still his ask).
/// - The nightly roll (`rollForwardTasks`, `.system`) is "rolled", never a move.
/// - Plan my day's keep (`keepPlannedTask`, any actor) is "planned", never a move.
/// - Undone records and Tess's pending previews are not part of the story.
@MainActor
public struct TaskStory {
    public enum Event: Equatable, Sendable {
        /// When it was made.
        case made(Date)
        /// A hand move, to a time (nil: to Later).
        case moved(to: Date?, at: Date)
        /// The nightly roll, into a day.
        case rolled(into: Date?, at: Date)
        /// Kept in Plan my day, for a time.
        case planned(for: Date?, at: Date)
        /// Marked done.
        case done(Date)

        public var date: Date {
            switch self {
            case let .made(date), let .done(date): date
            case let .moved(_, at), let .rolled(_, at), let .planned(_, at): at
            }
        }
    }

    /// Oldest first.
    public let events: [Event]

    /// Hand moves. Rolls and keeps never count.
    public var moves: Int {
        events.count {
            if case .moved = $0 {
                true
            } else {
                false
            }
        }
    }

    /// Nights the roll moved it by itself.
    public var rolls: Int {
        events.count {
            if case .rolled = $0 {
                true
            } else {
                false
            }
        }
    }

    /// Times it was kept in Plan my day.
    public var plannedCount: Int {
        events.count {
            if case .planned = $0 {
                true
            } else {
                false
            }
        }
    }

    /// Whether it was ever kept in Plan my day ("in Plan my day").
    public var isInPlan: Bool {
        plannedCount > 0
    }

    /// When it was made ("made Tuesday").
    public var madeAt: Date? {
        events.lazy.compactMap {
            if case let .made(date) = $0 {
                date
            } else {
                nil
            }
        }.first
    }

    /// When it was marked done, if it still is.
    public var doneAt: Date? {
        events.lazy.compactMap {
            if case let .done(date) = $0 {
                date
            } else {
                nil
            }
        }.last
    }

    /// Who counts as a move.
    static let handActors: Set<Actor> = [.user, .tess, .intent]

    public init(of task: ObjectRecord, engine: ActionEngine) {
        let store = engine.store
        let startsAt = task.classDef.flatMap { store.field("startsAt", of: $0)?.id }
        var events: [Event] = [.made(task.createdAt)]
        for record in engine.history(of: task.id, limit: .max)
            where record.state == .committed
        {
            let target = Self.startsAt(in: record, task: task.id, field: startsAt)
            switch (record.action, record.actor) {
            case let ("moveTask", actor) where Self.handActors.contains(actor):
                events.append(.moved(to: target, at: record.createdAt))
            case ("keepPlannedTask", _):
                events.append(.planned(for: target, at: record.createdAt))
            case ("rollForwardTasks", .system):
                events.append(.rolled(into: target, at: record.createdAt))
            default:
                break
            }
        }
        if store.value("isDone", of: task) == .bool(true) {
            events.append(.done(store.value("doneAt", of: task)?.dateValue ?? task.updatedAt))
        }
        // Stable: ties keep op order, with "made" first.
        self.events = events.enumerated()
            .sorted { ($0.element.date, $0.offset) < ($1.element.date, $1.offset) }
            .map(\.element)
    }

    /// The `startsAt` an action left on the task (nil when it cleared it: Later).
    private static func startsAt(in record: OpRecord, task: UUID, field: UUID?) -> Date? {
        guard let field else { return nil }
        for case let .setValue(object, id, _, new) in record.ops where object == task && id == field {
            return new?.dateValue
        }
        return nil
    }
}
