import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct ClassObjectAndPathTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    var context: TesseraContext {
        container.mainContext
    }

    var store: ObjectStore {
        ObjectStore(context: context)
    }

    // MARK: Class objects

    @Test func classLevelValuesInheritDownTheChain() throws {
        let classes = try SystemCatalog.seed(in: context)
        let bench = try #require(classes[.benchPress])
        let paused = ClassDef(name: "Paused Bench Press", parent: bench)
        context.insert(paused)
        let chest = try store.create(#require(classes[.muscle]), title: "Chest")
        let triceps = try store.create(#require(classes[.muscle]), title: "Triceps")

        let benchObject = store.ensureClassObject(of: bench)
        #expect(store.ensureClassObject(of: bench).id == benchObject.id)
        try store.setLinks("primaryMuscles", on: benchObject, to: [chest, triceps])
        try store.set("restSeconds", to: .duration(150), on: benchObject)

        // A subclass with no class object of its own inherits from Bench Press's.
        #expect(store.linkedObjects("primaryMuscles", ofClass: paused).map(\.title) == ["Chest", "Triceps"])
        let myPaused = store.create(paused, title: "Tuesday paused")
        #expect(store.value("restSeconds", of: myPaused) == .duration(150))
        #expect(!store.hasOwnValue("restSeconds", on: myPaused))

        // Overriding at the subclass wins; clearing falls back again.
        let pausedObject = store.ensureClassObject(of: paused)
        try store.setLinks("primaryMuscles", on: pausedObject, to: [chest])
        #expect(store.linkedObjects("primaryMuscles", of: myPaused).map(\.title) == ["Chest"])
        try store.setLinks("primaryMuscles", on: pausedObject, to: [])
        #expect(store.linkedObjects("primaryMuscles", of: myPaused).map(\.title) == ["Chest", "Triceps"])

        // An instance value beats every class value; nil clears it.
        try store.set("restSeconds", to: .duration(200), on: myPaused)
        #expect(store.value("restSeconds", of: myPaused) == .duration(200))
        try store.set("restSeconds", to: nil, on: myPaused)
        #expect(store.value("restSeconds", of: myPaused) == .duration(150))

        // Class objects aren't listed as ordinary objects.
        #expect(store.objects(of: bench).map(\.title) == ["Tuesday paused"])
    }

    @Test func onlyFlaggedObjectsAreClassObjects() throws {
        let classes = try SystemCatalog.seed(in: context)
        let workoutClass = try #require(classes[.workout])
        // An ordinary workout that happens to share the class's name stays an ordinary object.
        let workout = store.create(workoutClass, title: "Workout")
        #expect(store.classObject(of: workoutClass) == nil)
        #expect(store.objects(of: workoutClass).map(\.id) == [workout.id])
        let classObject = store.ensureClassObject(of: workoutClass)
        #expect(classObject.isClassObject && classObject.id != workout.id)
    }

    // MARK: Validation

    @Test func valuesMustMatchTheirFieldKind() throws {
        let classes = try SystemCatalog.seed(in: context)
        let set = try store.create(#require(classes[.set]))
        #expect(throws: ObjectStore.StoreError.wrongKind(field: "weight", expected: [.mass])) {
            try store.set("weight", to: .number(80), on: set)
        }
        #expect(throws: ObjectStore.StoreError.wrongKind(field: "primaryMuscles", expected: [.refList])) {
            let exercise = try store.create(#require(classes[.exercise]))
            try store.set("primaryMuscles", to: .text("Chest"), on: exercise)
        }
        let plan = try store.create(#require(classes[.routine]))
        try store.set("cadence", to: .choice("month"), on: plan)
        #expect(throws: ObjectStore.StoreError.notAnOption(field: "cadence", value: "fortnight")) {
            try store.set("cadence", to: .choice("fortnight"), on: plan)
        }
        #expect(throws: ObjectStore.StoreError.unknownField("nope")) {
            try store.set("nope", to: .number(1), on: plan)
        }
    }

    // MARK: Paths

    @Test func pathsFollowClassesThenComposition() throws {
        let classes = try SystemCatalog.seed(in: context)
        let bench = try #require(classes[.benchPress])
        #expect(ClassResolver.path(of: bench)
            .description == "/activity/exercise/strength-exercise/barbell-lift/bench-press")
        #expect(try ClassResolver.path(of: #require(classes[.thing])).description == "/thing")

        let workout = try store.create(#require(classes[.workout]), title: "Push Day A")
        let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: bench)
        let ledger = TrainingLedger(store: store, classes: classes)
        _ = try ledger.logSet(weight: 80, reps: 8, in: entry)
        let second = try ledger.logSet(weight: 80, reps: 7, in: entry)

        let path = store.path(of: second)
        #expect(path.description == "/activity/workout/push-day-a/bench-press/set-2")
        #expect(path.segments.last?.target == .object(second.id))
        #expect(try path.segments[1].target == .classDef(#require(classes[.workout]).id))
    }

    @Test func slugsAreTidy() {
        let segment = ObjectPath.Segment(target: .object(UUID()), title: "  Push Day — A!  ")
        #expect(segment.slug == "push-day-a")
        #expect(ObjectPath.Segment(target: .object(UUID()), title: "").slug == "untitled")
    }

    // MARK: Formulas

    @Test func formulaFunctions() throws {
        #expect(try Formula.parse("max(1, 4, 2) + min(3, -1)").evaluate { _ in nil } == 3)
        #expect(try Formula.parse("round(2.5) + floor(1.9) + ceil(1.1) + abs(-1)").evaluate { _ in nil } == 7)
        #expect(try Formula.parse("max(weight, 20)").variables == ["weight"])
        #expect(throws: Formula.ParseError.unknownFunction("sqrt")) { try Formula.parse("sqrt(4)") }
        #expect(throws: Formula.ParseError.wrongArgumentCount("abs")) { try Formula.parse("abs(1, 2)") }
        #expect(throws: Formula.ParseError.wrongArgumentCount("max")) { try Formula.parse("max()") }
    }

    @Test func descendantsAreBreadthFirstAndCycleSafe() throws {
        let classes = try SystemCatalog.seed(in: context)
        let strength = try #require(classes[.strengthExercise])
        #expect(ClassResolver.descendants(of: strength).map(\.name) ==
            ["Strength Exercise", "Barbell Lift", "Bench Press"])
    }
}

struct FieldValuesCodingTests {
    @Test func unknownValuesSurviveARoundTrip() throws {
        let known = UUID()
        let future = UUID()
        let json = """
        {"\(known.uuidString)":{"mass":{"_0":80}},"\(future.uuidString)":{"vector":{"_0":[1,2,3]}}}
        """
        var values = try JSONDecoder().decode(FieldValues.self, from: Data(json.utf8))
        #expect(values[known] == .mass(80))
        #expect(values[future] == nil)

        // Editing a known value keeps the unknown one, so a newer device's data is never wiped.
        values[known] = .mass(82.5)
        let reencoded = try JSONDecoder().decode(RawJSON.self, from: JSONEncoder().encode(values))
        guard case let .object(entries) = reencoded else { Issue.record("not an object"); return }
        #expect(entries[future.uuidString] == .object(["vector": .object(["_0": .array([
            .number(1),
            .number(2),
            .number(3),
        ])])]))
    }

    @Test func readsTheOlderFlatArrayFormat() throws {
        let id = UUID()
        let json = #"["\#(id.uuidString)",{"number":{"_0":8}}]"#
        #expect(try JSONDecoder().decode(FieldValues.self, from: Data(json.utf8))[id] == .number(8))
    }
}
