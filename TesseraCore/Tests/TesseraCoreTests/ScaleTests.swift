import Foundation
@testable import TesseraCore
import Testing

/// Years of training history, with time budgets for the queries screens make.
/// Runs 200 workouts by default; set TESSERA_SCALE=1500 for about five years of history (~37,500 sets).
@MainActor
struct ScaleTests {
    static let workouts = ProcessInfo.processInfo.environment["TESSERA_SCALE"].flatMap(Int.init) ?? 200

    @Test func historyQueriesStayFast() async throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let classes = try SystemCatalog.seed(in: context)
        let store = ObjectStore(context: context)
        let engine = ActionEngine(store: store, classes: classes)
        let ledger = TrainingLedger(store: store, classes: classes)
        let bench = try #require(classes[.benchPress])
        let lift = try #require(classes[.barbellLift])
        let workoutClass = try #require(classes[.workout])
        let entryClass = try #require(classes[.exerciseEntry])
        let others = (0 ..< 4).map { index in
            let classDef = ClassDef(name: "Lift \(index)", parent: lift)
            context.insert(classDef)
            return classDef
        }
        let muscles = try MuscleLibrary.install(store: store, classes: classes)
        try store.setLinks("primaryMuscles", on: store.ensureClassObject(of: bench), to: [#require(muscles[.chest])])

        let clock = ContinuousClock()
        let workouts = Self.workouts
        var lastEntry: ObjectRecord?
        let build = try clock.measure {
            for day in 0 ..< workouts {
                let workout = store.create(workoutClass, title: "Day \(day)")
                try store.set("endedAt", to: .date(Date(timeIntervalSince1970: 1_700_000_000 + Double(day) * 86400)),
                              on: workout)
                for exercise in [bench] + others {
                    let entry = store.create(entryClass, parent: workout)
                    try store.setClassLink("exercise", on: entry, to: exercise)
                    for set in 0 ..< 5 {
                        try ledger.logSet(weight: 60 + Double(day % 40), reps: Double(5 + set), in: entry)
                    }
                    if exercise.id == bench.id {
                        lastEntry = entry
                    }
                }
            }
            try context.save()
        }
        let now = Date(timeIntervalSince1970: 1_700_000_000 + Double(workouts) * 86400)
        var timings: [(String, Duration)] = [("build", build)]
        func time(_ name: String, _ work: () throws -> Void) rethrows {
            try timings.append((name, clock.measure(work)))
        }

        let warmStart = clock.now
        await ledger.warmUp()
        timings.append(("warmUp(background)", clock.now - warmStart))
        try time("firstQuery") { _ = ledger.sessions(of: bench) }
        try time("records") { _ = ledger.records(for: bench) }
        try time("nextTarget") { _ = ledger.nextTarget(for: bench) }
        try time("trend") { _ = ledger.trend(of: bench, days: 90, now: now) }
        try time("weeklySets") { _ = ledger.weeklySets(weekContaining: now) }
        try time("month") { _ = ledger.month(containing: now) }
        // The hot path in live mode: log a set, then ask for records for the PR hint.
        let entry = try #require(lastEntry)
        try time("logAndHint") {
            try engine.perform(LogSet(entry: entry.id, weight: 120, reps: 5), by: .user)
            _ = ledger.recordsBeaten(weight: 122.5, reps: 5, for: bench)
        }
        #expect(ledger.records(for: bench).bestE1RM?.weight == 120)

        print(
            "SCALE \(workouts) workouts:",
            timings.map { "\($0.0)=\(Self.milliseconds($0.1))ms" }.joined(separator: " ")
        )
        let budgets: [String: Double] = [
            "firstQuery": 100,
            "records": 50,
            "nextTarget": 100,
            "trend": 50,
            "logAndHint": 250,
        ]
        for (name, duration) in timings {
            // Five years of history get twice the room of the default run.
            if let budget = budgets[name].map({ workouts > 1000 ? $0 * 2 : $0 }) {
                #expect(Self.milliseconds(duration) < budget, "\(name) took \(Self.milliseconds(duration)) ms")
            }
        }
    }

    static func milliseconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) * 1000 + Double(duration.components.attoseconds) / 1e15
    }

    /// The Day log reads one day out of years of op log in a frame or two (QA S1 on #318).
    @Test func dayLogStaysFast() async throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let lifts = [SystemCatalog.Key](repeating: .benchPress, count: 5)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let clock = ContinuousClock()
        let build = try clock.measure {
            for day in 0 ..< Self.workouts {
                let time = start.addingTimeInterval(Double(day) * 86400)
                @MainActor func dated(_ record: OpRecord, _ minutes: Double) {
                    record.createdAt = time.addingTimeInterval(minutes * 60)
                }
                let workout = try store.create(#require(classes[.workout]), title: "Day \(day)")
                try dated(engine.perform(StartWorkout(workout: workout.id, time: time), by: .user).record, 0)
                for (index, key) in lifts.enumerated() {
                    let added = try engine.perform(
                        AddExercise(workout: workout.id, exercise: #require(classes[key]).id),
                        by: .user
                    )
                    dated(added.record, Double(index * 10))
                    for set in 0 ..< 5 {
                        let minutes = Double(index * 10 + set * 2)
                        try dated(engine.perform(LogSet(entry: added.output.id, weight: 60, reps: Double(5 + set),
                                                        time: time.addingTimeInterval(minutes * 60)),
                                                 by: .user).record, minutes)
                    }
                }
                try dated(engine.perform(FinishWorkout(workout: workout.id, time: time.addingTimeInterval(3600)),
                                         by: .user).record, 60)
                try dated(engine.perform(CreateTask(title: "task \(day)"), by: .user).record, 120)
            }
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let last = start.addingTimeInterval(Double(Self.workouts - 1) * 86400 + 600)
        // The app warms the ledger at launch; the Day log reads after that.
        await TrainingLedger(store: store, classes: classes).warmUp()
        var story: [DayLine] = []
        let read = clock.measure {
            story = DayStory.lines(engine: engine, on: last, calendar: calendar, now: last.addingTimeInterval(86400))
        }
        print("SCALE \(Self.workouts) workouts: dayLogBuild=\(Self.milliseconds(build))ms "
            + "dayLog=\(Self.milliseconds(read))ms")
        #expect(story.contains { $0.text.hasPrefix("Day \(Self.workouts - 1), 60 min") })
        let budget: Double = Self.workouts > 1000 ? 100 : 50
        #expect(Self.milliseconds(read) < budget, "dayLog took \(Self.milliseconds(read)) ms")
    }
}

@MainActor
struct OnDiskTests {
    /// Writes a history to SQLite, reopens it cold, and checks everything came back wired up.
    @Test func historySurvivesARoundTripThroughSQLite() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("tessera.sqlite")
        let workouts = ScaleTests.workouts
        let clock = ContinuousClock()
        var expected: TrainingLedger.PersonalRecords?
        let write = try clock.measure {
            let container = TesseraSchema.makeContainer(url: url)
            let context = container.mainContext
            context.autosaveEnabled = false
            let classes = try SystemCatalog.seed(in: context)
            let store = ObjectStore(context: context)
            let engine = ActionEngine(store: store, classes: classes)
            let bench = try #require(classes[.benchPress])
            for day in 0 ..< workouts {
                let workout = try store.create(#require(classes[.workout]), title: "Day \(day)")
                let entry = try engine.perform(AddExercise(workout: workout.id, exercise: bench.id), by: .user).output
                for set in 0 ..< 5 {
                    try engine.perform(LogSet(entry: entry.id, weight: 60 + Double(day % 40), reps: Double(5 + set)),
                                       by: .user)
                }
                try engine.perform(FinishWorkout(workout: workout.id,
                                                 time: Date(timeIntervalSince1970: 1_700_000_000 + Double(day) *
                                                     86400)),
                                   by: .user)
                try context.save() // one save per workout, as the app writes
            }
            expected = TrainingLedger(store: store, classes: classes).records(for: bench)
        }
        var reopened: TesseraContainer?
        let open = clock.measure { reopened = TesseraSchema.makeContainer(url: url) }
        let context = try #require(reopened).mainContext
        let classes = try SystemCatalog.existing(in: context)
        let ledger = TrainingLedger(store: ObjectStore(context: context), classes: classes)
        let bench = try #require(classes[.benchPress])
        let records = ledger.records(for: bench)
        #expect(records.bestE1RM?.e1RM == expected?.bestE1RM?.e1RM)
        #expect(records.bestWeightByReps == expected?.bestWeightByReps)
        #expect(ledger.sessions(of: bench).count == workouts)
        #expect(ActionEngine(store: ObjectStore(context: context), classes: classes).history(limit: .max).count
            == workouts * 7)
        print(
            "DISK \(workouts) workouts: write+save=\(ScaleTests.milliseconds(write))ms open=\(ScaleTests.milliseconds(open))ms"
        )
    }
}
