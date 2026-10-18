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
        /// A running shop untouched this long (overnight) is suspended as the system, basket kept (G44).
        public static let idleShop: TimeInterval = 12 * 3600
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

    /// The workout in progress: the running one, else the most recent one set aside.
    public func openWorkout() -> ProcessSnapshot? {
        if let running = running(), let subject = running.subject, isWorkout(subject) {
            return running
        }
        return all().filter { $0.state == .suspended && ($0.subject.map(isWorkout) ?? false) }
            .max { ($0.lastTouchedAt ?? .distantPast) < ($1.lastTouchedAt ?? .distantPast) }
    }

    /// Home's ledger under Now: suspended processes touched in the last 3 days, then waiting ones whose check
    /// time has passed. At most 3; the running process is shown as Now, not here.
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

    /// Suspends the running process if it has been idle: a workout longer than `idleLimit` (the rest time plus
    /// 10 minutes while backgrounded), a shop or a list run longer than `Limits.idleShop` (G44; checking
    /// a row resets the clock). A shop or a run keeps its basket. Returns the suspended process.
    @discardableResult
    public func suspendIfIdle(now: Date = .now, idleLimit: TimeInterval) -> ProcessSnapshot? {
        guard let running = running(), let subject = running.subject else { return nil }
        let limit: TimeInterval
        if isWorkout(subject) {
            limit = idleLimit
        } else if subject.id == Groceries.listID || isList(subject) {
            // The rest-based limit means nothing for a shop or a list run; they have their own.
            limit = Limits.idleShop
        } else {
            return nil
        }
        guard running.idle(at: now) > limit else { return nil }
        _ = try? engine.perform(SuspendProcess(process: running.id, time: running.lastTouchedAt), by: .system)
        return running
    }

    /// Applies the stale rules and returns Tess's one-line notes for what changed. Run on launch and foreground.
    @discardableResult
    public func tidy(now: Date = .now) -> [String] {
        tidyNotes(now: now).map(\.line)
    }

    /// One overnight line, and the record its UNDO takes back (only the empty wrap-up has one: "Push A, no sets, not
    /// saved." brings the workout back). Generic Undo skips system writes, so the record travels with the line.
    public struct Note: Sendable {
        public let line: String
        public let undo: OpRecord?
    }

    public func tidyNotes(now: Date = .now) -> [Note] {
        var notes: [Note] = []
        var putAway = 0
        var shopNotes: [Note] = []
        for process in all() where process.state == .suspended {
            let idle = process.idle(at: now)
            if let workout = process.subject, isWorkout(workout), idle >= Limits.wrapUpWorkout {
                notes.append(wrapUp(process, workout: workout))
            } else if idle >= Limits.putAway {
                let basket = basketOf(process)
                if (try? engine.perform(EndProcess(process: process.id, reason: .putAway, time: now), by: .system)) !=
                    nil
                {
                    if let basket, basket.count > 0 {
                        shopNotes.append(Note(line: "\(basket.name) moved to Later. \(basket.count) in the basket.",
                                              undo: nil))
                    } else {
                        putAway += 1
                    }
                }
            }
        }
        notes += shopNotes
        if putAway > 0 {
            let things = putAway == 1 ? "One thing" : "\(spelled(putAway).capitalized) things"
            notes.append(Note(line: "\(things) moved to Later.", undo: nil))
        }
        return notes
    }

    /// The checked rows in the basket of a shop or a list run, with the name the note uses; nil when the process is
    /// neither. Rows are never dropped. A walled list name reads "Private list".
    private func basketOf(_ process: ProcessSnapshot) -> (name: String, count: Int)? {
        guard let subject = process.subject else { return nil }
        if subject.id == Groceries.listID {
            return ("Shopping", ListContents.basketCount(of: subject, in: store))
        }
        guard isList(subject) else { return nil }
        let name = ObjectPrivacy.isPrivateWord(subject.title, in: store) ? "Private list" : subject.title
        return (name, ListContents.basketCount(of: subject, in: store))
    }

    private func isList(_ object: ObjectRecord) -> Bool {
        guard let listClass = engine.classes[.list], let classDef = object.classDef else { return false }
        return ClassResolver.isSubclass(classDef, of: listClass)
    }

    private func isWorkout(_ object: ObjectRecord) -> Bool {
        guard let workoutClass = engine.classes[.workout], let classDef = object.classDef else { return false }
        return ClassResolver.isSubclass(classDef, of: workoutClass)
    }

    private func wrapUp(_ process: ProcessSnapshot, workout: ObjectRecord) -> Note {
        let end = process.lastTouchedAt ?? .now
        // Opened and never logged: not a session. Close it without saving a trained day (undo brings it back).
        if !workout.orderedChildren.contains(where: { !$0.orderedChildren.isEmpty }) {
            let title = ObjectPrivacy.routineTitle(store.displayTitle(of: workout), in: store)
            let deleted = try? engine.perform(DiscardEmptyWorkout(process: process.id, workout: workout.id, time: end),
                                              by: .system).record
            // M37, with a 10 s UNDO that brings the workout back (lines audit 2, item 1).
            return Note(line: "\(title), no sets, not saved.", undo: deleted)
        }
        _ = try? engine.perform(FinishWorkout(workout: workout.id, time: end), by: .system)
        _ = try? engine.perform(EndProcess(process: process.id, reason: .wrappedUp, time: end), by: .system)
        let entries = workout.orderedChildren
        let started = entries.count { !$0.orderedChildren.isEmpty }
        let noun = entries.count == 1 ? "exercise" : "exercises"
        let counts = entries.isEmpty ? "" : " \(started) of \(entries.count) \(noun)."
        return Note(
            line: "\(ObjectPrivacy.routineTitle(store.displayTitle(of: workout), in: store)) saved.\(counts)",
            undo: nil
        )
    }

    private func spelled(_ number: Int) -> String {
        let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
        return number < words.count ? words[number] : String(number)
    }
}
