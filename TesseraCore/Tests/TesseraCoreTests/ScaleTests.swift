import Foundation
import SwiftData
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
}
