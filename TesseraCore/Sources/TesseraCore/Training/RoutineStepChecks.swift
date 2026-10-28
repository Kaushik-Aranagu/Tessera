import Foundation

// Checking a routine's steps off (sheets 313 and 379): each step carries the time it was last checked, the page reads
// which steps are done today, and checking the last one tends the routine for the day (once a day, in the same op
// group, so one Undo takes both back). Unchecking only clears the step; the day's tend stays, since it happened.

/// Checks a step (or a move) off, or takes the check back.
public struct TendRoutineStep: EngineAction {
    public struct Output: Equatable, Sendable {
        /// The step is checked after this.
        public let done: Bool
        /// This check was the routine's last: the routine was tended for the day (false if it already had been).
        public let routineTended: Bool
    }

    public static let descriptor = ActionDescriptor(
        name: "tendRoutineStep", summary: "Check a routine step off",
        parameters: [.init("step", .object, "The step"), .init("at", .date, "Defaults to now", required: false),
                     .init("done", .boolean, "False takes the check back; true when left out", required: false)],
        isOfferedToModel: false
    )

    public var step: UUID
    public var at: Date?
    public var done: Bool

    public init(step: UUID, at: Date? = nil, done: Bool = true) {
        self.step = step
        self.at = at
        self.done = done
    }

    public func apply(_ transaction: inout Transaction) throws -> Output {
        let target = try transaction.object(step, is: .routineStep)
        let when = at ?? transaction.now
        try transaction.set("doneAt", to: done ? .date(when) : nil, on: target)
        guard done, let routine = target.parent, routine.classDef?.systemKey == SystemCatalog.Key.routine.systemKey
        else { return Output(done: done, routineTended: false) }
        // The last step checked today tends the routine, once a day.
        let book = RestBook(store: transaction.store, classes: transaction.classes)
        guard book.isFullyDone(routine.id, on: when, calendar: transaction.calendar) else {
            return Output(done: true, routineTended: false)
        }
        let tended = try TendRoutine(routine: routine.id, at: when).apply(&transaction)
        return Output(done: true, routineTended: tended)
    }

    public func summary(in store: ObjectStore) -> String {
        "\(done ? "Checked" : "Unchecked") \(store.object(id: step).map(\.title) ?? "a step")"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

public extension RestBook {
    /// When a step was last checked off.
    func lastDone(ofStep step: UUID) -> Date? {
        store.object(id: step).flatMap { store.value("doneAt", of: $0)?.dateValue }
    }

    /// The steps of a routine checked today (a Tessera day, 04:00 to 04:00).
    func stepsDone(of routine: UUID, on moment: Date, calendar: Calendar = .current) -> Set<UUID> {
        guard let object = store.object(id: routine) else { return [] }
        let tessera = TesseraDay(calendar: calendar)
        let today = tessera.day(of: moment)
        return Set(object.orderedChildren.compactMap { step -> UUID? in
            guard let done = store.value("doneAt", of: step)?.dateValue,
                  tessera.day(of: done) == today else { return nil }
            return step.id
        })
    }

    /// The steps still to check today, in order.
    func stepsLeft(of routine: UUID, on moment: Date, calendar: Calendar = .current) -> [UUID] {
        guard let object = store.object(id: routine) else { return [] }
        let done = stepsDone(of: routine, on: moment, calendar: calendar)
        return object.orderedChildren.map(\.id).filter { !done.contains($0) }
    }

    /// Every step of the routine is checked today (a routine with no steps is never done this way).
    func isFullyDone(_ routine: UUID, on moment: Date, calendar: Calendar = .current) -> Bool {
        guard let object = store.object(id: routine), !object.orderedChildren.isEmpty else { return false }
        return stepsLeft(of: routine, on: moment, calendar: calendar).isEmpty
    }
}
