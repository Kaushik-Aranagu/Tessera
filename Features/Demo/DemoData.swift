import Foundation
import TesseraCore

/// Seeds a lived-in day on top of Core's exercise library: a Push / Pull / Legs plan, six weeks of history, today's
/// schedule and tonight's workout.
@MainActor
enum DemoData {
    static func prepare(_ model: AppModel, arguments: [String] = ProcessInfo.processInfo.arguments) {
        if arguments.contains("-resetDemo") {
            reset(model)
        }
        if model.objects(of: .routine).isEmpty {
            seedLibrary(model)
        }
        if model.schedule().isEmpty {
            seedToday(model)
        }
        model.touch()
    }

    private static func reset(_ model: AppModel) {
        model.store.resetUserData()
        // The wipe takes the library's muscles, equipment and exercise profiles with it: put them back.
        model.store.invalidateCaches()
        _ = try? ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: model.store,
                                                  classes: model.classes)
    }

    // MARK: Library

    /// A library exercise by its seed key (`ExerciseLibrary`); Bench Press is the system class.
    private static func library(_ key: String, _ model: AppModel) -> ClassDef? {
        if key == "benchPress" {
            return model.classDef(.benchPress)
        }
        return model.store.classDef(id: SystemCatalog.stableID("library.\(key)"))
    }

    /// The demo trains on Core's exercise library (muscles, equipment and profiles come with it); it only adds the
    /// plan and the history.
    private static func seedLibrary(_ model: AppModel) {
        guard let bench = library("benchPress", model), let overhead = library("overheadPress", model),
              let incline = library("inclineDbPress", model), let fly = library("cableFly", model),
              let pushdown = library("ropePushdown", model), let row = library("barbellRow", model),
              let pulldown = library("latPulldown", model), let squat = library("backSquat", model),
              let deadlift = library("romanianDeadlift", model) else { return }

        // The plan, through typed actions like any other write.
        let routines = seedPlan(model, slots: [
            "Push Day A": [bench, overhead, incline, fly, pushdown],
            "Pull Day A": [row, pulldown],
            "Leg Day A": [squat, deadlift],
        ])

        seedHistory(model, routines: routines, push: (bench, overhead), pull: (row, pulldown), legs: (squat, deadlift))
        model.store.save()
    }

    /// Six weeks of a rolling Push / Pull / Legs: September lighter, October progressing, legs yesterday.
    private static func seedHistory(_ model: AppModel, routines: [String: ObjectRecord],
                                    push: (bench: ClassDef, overhead: ClassDef),
                                    pull: (row: ClassDef, pulldown: ClassDef),
                                    legs: (squat: ClassDef, deadlift: ClassDef))
    {
        let (bench, overhead) = push, (row, pulldown) = pull, (squat, deadlift) = legs
        // Three weeks of Push Day A, progressing.
        let pushDays: [(daysAgo: Double, bench: [(Double, Double)], ohp: [(Double, Double)])] = [
            (14, [(77.5, 8), (77.5, 8), (77.5, 7), (77.5, 6)], [(42.5, 8), (42.5, 8), (42.5, 7)]),
            (10, [(80, 8), (80, 7), (80, 6), (80, 6)], [(45, 8), (45, 7), (45, 6)]),
            (7, [(80, 8), (80, 8), (80, 8), (80, 7)], [(45, 8), (45, 8), (45, 7)]),
            (3, [(82.5, 7), (82.5, 6), (80, 8), (80, 8)], [(47.5, 7), (47.5, 6), (45, 8)]),
        ]
        for session in pushDays {
            addWorkout(model, routine: routines["Push Day A"], daysAgo: session.daysAgo,
                       entries: [(bench, session.bench), (overhead, session.ohp)])
        }

        // Pull and legs between those pushes, rolling on to Push today (Legs yesterday). Leg day four days ago
        // ends before Home's two-to-four-days-ago window opens.
        for (index, daysAgo) in [13.0, 9, 5, 2].enumerated() {
            let load = 60 + Double(index) * 2.5
            addWorkout(model, routine: routines["Pull Day A"], daysAgo: daysAgo,
                       entries: [
                           (row, Array(repeating: (load, 8), count: 4)),
                           (pulldown, [(50, 10), (50, 10), (50, 9)]),
                       ])
        }
        for (index, daysAgo) in [12.0, 8, 4.2, 1].enumerated() {
            let load = 90 + Double(index) * 2.5
            addWorkout(model, routine: routines["Leg Day A"], daysAgo: daysAgo,
                       entries: [(squat, [(load, 8), (load, 7), (load, 6), (load, 6)]), (deadlift, [(80, 8), (80, 8)])])
        }

        // September: fourteen sessions every other day, lighter, so October has a month to keep level with. No
        // bench or other chest work here: bench history stays the four sessions above, and swaps keep estimating.
        let order = ["Leg Day A", "Pull Day A", "Push Day A"]
        for (index, daysAgo) in stride(from: 17.0, through: 43, by: 2).enumerated() {
            let routine = order[index % 3]
            let step = Double(index) * 1.25
            let entries: [(ClassDef, [(Double, Double)])] = switch routine {
            case "Push Day A": [(overhead, [(40, 8), (40, 8), (40, 7), (40, 6)])]
            case "Pull Day A": [(row, [(55 - step, 8), (55 - step, 8), (55 - step, 7)])]
            default: [(squat, [(85 - step, 8), (85 - step, 7), (85 - step, 6)])]
            }
            addWorkout(model, routine: routines[routine], daysAgo: daysAgo, entries: entries)
        }
    }

    /// Push Day A / Pull Day A / Leg Day A as routines with slots, and a plan that cycles them.
    private static func seedPlan(_ model: AppModel,
                                 slots: KeyValuePairs<String, [ClassDef]>) -> [String: ObjectRecord]
    {
        var routines: [String: ObjectRecord] = [:]
        for (title, exercises) in slots {
            guard let routine = try? model.engine.perform(CreateRoutine(title: title), by: .system).output else {
                continue
            }
            for exercise in exercises {
                _ = try? model.engine.perform(AddSlot(routine: routine.id, exercise: exercise.id), by: .system)
            }
            routines[title] = routine
        }
        let cycle = slots.compactMap { routines[$0.key]?.id }
        let start = AppClock.now.addingTimeInterval(-45 * 86400)
        _ = try? model.engine.perform(
            CreatePlan(title: "Push Pull Legs", routines: cycle, startsOn: start),
            by: .system
        )
        return routines
    }

    /// A finished workout `daysAgo` days back, linked to its routine, with working sets.
    private static func addWorkout(_ model: AppModel, routine: ObjectRecord?, daysAgo: Double,
                                   entries: [(ClassDef, [(Double, Double)])])
    {
        let store = model.store
        guard let workoutClass = model.classDef(.workout), let entryClass = model.classDef(.exerciseEntry),
              let setClass = model.classDef(.set) else { return }
        let date = AppClock.now.addingTimeInterval(-daysAgo * 86400)
        let workout = store.create(workoutClass, title: routine?.title ?? "Workout")
        workout.createdAt = date
        try? store.set("scheduledFor", to: .date(date), on: workout)
        try? store.set("startedAt", to: .date(date), on: workout)
        try? store.set("endedAt", to: .date(date.addingTimeInterval(68 * 60)), on: workout)
        if let routine {
            try? store.setLinks("routine", on: workout, to: [routine])
        }
        for (exercise, sets) in entries {
            let entry = store.create(entryClass, parent: workout)
            try? store.setClassLink("exercise", on: entry, to: exercise)
            for (weight, reps) in sets {
                let set = store.create(setClass, parent: entry)
                try? store.set("weight", to: .mass(weight), on: set)
                try? store.set("reps", to: .number(reps), on: set)
            }
        }
    }

    // MARK: Today

    private static func seedToday(_ model: AppModel) {
        let store = model.store
        guard let taskClass = model.classDef(.task), let workoutClass = model.classDef(.workout),
              let entryClass = model.classDef(.exerciseEntry) else { return }
        let now = AppClock.now
        let anchor = Date(timeIntervalSinceReferenceDate: (now.timeIntervalSinceReferenceDate / 300)
            .rounded(.down) * 300)

        let items: [(String, Double, Double, Bool)] = [
            ("Morning pages", -10 * 60 - 20, 20, true),
            ("Standup", -8 * 60 - 40, 15, true),
            ("Deep work · Tessera object model", -7 * 60 - 50, 120, true),
            ("Lunch walk", -5 * 60 - 10, 40, true),
            ("Review the sprint plan", -3 * 60 - 20, 45, true),
            ("Groceries for the week", -25, 55, false),
            ("Stretch & mobility", 140, 20, false),
            ("Read · Designing Data-Intensive Applications", 180, 40, false),
        ]
        for (title, offset, minutes, done) in items {
            let task = store.create(taskClass, title: title)
            try? store.set("startsAt", to: .date(anchor.addingTimeInterval(offset * 60)), on: task)
            try? store.set("length", to: .duration(minutes * 60), on: task)
            try? store.set("isDone", to: .bool(done), on: task)
        }

        let workout = store.create(workoutClass, title: "Push Day A")
        try? store.set("scheduledFor", to: .date(anchor.addingTimeInterval(50 * 60)), on: workout)
        // Today's workout is the plan's Push routine (the plan rolls on to it after yesterday's legs).
        if let push = model.objects(of: .routine).first(where: { $0.title == "Push Day A" }) {
            try? store.setLinks("routine", on: workout, to: [push])
        }
        let lineup: [(String, Double, Double, Double)] = [
            ("benchPress", 4, 8, 82.5),
            ("overheadPress", 3, 8, 47.5),
            ("inclineDbPress", 3, 10, 26),
            ("cableFly", 3, 12, 15),
            ("ropePushdown", 3, 12, 25),
        ]
        for (index, item) in lineup.enumerated() {
            guard let exercise = library(item.0, model) else { continue }
            let entry = store.create(entryClass, parent: workout)
            entry.sortIndex = index
            try? store.setClassLink("exercise", on: entry, to: exercise)
            try? store.set("targetSets", to: .number(item.1), on: entry)
            try? store.set("targetReps", to: .number(item.2), on: entry)
            try? store.set("targetWeight", to: .mass(item.3), on: entry)
        }
        model.store.save()
    }
}
