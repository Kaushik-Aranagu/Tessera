import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

@MainActor
struct ExerciseLibraryTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let engine: ActionEngine
    let ledger: TrainingLedger

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
        ledger = TrainingLedger(store: store, classes: classes)
    }

    @Test func patternSpineInstallsEveryExerciseOnce() throws {
        let installed = try ExerciseLibraryInstaller.install(shape: .patternSpine, store: store, classes: classes)
        #expect(installed.count == ExerciseLibrary.seeds.count)
        let bench = try #require(classes[.benchPress])
        #expect(installed["benchPress"]?.id == bench.id) // history linked to Bench Press stays put
        #expect(store.lineage(of: bench).map(\.name) ==
            ["Thing", "Activity", "Exercise", "Strength Exercise", "Horizontal Push", "Bench Press"])
        #expect(store.equipmentKind(of: bench) == .barbell)
        let curl = try #require(installed["hammerCurl"])
        #expect(curl.parent?.name == "Curl" && curl.parent?.parent?.name == "Isolation")

        // Idempotent, and cheap on later launches.
        #expect(try ExerciseLibraryInstaller.installIfNeeded(store: store, classes: classes) == false)
        let fresh = TesseraSchema.makeContainer(inMemory: true)
        let freshStore = ObjectStore(context: fresh.mainContext)
        let freshClasses = try SystemCatalog.seed(in: fresh.mainContext)
        #expect(try ExerciseLibraryInstaller.installIfNeeded(store: freshStore, classes: freshClasses) == true)
        #expect(try ExerciseLibraryInstaller.installIfNeeded(store: freshStore, classes: freshClasses) == false)
        let all = container.mainContext.all(ClassDef.self)
        #expect(Set(all.map(\.id)).count == all.count)
        let incline = try #require(installed["inclineDbPress"])
        #expect(all.filter { $0.name == incline.name }.count == 1)
        #expect(try store.objects(of: #require(classes[.muscle])).count == 18)
    }

    @Test func groupsFollowThePatternsThenYours() throws {
        try ExerciseLibraryInstaller.install(shape: .patternSpine, store: store, classes: classes)
        let strength = try #require(classes[.strengthExercise])
        _ = store.createClass(name: "Landmine Press", parent: strength)
        let bench = try #require(classes[.benchPress])
        _ = store.createClass(name: "Paused Bench", parent: bench)
        let groups = store.exerciseGroups(root: classes[.exercise])
        let push = try #require(groups.first { $0.name == "Horizontal Push" })
        // QA E3: a variant shows beside its parent, which stays loggable.
        #expect(push.exercises.contains { $0.name == "Bench Press" })
        #expect(push.exercises.contains { $0.name == "Paused Bench" })
        #expect(push.exercises.map(\.name) == push.exercises.map(\.name).sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        })
        // Groupings (Curl, Isolation) never show as exercises; every seed shows exactly once.
        let shown = groups.flatMap(\.exercises)
        #expect(!shown.contains { $0.name == "Curl" || $0.name == "Isolation" })
        #expect(Set(shown.map(\.id)).count == shown.count)
        #expect(shown.count == ExerciseLibrary.seeds.count + 2)
        #expect(groups.last?.name == "Yours" && groups.last?.exercises.map(\.name) == ["Landmine Press"])
    }

    @Test func equipmentClassShapeIsTheSmallAlternative() throws {
        let installed = try ExerciseLibraryInstaller.install(shape: .equipmentClasses, store: store, classes: classes)
        #expect(installed["benchPress"]?.parent?.id == classes[.barbellLift]?.id)
        #expect(installed["dbBenchPress"]?.parent?.id == classes[.strengthExercise]?.id)
        #expect(installed["dbBenchPress"].flatMap { store.equipmentKind(of: $0) } == .dumbbell)
    }

    @Test func classLevelDataComesFromTheSeed() throws {
        let installed = try ExerciseLibraryInstaller.install(shape: .patternSpine, store: store, classes: classes)
        let incline = try #require(installed["inclineDbPress"])
        let seed = try #require(ExerciseLibrary.seeds.first { $0.key == "inclineDbPress" })
        #expect(store.classValue("repMin", of: incline)?.numericValue == Double(seed.repRange.lowerBound))
        #expect(store.linkedObjects("primaryMuscles", ofClass: incline).map(\.title).sorted() ==
            seed.primary.map(\.name).sorted())
        #expect(store.linkedObjects("secondaryMuscles", ofClass: incline).count == seed.secondary.count)
        let profile = try #require(store.classObject(of: incline))
        #expect(store.linkedClass("variantOf", of: profile)?.id == installed["dbBenchPress"]?.id)
        #expect(store.classValue("pattern", of: incline) == .choice("horizontalPush"))
        #expect(store.loadProfile(for: incline).next(above: 20) == 22.5)
    }

    @Test func progressionComesFromTheEquipmentTrait() throws {
        let installed = try ExerciseLibraryInstaller.install(shape: .patternSpine, store: store, classes: classes)
        func finish(_ exercise: ClassDef, weight: Double, reps: Double) throws {
            let workout = try store.create(#require(classes[.workout]), title: "Day")
            let entry = try engine.perform(AddExercise(workout: workout.id, exercise: exercise.id), by: .user).output
            for _ in 0 ..< 3 {
                try engine.perform(LogSet(entry: entry.id, weight: weight, reps: reps), by: .user)
            }
            try engine.perform(FinishWorkout(workout: workout.id), by: .user)
        }
        // Dumbbell press hits the top of its range: +2 kg, snapped to a real dumbbell.
        let dbBench = try #require(installed["dbBenchPress"])
        let top = try #require(ExerciseLibrary.seeds.first { $0.key == "dbBenchPress" }).repRange.upperBound
        try finish(dbBench, weight: 30, reps: Double(top))
        let target = ledger.nextTarget(for: dbBench)
        #expect(target.weight == 32.5)
        // Barbell bench: +2.5 kg.
        let bench = try #require(classes[.benchPress])
        let benchTop = try #require(ExerciseLibrary.seeds.first { $0.key == "benchPress" }).repRange.upperBound
        try finish(bench, weight: 80, reps: Double(benchTop))
        #expect(ledger.nextTarget(for: bench).weight == 82.5)
        // Records for a variant stay its own.
        #expect(ledger.records(for: bench).bestE1RM?.weight == 80)
    }

    @Test func swapsRankFamilyThenPatternByMuscles() throws {
        let installed = try ExerciseLibraryInstaller.install(shape: .patternSpine, store: store, classes: classes)
        let bench = try #require(classes[.benchPress])
        let swaps = ledger.swapCandidates(for: bench).map(\.name)
        let family = ExerciseLibrary.seeds.filter { $0.family == "BenchPress" && $0.key != "benchPress" }.map(\.name)
        #expect(Set(swaps.prefix(family.count)) == Set(family))
        #expect(try swaps.contains(#require(installed["pushUp"]).name) || swaps.count == 8)
        #expect(try !swaps.contains(#require(installed["backSquat"]).name))
    }

    @Test func tessKnowsTheLibrary() async throws {
        try ExerciseLibraryInstaller.install(shape: .patternSpine, store: store, classes: classes)
        let grammar = TessGrammar(store: store, classes: classes)
        #expect(grammar.resolveExercise("rdl")?.name == "Romanian Deadlift")
        #expect(grammar.resolveExercise("squat")?.name == "Back Squat")
        #expect(grammar.resolveExercise("incline db press")?.name ==
            ExerciseLibrary.seeds.first { $0.key == "inclineDbPress" }?.name)
        let capture = await TessCaptureEngine(engine: engine).capture("3x5 squat 100", context: TessContext())
        #expect(capture.line == "Back Squat 3 × 5 at 100. Added to today.")
    }
}
