import Foundation
import SwiftData

/// Seeds a lived-in library through the object model: muscles, equipment, exercise subclasses with profiles,
/// a few weeks of Push Day history, today's schedule and tonight's workout.
@MainActor
enum DemoData {
    static func prepare(_ model: AppModel, arguments: [String] = ProcessInfo.processInfo.arguments) {
        if arguments.contains("-resetDemo") {
            reset(model)
        }
        if model.objects(of: .muscle).isEmpty {
            seedLibrary(model)
        }
        if model.schedule().isEmpty {
            seedToday(model)
        }
        model.touch()
    }

    private static func reset(_ model: AppModel) {
        let context = model.context
        try? context.delete(model: ObjectLink.self)
        try? context.delete(model: ObjectRecord.self)
        let userClasses = (try? context
            .fetch(FetchDescriptor<ClassDef>(predicate: #Predicate { $0.systemKey == nil }))) ?? []
        for classDef in userClasses {
            context.delete(classDef)
        }
        try? context.save()
    }

    // MARK: Library

    private static func seedLibrary(_ model: AppModel) {
        let store = model.store
        guard let muscle = model.classDef(.muscle), let equipment = model.classDef(.equipment),
              let lift = model.classDef(.barbellLift), let strength = model.classDef(.strengthExercise),
              let bench = model.classDef(.benchPress) else { return }

        func make(_ classDef: ClassDef, _ title: String, notes: String? = nil) -> ObjectRecord {
            let object = store.create(classDef, title: title)
            if let notes {
                try? store.set("notes", to: .richText(notes), on: object)
            }
            return object
        }

        let chest = make(muscle, "Chest", notes: "Pectoralis major — sternal and clavicular heads.")
        let triceps = make(muscle, "Triceps", notes: "Long, lateral and medial heads. Elbow extension.")
        let delts = make(muscle, "Front Delts", notes: "Anterior deltoid. Shoulder flexion.")
        let upperBack = make(muscle, "Upper Back")
        let barbell = make(equipment, "Barbell", notes: "20 kg Olympic bar.")
        let flatBench = make(equipment, "Flat Bench")
        let cable = make(equipment, "Cable Stack")
        let dumbbells = make(equipment, "Dumbbells")

        func subclass(_ name: String, of parent: ClassDef, symbol: String = "dumbbell") -> ClassDef {
            let classDef = ClassDef(name: name, parent: parent, symbolName: symbol, colorRole: "training")
            model.context.insert(classDef)
            return classDef
        }

        let overhead = subclass("Overhead Press", of: lift)
        let incline = subclass("Incline Dumbbell Press", of: strength)
        let fly = subclass("Cable Fly", of: strength, symbol: "figure.strengthtraining.functional")
        let pushdown = subclass("Triceps Pushdown", of: strength, symbol: "figure.strengthtraining.functional")
        _ = subclass("Paused Bench Press", of: bench)

        func profile(_ classDef: ClassDef, muscles: [ObjectRecord], gear: [ObjectRecord], cue: String) {
            let object = make(classDef, classDef.name, notes: cue)
            try? store.setLinks("primaryMuscles", on: object, to: muscles)
            try? store.setLinks("equipment", on: object, to: gear)
        }

        profile(bench, muscles: [chest, triceps, delts], gear: [barbell, flatBench],
                cue: "Shoulder blades pinned, slight arch, bar to lower chest, drive feet.")
        profile(overhead, muscles: [delts, triceps, upperBack], gear: [barbell],
                cue: "Squeeze glutes, bar path close to the face, lock out overhead.")
        profile(incline, muscles: [chest, delts], gear: [dumbbells, flatBench], cue: "30° bench. Elbows at 45°.")
        profile(fly, muscles: [chest], gear: [cable], cue: "Soft elbows, hug a tree, slow on the way back.")
        profile(pushdown, muscles: [triceps], gear: [cable], cue: "Elbows pinned to your sides.")

        // Three weeks of Push Day A, progressing.
        let plan: [(daysAgo: Double, bench: [(Double, Double)], ohp: [(Double, Double)])] = [
            (14, [(77.5, 8), (77.5, 8), (77.5, 7), (77.5, 6)], [(42.5, 8), (42.5, 8), (42.5, 7)]),
            (10, [(80, 8), (80, 7), (80, 6), (80, 6)], [(45, 8), (45, 7), (45, 6)]),
            (7, [(80, 8), (80, 8), (80, 8), (80, 7)], [(45, 8), (45, 8), (45, 7)]),
            (3, [(82.5, 7), (82.5, 6), (80, 8), (80, 8)], [(47.5, 7), (47.5, 6), (45, 8)]),
        ]
        guard let workoutClass = model.classDef(.workout), let entryClass = model.classDef(.exerciseEntry),
              let setClass = model.classDef(.set) else { return }
        for session in plan {
            let date = AppClock.now.addingTimeInterval(-session.daysAgo * 86400)
            let workout = store.create(workoutClass, title: "Push Day A")
            workout.createdAt = date
            try? store.set("scheduledFor", to: .date(date), on: workout)
            try? store.set("startedAt", to: .date(date), on: workout)
            try? store.set("endedAt", to: .date(date.addingTimeInterval(68 * 60)), on: workout)
            for (exercise, sets) in [(bench as ClassDef, session.bench), (overhead, session.ohp)] {
                let entry = store.create(entryClass, parent: workout)
                try? store.setClassLink("exercise", on: entry, to: exercise)
                for (weight, reps) in sets {
                    let set = store.create(setClass, parent: entry)
                    try? store.set("weight", to: .mass(weight), on: set)
                    try? store.set("reps", to: .number(reps), on: set)
                }
            }
        }
        _ = (incline, fly, pushdown)
        try? model.context.save()
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
        let lineup: [(String, Double, Double, Double)] = [
            ("Bench Press", 4, 8, 82.5),
            ("Overhead Press", 3, 8, 47.5),
            ("Incline Dumbbell Press", 3, 10, 26),
            ("Cable Fly", 3, 12, 15),
            ("Triceps Pushdown", 3, 12, 25),
        ]
        let allClasses = (try? model.context.fetch(FetchDescriptor<ClassDef>())) ?? []
        for (index, item) in lineup.enumerated() {
            guard let exercise = allClasses.first(where: { $0.name == item.0 }) else { continue }
            let entry = store.create(entryClass, parent: workout)
            entry.sortIndex = index
            try? store.setClassLink("exercise", on: entry, to: exercise)
            try? store.set("targetSets", to: .number(item.1), on: entry)
            try? store.set("targetReps", to: .number(item.2), on: entry)
            try? store.set("targetWeight", to: .mass(item.3), on: entry)
        }
        try? model.context.save()
    }
}
