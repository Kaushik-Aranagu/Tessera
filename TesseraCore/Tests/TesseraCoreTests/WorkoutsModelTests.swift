import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct WorkoutsModelTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let engine: ActionEngine
    let ledger: TrainingLedger
    let start = Date(timeIntervalSince1970: 1_792_000_000)

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
        ledger = TrainingLedger(store: store, classes: classes)
    }

    func finishedWorkout(_ routine: ObjectRecord? = nil, daysAgo: Double, _ sets: [(Double, Double)],
                         exercise key: SystemCatalog.Key = .benchPress) throws -> ObjectRecord
    {
        let workout = try store.create(#require(classes[.workout]), title: "Push Day A")
        if let routine {
            try store.setLinks("routine", on: workout, to: [routine])
        }
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[key]).id),
                                       by: .user).output
        for (weight, reps) in sets {
            try engine.perform(LogSet(entry: entry.id, weight: weight, reps: reps), by: .user)
        }
        try engine.perform(FinishWorkout(workout: workout.id, time: start.addingTimeInterval(-daysAgo * 86400)),
                           by: .user)
        return workout
    }

    // MARK: Honest e1RM and set kinds

    @Test func e1RMUsesEffectiveRepsWhenRPEIsLogged() {
        #expect(ledger.e1RM(weight: 100, reps: 5) == 100 * (1 + 5.0 / 30))
        // 5 @ RPE 8 is a 7-rep effort.
        #expect(ledger.e1RM(weight: 100, reps: 5, rpe: 8) == 100 * (1 + 7.0 / 30))
        #expect(TrainingLedger.effectiveReps(5, rpe: 8) == 7)
    }

    @Test func highRepSetsAndWarmupsStayOutOfRecords() throws {
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 100, reps: 3, kind: .warmup, source: .hold), by: .user)
        try engine.perform(LogSet(entry: entry.id, weight: 60, reps: 20, source: .dial), by: .user)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8, source: .lockScreen), by: .user)
        try engine.perform(FinishWorkout(workout: workout.id, time: start), by: .user)

        let records = try ledger.records(for: #require(classes[.benchPress]))
        #expect(records.bestE1RM?.weight == 80) // 60 × 20 would "win" on Epley but isn't honest
        #expect(records.bestWeightByReps == [8: 80])
        let sets = entry.orderedChildren
        #expect(ledger.setKind(sets[0]) == .warmup)
        #expect(store.value("source", of: sets[2]) == .choice("lockScreen"))
        #expect(store.value("loggedAt", of: sets[2]) != nil)
    }

    @Test func undoTheLastSetFromTheLockScreen() throws {
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8), by: .user)
        let second = try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 7, source: .lockScreen), by: .intent)
        try engine.perform(CreateTask(title: "Stretch"), by: .user)
        #expect(engine.undoLatest(action: LogSet.descriptor.name)?.id == second.record.id)
        #expect(entry.orderedChildren.count == 1)
    }

    // MARK: Muscles

    @Test func secondaryMusclesCountHalf() throws {
        let muscles = try MuscleLibrary.install(store: store, classes: classes)
        #expect(muscles.count == 18)
        #expect(try MuscleLibrary.install(store: store, classes: classes).count == 18)
        #expect(try store.objects(of: #require(classes[.muscle])).count == 18)
        #expect(try muscles[.frontDelts].flatMap { store.value("group", of: $0) } == .text("Shoulders"))

        let bench = try #require(classes[.benchPress])
        let profile = store.ensureClassObject(of: bench)
        try store.setLinks("primaryMuscles", on: profile, to: [#require(muscles[.chest])])
        try store.setLinks(
            "secondaryMuscles",
            on: profile,
            to: [#require(muscles[.triceps]), #require(muscles[.frontDelts])]
        )
        _ = try finishedWorkout(daysAgo: 0, [(80, 8), (80, 8), (80, 7)])

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let week = ledger.weeklySets(weekContaining: start, calendar: calendar)
        #expect(try week[#require(muscles[.chest]).id] == 3)
        #expect(try week[#require(muscles[.triceps]).id] == 1.5)
        #expect(try store.objects(of: #require(classes[.muscle])).first
            .flatMap { store.number("weeklySetsMax", of: $0) } == 20)
    }

    // MARK: Progression

    @Test func progressionRulesParse() {
        #expect(ProgressionRule(parsing: "dp(+2.5, 8, 12)") == .doubleProgression(
            increment: 2.5,
            repMin: 8,
            repMax: 12
        ))
        #expect(ProgressionRule(parsing: "DP(2,6,10)")?.text == "dp(+2, 6, 10)")
        #expect(ProgressionRule(parsing: "dp(+2.5, 12, 8)") == nil)
        #expect(ProgressionRule(parsing: "linear") == nil)
    }

    @Test func doubleProgressionAddsWeightWhenEverySetHitsTheTop() throws {
        let bench = try #require(classes[.benchPress])
        #expect(ledger.nextTarget(for: bench).weight == nil)

        // Barbell lifts inherit dp(+2.5, 8, 12). Not every set reached 12: same weight, one more rep.
        _ = try finishedWorkout(daysAgo: 7, [(80, 12), (80, 11), (80, 10)])
        let hold = ledger.nextTarget(for: bench)
        #expect(hold.weight == 80 && hold.reps == 11)

        // Every set at 12: +2.5 kg and back to 8.
        _ = try finishedWorkout(daysAgo: 3, [(80, 12), (80, 12), (80, 12)])
        let raise = ledger.nextTarget(for: bench)
        #expect(raise.weight == 82.5 && raise.reps == 8)
        #expect(raise.reason == "Every set hit 12 last time, so +2.5 kg")

        // A slot's rule overrides the class's.
        let routine = try engine.perform(CreateRoutine(title: "Push Day A"), by: .user).output
        let slot = try engine.perform(AddSlot(routine: routine.id, exercise: bench.id, repMin: 5, repMax: 12,
                                              progression: "dp(+5, 5, 12)"), by: .user).output
        let slotTarget = ledger.nextTarget(for: bench, slot: slot)
        #expect(slotTarget.weight == 85 && slotTarget.reps == 5)
    }

    @Test func loadProfilesSnapToRealWeights() throws {
        let plates = PlateLoad(bar: 20, plates: [20, 10, 5, 2.5, 1.25])
        #expect(plates.plates(for: 82.5) == [20, 10, 1.25])
        #expect(plates.plates(for: 83) == nil)
        #expect(plates.next(above: 80) == 82.5)
        #expect(plates.nearest(to: 81.4) == 82.5)
        #expect(FixedLoads.dumbbells.next(above: 12.5) == 14)
        #expect(FixedLoads(step: 5).nearest(to: 47) == 45)

        // An equipment object's plates drive the profile for exercises that use it.
        let barbell = try store.create(#require(classes[.equipment]), title: "Barbell")
        try store.set("kind", to: .choice("barbell"), on: barbell)
        try store.set("plates", to: .text("20, 10, 5, 2.5"), on: barbell)
        let bench = try #require(classes[.benchPress])
        try store.setLinks("equipment", on: store.ensureClassObject(of: bench), to: [barbell])
        let profile = store.loadProfile(for: bench)
        #expect(profile.next(above: 80) == 85)
    }

    // MARK: Routines and plans

    @Test func startingARoutinePrefillsEveryEntry() throws {
        let bench = try #require(classes[.benchPress])
        let lift = try #require(classes[.barbellLift])
        let routine = try engine.perform(CreateRoutine(title: "Push Day A"), by: .user).output
        try engine.perform(AddSlot(routine: routine.id, exercise: bench.id, sets: 4), by: .user)
        try engine.perform(AddSlot(routine: routine.id, exercise: lift.id), by: .user)
        _ = try finishedWorkout(routine, daysAgo: 3, [(80, 12), (80, 12), (80, 12)])

        let started = try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user)
        let workout = started.output
        let entries = workout.orderedChildren
        #expect(entries.count == 2)
        #expect(store.number("targetSets", of: entries[0]) == 4)
        #expect(store.number("targetWeight", of: entries[0]) == 82.5)
        #expect(store.number("targetReps", of: entries[0]) == 8)
        #expect(store.linkedObjects("slot", of: entries[0]).first?.id == routine.orderedChildren[0].id)
        #expect(store.linkedObjects("routine", of: workout).first?.id == routine.id)
        #expect(ProcessTable(engine: engine).running()?.nextStep == "Bench Press, set 1: 82.5 kg × 8")

        // One undo removes the whole started workout.
        engine.undo(started.record)
        #expect(workout.isDeleted)
    }

    @Test func plansRollToTheNextRoutineWithoutDebt() throws {
        let names = ["Push", "Pull", "Legs"]
        let routines = try names.map { try engine.perform(CreateRoutine(title: $0), by: .user).output }
        let plan = try engine.perform(CreatePlan(title: "PPL", routines: routines.map(\.id)), by: .user).output
        #expect(ledger.nextRoutine(in: plan)?.title == "Push")
        _ = try finishedWorkout(routines[0], daysAgo: 5, [(80, 8)])
        #expect(ledger.nextRoutine(in: plan)?.title == "Pull")
        // Days missed don't matter; after Legs it wraps to Push.
        _ = try finishedWorkout(routines[2], daysAgo: 1, [(80, 8)])
        #expect(ledger.nextRoutine(in: plan)?.title == "Push")
        #expect(throws: ActionError.self) { try engine.perform(CreatePlan(title: "Empty", routines: []), by: .user) }
    }

    @Test func monthHeatmapHasOneCellPerDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        _ = try finishedWorkout(daysAgo: 0, [(100, 10)])
        _ = try finishedWorkout(daysAgo: 1, [(50, 10)])
        let month = ledger.month(containing: start, calendar: calendar)
        let range = try #require(calendar.range(of: .day, in: .month, for: start))
        #expect(month.count == range.count)
        let today = try #require(month.first { calendar.isDate($0.day, inSameDayAs: start) })
        #expect(today.sessions == 1 && today.volume == 1000)
        #expect(month.filter { $0.sessions > 0 }.count == (calendar.component(.day, from: start) > 1 ? 2 : 1))
        #expect(month.allSatisfy { (0 ... 1.5).contains($0.relative) })
    }

    // MARK: Seed library and catalog upgrades

    @Test func exerciseLibraryIsConsistent() {
        let seeds = ExerciseLibrary.seeds
        let keys = Set(seeds.map(\.key))
        #expect(keys.count == seeds.count)
        #expect(seeds.count >= 69)
        #expect(seeds.allSatisfy { !$0.primary.isEmpty && $0.repRange.lowerBound >= 1 && !$0.cue.isEmpty })
        #expect(seeds.compactMap(\.variantOf).allSatisfy(keys.contains))
        #expect(seeds.allSatisfy { Set($0.primary).isDisjoint(with: $0.secondary) })
        #expect(keys.isSuperset(of: ["benchPress", "overheadPress", "backSquat", "deadlift"]))
    }

    @Test func seedingUpgradesUneditedSystemFormulasAndRenamesRoutine() throws {
        let context = container.mainContext
        let setClass = try #require(classes[.set])
        let e1rm = try #require(setClass.ownFields?.first { $0.key == "e1rm" })
        e1rm.expression = "weight * (1 + reps / 30)"
        try #require(classes[.routine]).name = "Plan"
        try SystemCatalog.seed(in: context)
        #expect(e1rm.expression == SystemCatalog.honestE1RM)
        #expect(classes[.routine]?.name == "Routine")

        // A formula the person changed is left alone.
        e1rm.expression = "weight * (36 / (37 - reps))"
        try SystemCatalog.seed(in: context)
        #expect(e1rm.expression == "weight * (36 / (37 - reps))")
    }
}
