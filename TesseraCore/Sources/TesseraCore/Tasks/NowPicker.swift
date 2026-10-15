import Foundation

/// What Now shows, and what's next (M2 slice 4). One rule, so Home never shows two "next things":
/// 1. the running process (a workout or task in progress);
/// 2. else the current or next timed item today: a task with a start time, or a scheduled workout;
/// 3. else the top of today's task list (carried-over first, then undated today).
/// The next three follow in the same order, without repeating Now.
public struct NowItem: Identifiable {
    public enum Kind: String, Sendable {
        case process, task, workout
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

    private var store: ObjectStore {
        engine.store
    }

    /// Now, then up to `count` next items.
    public func pick(at now: Date = .now, next count: Int = 3,
                     calendar: Calendar = .current) -> (now: NowItem?, next: [NowItem])
    {
        var queue: [NowItem] = []
        if let running = ProcessTable(engine: engine).running(), let subject = running.subject {
            queue.append(NowItem(
                id: subject.id,
                kind: .process,
                object: subject,
                title: store.displayTitle(of: subject),
                startsAt: running.startedAt,
                endsAt: nil,
                nextStep: running.nextStep
            ))
        }
        queue += timedItems(at: now, calendar: calendar)
        queue += untimedToday(at: now, calendar: calendar)
        var seen = Set<UUID>()
        let unique = queue.filter { seen.insert($0.id).inserted }
        return (unique.first, Array(unique.dropFirst().prefix(count)))
    }

    /// Today's tasks with a start time that haven't ended yet, and today's scheduled workouts not yet finished,
    /// by start time. Something that has started and is still within its length comes first.
    private func timedItems(at now: Date, calendar: Calendar) -> [NowItem] {
        guard let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return [] }
        var items: [NowItem] = []
        let tasks = TaskList(store: store, classes: engine.classes).today(now, calendar: calendar)
        for item in tasks where !item.isDone && !item.isCarriedOver {
            guard let start = store.value("startsAt", of: item.task)?.dateValue, start < end else { continue }
            let finish = item.minutes.map { start.addingTimeInterval($0 * 60) }
            guard (finish ?? start) >= now || start >= now else { continue }
            items.append(NowItem(id: item.id, kind: .task, object: item.task, title: item.title, startsAt: start,
                                 endsAt: finish, nextStep: nil))
        }
        if let workoutClass = engine.classes[.workout] {
            for workout in store.objects(of: workoutClass) {
                guard store.value("endedAt", of: workout) == nil,
                      let scheduled = store.value("scheduledFor", of: workout)?.dateValue,
                      calendar.isDate(scheduled, inSameDayAs: now) else { continue }
                items.append(NowItem(id: workout.id, kind: .workout, object: workout,
                                     title: store.displayTitle(of: workout), startsAt: scheduled, endsAt: nil,
                                     nextStep: nil))
            }
        }
        return items.sorted { ($0.startsAt ?? .distantFuture) < ($1.startsAt ?? .distantFuture) }
    }

    /// The rest of today's list: carried-over tasks first, then today's without a time.
    private func untimedToday(at now: Date, calendar: Calendar) -> [NowItem] {
        TaskList(store: store, classes: engine.classes).today(now, calendar: calendar)
            .filter { !$0.isDone && ($0.isCarriedOver || store.value("startsAt", of: $0.task) == nil) }
            .sorted { $0.isCarriedOver && !$1.isCarriedOver }
            .map { NowItem(id: $0.id, kind: .task, object: $0.task, title: $0.title, startsAt: nil, endsAt: nil,
                           nextStep: nil) }
    }
}
