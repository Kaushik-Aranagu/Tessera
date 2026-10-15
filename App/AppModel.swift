import Foundation
import Observation
import SwiftData
import SwiftUI
import TesseraCore

/// Something you can navigate to: every name in the UI is a handle to one of these.
enum Route: Hashable {
    case object(UUID)
    case classDef(UUID)
}

/// One row of the day's schedule.
struct ScheduleItem: Identifiable, Equatable {
    enum Status: String {
        case done = "DONE", now = "NOW", boarding = "BOARDING", soon = "SOON", later = "LATER"
    }

    let id: UUID
    let title: String
    let start: Date
    let end: Date
    let isDone: Bool
    let isWorkout: Bool

    func status(at now: Date) -> Status {
        if isDone || end < now && !isWorkout {
            return .done
        }
        if start <= now, now < end {
            return .now
        }
        let minutes = start.timeIntervalSince(now) / 60
        if minutes <= 15 {
            return .boarding
        }
        if minutes <= 90 {
            return .soon
        }
        return .later
    }
}

@MainActor
@Observable
final class AppModel {
    let context: ModelContext
    let store: ObjectStore
    private(set) var classes: [SystemCatalog.Key: ClassDef] = [:]

    /// Bumped after writes so views re-read derived data.
    private(set) var revision = 0
    /// Pages above Today.
    var path: [Route] = []
    /// How each pushed page arrives: zoom out of the tapped row (deeper) or cross-fade (jump / up).
    @ObservationIgnored private(set) var arrivals: [Route: Arrival] = [:]
    /// Pages already seen this session — their entrance choreography only plays on the first visit.
    @ObservationIgnored private var visited: Set<Route> = []
    var hasRevealedGreeting = false
    var session: WorkoutSession?
    var isWorkoutPresented = false
    var commandDraft = ""
    var isCommandExpanded = false

    init(context: ModelContext) {
        self.context = context
        store = ObjectStore(context: context)
        do {
            classes = try SystemCatalog.seed(in: context)
        } catch {
            assertionFailure("Seeding failed: \(error)")
        }
    }

    // MARK: Navigation

    enum Relation {
        /// Into a child, subclass or linked object from a tapped row: zooms out of that row.
        case deeper
        /// To an ancestor (breadcrumbs): pops back if it's on the path, otherwise cross-fades in.
        case up
        /// A jump that isn't spatial (search, Tess, links elsewhere): cross-fade.
        case jump
    }

    enum Arrival { case zoom, crossFade }

    func open(_ route: Route, _ relation: Relation = .deeper) {
        guard route != path.last else { return }
        switch relation {
        case .deeper:
            arrivals[route] = .zoom
            path.append(route)
        case .jump:
            arrivals[route] = .crossFade
            path.append(route)
        case .up:
            if let index = path.firstIndex(of: route) {
                path.removeSubrange((index + 1)...)
            } else {
                arrivals[route] = .crossFade
                path.append(route)
            }
        }
    }

    func back() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// True the first time a page is shown this session (then it's marked as seen).
    func consumeFirstVisit(_ route: Route?) -> Bool {
        let key = route ?? .object(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        return visited.insert(key).inserted
    }

    func title(of route: Route) -> String {
        switch route {
        case let .object(id): object(id)?.title ?? "Object"
        case let .classDef(id): classDef(id: id)?.name ?? "Class"
        }
    }

    func classDef(_ key: SystemCatalog.Key) -> ClassDef? {
        classes[key]
    }

    func touch() {
        try? context.save()
        revision += 1
    }

    // MARK: Lookup

    func object(_ id: UUID) -> ObjectRecord? {
        try? context.fetch(FetchDescriptor<ObjectRecord>(predicate: #Predicate { $0.id == id })).first
    }

    func classDef(id: UUID) -> ClassDef? {
        try? context.fetch(FetchDescriptor<ClassDef>(predicate: #Predicate { $0.id == id })).first
    }

    func objects(of key: SystemCatalog.Key) -> [ObjectRecord] {
        guard let classID = classes[key]?.id else { return [] }
        let descriptor = FetchDescriptor<ObjectRecord>(
            predicate: #Predicate { $0.classDef?.id == classID && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// The "profile" object of a class: holds class-level values like Bench Press's muscles and cues.
    func prototype(of classDef: ClassDef) -> ObjectRecord? {
        (classDef.objects ?? []).first { $0.parent == nil && $0.title == classDef.name && !$0.isDeleted }
    }

    // MARK: Today

    /// Derived schedule, rebuilt only when data changes (or the window drifts by a minute) — the
    /// once-a-second UI ticks must stay far under a frame.
    @ObservationIgnored private var scheduleCache: (revision: Int, anchor: Date, items: [ScheduleItem])?
    @ObservationIgnored private var workoutCache: (revision: Int, anchor: Date, workout: ObjectRecord?)?

    func schedule(around now: Date = AppClock.now) -> [ScheduleItem] {
        let revision = revision
        if let cache = scheduleCache, cache.revision == revision, abs(cache.anchor.timeIntervalSince(now)) < 60 {
            return cache.items
        }
        let items = buildSchedule(around: now)
        scheduleCache = (revision, now, items)
        return items
    }

    private func buildSchedule(around now: Date) -> [ScheduleItem] {
        let window = now.addingTimeInterval(-14 * 3600) ... now.addingTimeInterval(12 * 3600)
        var items: [ScheduleItem] = objects(of: .task).compactMap { task in
            guard case let .date(start)? = store.value("startsAt", of: task), window.contains(start) else { return nil }
            let length = store.value("length", of: task)?.numericValue ?? 1800
            let done = store.value("isDone", of: task) == .bool(true)
            return ScheduleItem(id: task.id, title: task.title, start: start, end: start.addingTimeInterval(length),
                                isDone: done, isWorkout: false)
        }
        if let workout = tonightWorkout(around: now),
           case let .date(start)? = store.value("scheduledFor", of: workout)
        {
            items.append(ScheduleItem(id: workout.id, title: workout.title, start: start,
                                      end: start.addingTimeInterval(75 * 60), isDone: false, isWorkout: true))
        }
        return items.sorted { $0.start < $1.start }
    }

    /// The task happening now, else the next one not done.
    func currentTask(around now: Date = AppClock.now) -> ScheduleItem? {
        let items = schedule(around: now).filter { !$0.isWorkout && !$0.isDone }
        return items.first { $0.start <= now && now < $0.end } ?? items.first { $0.start > now }
    }

    func tonightWorkout(around now: Date = AppClock.now) -> ObjectRecord? {
        let revision = revision
        if let cache = workoutCache, cache.revision == revision, abs(cache.anchor.timeIntervalSince(now)) < 60 {
            return cache.workout
        }
        let workout = findTonightWorkout(around: now)
        workoutCache = (revision, now, workout)
        return workout
    }

    private func findTonightWorkout(around now: Date) -> ObjectRecord? {
        objects(of: .workout).first { workout in
            guard case let .date(date)? = store.value("scheduledFor", of: workout) else { return false }
            return store.value("endedAt", of: workout) == nil && abs(date.timeIntervalSince(now)) < 12 * 3600
        }
    }

    func finish(taskID: UUID) {
        guard let task = object(taskID) else { return }
        try? store.set("isDone", to: .bool(true), on: task)
        touch()
    }

    // MARK: Workout

    func startWorkout(_ workout: ObjectRecord) {
        if session?.workout.id != workout.id {
            if store.value("startedAt", of: workout) == nil {
                try? store.set("startedAt", to: .date(AppClock.now), on: workout)
            }
            session = WorkoutSession(workout: workout, model: self)
        }
        isWorkoutPresented = true
        touch()
    }

    func endWorkout() {
        guard let session else { return }
        try? store.set("endedAt", to: .date(AppClock.now), on: session.workout)
        isWorkoutPresented = false
        self.session = nil
        touch()
    }

    // MARK: Training stats

    struct LoggedSet {
        let weight: Double
        let reps: Double
        let e1RM: Double
    }

    struct SessionSummary: Identifiable {
        let id: UUID
        let workout: ObjectRecord
        let date: Date
        let sets: [LoggedSet]
    }

    /// Completed sessions for an exercise class (and its subclasses), newest first.
    func history(of exercise: ClassDef) -> [SessionSummary] {
        _ = revision
        let workoutClass = classes[.workout]
        return store.backlinks(to: exercise, includingSubclasses: true).compactMap { entry in
            guard let workoutClass, let workout = store.ancestor(of: entry, ofClass: workoutClass),
                  case let .date(date)? = store.value("endedAt", of: workout) ?? store.value("startedAt", of: workout)
            else { return nil }
            let sets = entry.orderedChildren.compactMap { set -> LoggedSet? in
                guard let weight = store.number("weight", of: set), let reps = store.number("reps", of: set),
                      let e1RM = store.number("e1rm", of: set) else { return nil }
                return LoggedSet(weight: weight, reps: reps, e1RM: e1RM)
            }
            guard !sets.isEmpty else { return nil }
            return SessionSummary(id: entry.id, workout: workout, date: date, sets: sets)
        }
        .sorted { $0.date > $1.date }
    }

    func bestSet(of exercise: ClassDef, excludingWorkout excludedID: UUID? = nil) -> LoggedSet? {
        history(of: exercise)
            .filter { $0.workout.id != excludedID }
            .flatMap(\.sets)
            .max { $0.e1RM < $1.e1RM }
    }

    /// Evaluates the Set class's own `e1rm` expression for values that aren't logged yet.
    func previewE1RM(weight: Double, reps: Double) -> Double? {
        guard let setClass = classes[.set], let source = ClassResolver.field("e1rm", of: setClass)?.expression,
              let expression = try? Formula.parse(source) else { return nil }
        return expression.evaluate { ["weight": weight, "reps": reps][$0] }
    }
}
