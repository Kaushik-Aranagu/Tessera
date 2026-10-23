import Foundation

@MainActor
public extension HomeSentence.MoneyDue {
    /// The next bill that is due, by name and day, for Home. There is no bills model in Core yet (pools have no due
    /// dates, and a move is not a bill), so this is nil. Home then says nothing about Money rather than "Nothing is
    /// due", which would be a claim. When a bills model exists this is the one place that reads it, words only.
    static func next(engine _: ActionEngine, now _: Date) -> HomeSentence.MoneyDue? {
        nil
    }
}

@MainActor
public extension HomeSentence.RoutinesPart {
    /// The routines' landing facts and the next usual start, read from the phone: every routine with its runs (finished
    /// workouts made from it), what ran today, and the one running now. Names are masked the way the landing masks
    /// them. With no routines the part is empty and the apps list says "Nothing planned", which is true.
    static func make(engine: ActionEngine, now: Date, calendar: Calendar = .current) -> HomeSentence.RoutinesPart {
        let store = engine.store, classes = engine.classes
        let day = TesseraDay(calendar: calendar)
        let today = day.day(of: now)
        var runs: [UUID: [RoutineRun]] = [:]
        var doneToday: [UUID: Date] = [:]
        if let workoutClass = classes[.workout] {
            for workout in store.objects(of: workoutClass) where !workout.isDeleted {
                guard let routine = store.linkedObjects("routine", of: workout).first,
                      let start = store.value("startedAt", of: workout)?.dateValue,
                      let end = store.value("endedAt", of: workout)?.dateValue, end > start else { continue }
                runs[routine.id, default: []].append(RoutineRun(start: start, end: end))
                if day.day(of: end) == today {
                    doneToday[routine.id] = max(doneToday[routine.id] ?? end, end)
                }
            }
        }
        var items: [(record: ObjectRecord, item: RoutinesLanding.Item)] = []
        if let routineClass = classes[.routine] {
            for routine in store.objects(of: routineClass) where !routine.isDeleted {
                let isPrivate = ObjectPrivacy.shownLabel(of: routine, in: store, classes: classes) != nil
                    || AppSummaryLines.shown(routine.title, in: store, classes: classes).isPrivate
                let children = routine.orderedChildren
                items.append((routine, RoutinesLanding.Item(
                    name: isPrivate ? RoutinesLanding.privateRoutine : routine.title,
                    isWorkout: children.contains { $0.classDef?.id == classes[.slot]?.id },
                    count: children.count, isPrivate: isPrivate, runs: runs[routine.id] ?? [],
                    doneToday: doneToday[routine.id]
                )))
            }
        }
        var running: RoutinesLanding.Running?
        if let process = ProcessTable(engine: engine).running(), let subject = process.subject,
           subject.classDef?.id == classes[.workout]?.id
        {
            let routine = store.linkedObjects("routine", of: subject).first
            let masked = ObjectPrivacy.shownLabel(of: subject, in: store, classes: classes) != nil
                || routine.map { ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) != nil } ?? false
            let name = routine?.title ?? subject.title
            let step = process.nextStep ?? "First set"
            let stepHidden = AppSummaryLines.shown(step, in: store, classes: classes).isPrivate
            running = RoutinesLanding.Running(
                name: name,
                isPrivate: masked || AppSummaryLines.shown(name, in: store, classes: classes).isPrivate,
                step: step,
                isStepPrivate: stepHidden,
                secondsOnStep: max(0, process.idle(at: now))
            )
        }
        let facts = RoutinesLanding.facts(items: items.map(\.item), running: running, now: now, calendar: calendar)
        // The next usual start today, among routines he has not run today and usually runs at a time still ahead.
        var next: Date?
        for entry in items where entry.item.doneToday == nil && !entry.item.isPrivate {
            guard let counts = RoutineUsual.counts(of: entry.item.runs, calendar: calendar) else { continue }
            let minutes = TesseraDay.startHour * 60 + counts.startMinutes
            guard let start = calendar.date(bySettingHour: minutes / 60 % 24, minute: minutes % 60, second: 0, of: now),
                  start >= now else { continue }
            next = min(next ?? start, start)
        }
        return HomeSentence.RoutinesPart(facts: facts, nextUsualStart: next)
    }
}
