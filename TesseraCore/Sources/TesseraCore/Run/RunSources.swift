import Foundation

/// Runners read what they run into steps. These are the read-only readers for the two runs that exist today, so the
/// plane can be proven against them (tests) before any screen moves onto it. Nothing here writes.
@MainActor
public enum RunSources {
    /// A workout: one counted step per planned set of every exercise, in order. Logged working sets are done; the
    /// first one not logged is now, exactly where `WorkoutProgress` points. A private workout's steps all read
    /// "Private workout", so nothing built on this (a Live Activity on the Lock Screen) can show its exercises.
    public static func workout(_ workout: ObjectRecord, store: ObjectStore,
                               classes: [SystemCatalog.Key: ClassDef]) -> [RunStep]
    {
        let mask = ObjectPrivacy.shownLabel(of: workout, in: store, classes: classes)
        var steps: [RunStep] = []
        var foundNow = false
        for entry in workout.orderedChildren {
            let name = store.linkedClass("exercise", of: entry)?.name ?? entry.title
            let logged = entry.orderedChildren.count { store.value("isWarmup", of: $0) != .bool(true) }
            let planned = Int(store.number("targetSets", of: entry) ?? 3)
            // A set past the plan (an extra set) is a done step of its own, so the count never shrinks.
            for index in 0 ..< max(planned, logged) {
                let done = index < logged
                var step = RunStep(title: mask ?? "\(name), set \(index + 1)", kind: .counted,
                                   state: done ? .done : .ahead)
                if !done, !foundNow {
                    step.state = .now
                    foundNow = true
                }
                steps.append(step)
            }
        }
        return steps
    }

    /// A recipe at a size: one step per recipe step, in order. A step with a timer is timed (the shortest end of its
    /// first range, as the cook screen offers it); the rest are checks. A private recipe's steps read "Private recipe".
    public static func recipe(cook: ObjectRecord, store: ObjectStore,
                              classes: [SystemCatalog.Key: ClassDef]) -> [RunStep]
    {
        guard let recipe = store.linkedObjects("recipe", of: cook).first else { return [] }
        return RecipeBook(store: store, classes: classes).steps(of: recipe).map { step in
            let title = ObjectPrivacy.stepLine(step.text, cook: cook, in: store) ?? step.text
            if let timer = step.offeredTimers.first {
                return RunStep(title: title, kind: .timed, seconds: timer.lowerBound * 60)
            }
            return RunStep(title: title, kind: .check)
        }
    }

    /// A routine with no runner of its own (morning, night, anything he makes): the default runner's steps. Each is a
    /// check, or timed when it has a length.
    public static func routine(_ items: [(title: String, seconds: TimeInterval?)]) -> [RunStep] {
        items.map { item in
            item.seconds.map { RunStep(title: item.title, kind: .timed, seconds: $0) }
                ?? RunStep(title: item.title, kind: .check)
        }
    }
}
