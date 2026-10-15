import Foundation

/// The kernel's process table: what's running, the Home ledger, and the stale rules.
@MainActor
public struct ProcessTable {
    public enum Limits {
        /// Rows under Now on Home.
        public static let ledgerRows = 3
        /// Suspended and untouched this long: leaves Home for the full list.
        public static let leavesHome: TimeInterval = 3 * 86400
        /// Untouched this long: put away to Later.
        public static let putAway: TimeInterval = 7 * 86400
        /// A suspended workout this old is wrapped up with what was logged.
        public static let wrapUpWorkout: TimeInterval = 6 * 3600
    }

    public let engine: ActionEngine

    public init(engine: ActionEngine) {
        self.engine = engine
    }

    private var store: ObjectStore {
        engine.store
    }

    // MARK: Queries

    /// Every process, newest touch first.
    public func all() -> [ProcessSnapshot] {
        guard let processClass = engine.classes[.process] else { return [] }
        return store.objects(of: processClass)
            .map { ProcessSnapshot($0, store: store) }
            .sorted { ($0.lastTouchedAt ?? .distantPast) > ($1.lastTouchedAt ?? .distantPast) }
    }

    /// The one running process. It is Now.
    public func running() -> ProcessSnapshot? {
        all().first { $0.state == .running }
    }

    /// Home's ledger under Now: suspended processes touched in the last 3 days, then waiting ones whose check
    /// time has passed. At most 3; the running process is shown as Now, not here.
    /// The workout in progress: the running one, else the most recent one set aside.
    public func openWorkout(now _: Date = .now) -> ProcessSnapshot? {
        if let running = running(), let subject = running.subject, isWorkout(subject) {
            return running
        }
        return all().filter { $0.state == .suspended && ($0.subject.map(isWorkout) ?? false) }
            .max { ($0.lastTouchedAt ?? .distantPast) < ($1.lastTouchedAt ?? .distantPast) }
    }

    public func ledger(now: Date = .now) -> [ProcessSnapshot] {
        let processes = all()
        let suspended = processes.filter { $0.state == .suspended && $0.idle(at: now) < Limits.leavesHome }
        let due = processes.filter { $0.state == .waiting && ($0.checkAt.map { $0 <= now } ?? false) }
        return Array((suspended + due).prefix(Limits.ledgerRows))
    }

    /// Open processes not on Home (the full list one level deeper).
    public func fullList(now: Date = .now) -> [ProcessSnapshot] {
        let onHome = Set(ledger(now: now).map(\.id) + [running()?.id].compactMap(\.self))
        return all().filter { $0.state.isOpen && !onHome.contains($0.id) }
    }

    /// Put-away processes (Later).
    public func later() -> [ProcessSnapshot] {
        all().filter { $0.state == .putAway }
    }

    public func process(for subject: ObjectRecord) -> ProcessSnapshot? {
        all().first { $0.subject?.id == subject.id && $0.state.isOpen }
    }

    /// The last 3 actions on the subject, for the process page's trail.
    public func trail(of process: ProcessSnapshot, limit: Int = 3) -> [OpRecord] {
        guard let subject = process.subject else { return [] }
        return engine.history(of: subject.id, limit: limit)
    }

    // MARK: Housekeeping

    /// Suspends the running process if it has been idle longer than `idleLimit`
    /// (the rest time plus 10 minutes while backgrounded). Returns the suspended process.
    @discardableResult
    public func suspendIfIdle(now: Date = .now, idleLimit: TimeInterval) -> ProcessSnapshot? {
        // Only workouts go idle this way (the rest-based limit means nothing for a shop, a cook or a task).
        guard let running = running(), let subject = running.subject, isWorkout(subject),
              running.idle(at: now) > idleLimit else { return nil }
        _ = try? engine.perform(SuspendProcess(process: running.id, time: running.lastTouchedAt), by: .system)
        return running
    }

    /// Applies the stale rules and returns Tess's one-line notes for what changed. Run on launch and foreground.
    @discardableResult
    public func tidy(now: Date = .now) -> [String] {
        var notes: [String] = []
        var putAway = 0
        for process in all() where process.state == .suspended {
            let idle = process.idle(at: now)
            if let workout = process.subject, isWorkout(workout), idle >= Limits.wrapUpWorkout {
                notes.append(wrapUp(process, workout: workout))
            } else if idle >= Limits.putAway {
                if (try? engine.perform(EndProcess(process: process.id, reason: .putAway, time: now), by: .system)) !=
                    nil
                {
                    putAway += 1
                }
            }
        }
        if putAway > 0 {
            notes.append("Put \(putAway == 1 ? "one thing" : "\(spelled(putAway)) things") away. They're in Later.")
        }
        return notes
    }

    private func isWorkout(_ object: ObjectRecord) -> Bool {
        guard let workoutClass = engine.classes[.workout], let classDef = object.classDef else { return false }
        return ClassResolver.isSubclass(classDef, of: workoutClass)
    }

    private func wrapUp(_ process: ProcessSnapshot, workout: ObjectRecord) -> String {
        let end = process.lastTouchedAt ?? .now
        _ = try? engine.perform(FinishWorkout(workout: workout.id, time: end), by: .system)
        _ = try? engine.perform(EndProcess(process: process.id, reason: .wrappedUp, time: end), by: .system)
        let entries = workout.orderedChildren
        let started = entries.count { !$0.orderedChildren.isEmpty }
        return "Saved \(store.displayTitle(of: workout)), \(started) of \(entries.count) exercises"
    }

    private func spelled(_ number: Int) -> String {
        let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
        return number < words.count ? words[number] : String(number)
    }
}
