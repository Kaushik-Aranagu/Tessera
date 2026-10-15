import Foundation
import SwiftData
@testable import Tessera
import Testing

@MainActor
struct ObjectModelTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    var context: ModelContext {
        container.mainContext
    }

    var store: ObjectStore {
        ObjectStore(context: context)
    }

    // MARK: Inheritance

    @Test func benchPressInheritsTheWholeChain() throws {
        let classes = try SystemCatalog.seed(in: context)
        let bench = try #require(classes[.benchPress])

        #expect(ClassResolver.lineage(of: bench).map(\.name) ==
            ["Thing", "Activity", "Exercise", "Strength Exercise", "Barbell Lift", "Bench Press"])
        #expect(ClassResolver.effectiveFields(of: bench).map(\.key) ==
            ["notes", "primaryMuscles", "equipment", "restSeconds"])
        #expect(try ClassResolver.isSubclass(bench, of: #require(classes[.exercise])))
        #expect(try !ClassResolver.isSubclass(#require(classes[.exercise]), of: bench))
        #expect(ClassResolver.traits(of: bench) == [.measurable])
    }

    @Test func childOverridesInheritedDefaultButKeepsFieldIdentity() throws {
        let classes = try SystemCatalog.seed(in: context)
        let exercise = try #require(classes[.exercise])
        let strength = try #require(classes[.strengthExercise])
        let bench = try #require(classes[.benchPress])
        let rest = { (classDef: ClassDef) in ClassResolver.field("restSeconds", of: classDef) }

        #expect(rest(exercise)?.defaultValue == .duration(90))
        #expect(rest(strength)?.defaultValue == .duration(120))
        #expect(rest(bench)?.defaultValue == .duration(180))
        // Same storage id all the way down, so values never fork per subclass.
        #expect(rest(bench)?.id == rest(exercise)?.id)
        #expect(rest(bench)?.declaringClassID == exercise.id)

        // An explicit value wins over every default.
        let myBench = store.create(bench, title: "Paused bench")
        #expect(store.value("restSeconds", of: myBench) == .duration(180))
        try store.set("restSeconds", to: .duration(240), on: myBench)
        #expect(store.value("restSeconds", of: myBench) == .duration(240))
    }

    @Test func userClassesExtendSystemClasses() throws {
        let classes = try SystemCatalog.seed(in: context)
        let lift = try #require(classes[.barbellLift])
        let squat = ClassDef(name: "Back Squat", parent: lift)
        context.insert(squat)
        let depth = FieldDef(name: "Depth", key: "depth", kind: .choice)
        depth.enumOptions = ["parallel", "below"]
        depth.owner = squat
        context.insert(depth)

        #expect(ClassResolver.effectiveFields(of: squat).map(\.key).suffix(2) == ["restSeconds", "depth"])
        #expect(ClassResolver.field("restSeconds", of: squat)?.defaultValue == .duration(180))
    }

    @Test func lineageSurvivesACycle() {
        let first = ClassDef(name: "A")
        let second = ClassDef(name: "B", parent: first)
        context.insert(first)
        context.insert(second)
        first.parent = second

        #expect(ClassResolver.lineage(of: second).count == 2)
    }

    // MARK: Computed fields

    @Test func setComputesEstimatedOneRepMax() throws {
        let classes = try SystemCatalog.seed(in: context)
        let set = try store.create(#require(classes[.set]))
        #expect(store.value("e1rm", of: set) == nil)

        try store.set("weight", to: .mass(100), on: set)
        try store.set("reps", to: .number(5), on: set)
        let e1rm = try #require(store.number("e1rm", of: set))
        #expect(abs(e1rm - 116.6667) < 0.001)

        #expect(throws: ObjectStore.StoreError.self) { try store.set("e1rm", to: .number(1), on: set) }
    }

    @Test func expressionParsingAndEvaluation() throws {
        let expression = try Expression.parse("weight * (1 + reps / 30) - -2")
        #expect(expression.variables == ["weight", "reps"])
        #expect(expression.evaluate { ["weight": 60, "reps": 30][$0] } == 122)
        #expect(try Expression.parse("1 / 0").evaluate { _ in nil } == nil)
        #expect(throws: Expression.ParseError.self) { try Expression.parse("2 +") }
        #expect(throws: Expression.ParseError.self) { try Expression.parse("2 $ 3") }
    }

    // MARK: Composition

    @Test func workoutComposesEntriesAndSetsAndCascades() throws {
        let classes = try SystemCatalog.seed(in: context)
        let workout = try store.create(#require(classes[.workout]), title: "Push day")
        let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: classes[.benchPress])
        let setClass = try #require(classes[.set])
        let sets = (1 ... 3).map { _ in store.create(setClass, parent: entry) }
        try context.save()

        #expect(workout.orderedChildren.map(\.id) == [entry.id])
        #expect(entry.orderedChildren.map(\.id) == sets.map(\.id))
        #expect(try store.ancestor(of: sets[2], ofClass: #require(classes[.workout]))?.id == workout.id)

        store.softDelete(workout)
        #expect(sets.map(\.isDeleted) == [true, true, true])
        store.restore(workout)
        #expect(sets.map(\.isDeleted) == [false, false, false])

        context.delete(workout)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<ObjectRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ObjectLink>()) == 0)
    }

    // MARK: Links & backlinks

    @Test func backlinksToObjectsAndClasses() throws {
        let classes = try SystemCatalog.seed(in: context)
        let chest = try store.create(#require(classes[.muscle]), title: "Chest")
        let triceps = try store.create(#require(classes[.muscle]), title: "Triceps")
        let note = try store.create(#require(classes[.note]))

        // A user-defined exercise object linking to muscles.
        let dip = try store.create(#require(classes[.exercise]), title: "Dip")
        try store.setLinks("primaryMuscles", on: dip, to: [chest, triceps])
        #expect(store.linkedObjects("primaryMuscles", of: dip).map(\.title) == ["Chest", "Triceps"])
        #expect(store.backlinks(to: chest).map(\.id) == [dip.id])

        // Targets must match the field's class.
        #expect(throws: ObjectStore.StoreError.targetNotAllowed(field: "primaryMuscles")) {
            try store.setLinks("primaryMuscles", on: dip, to: [note])
        }

        // "Bench Press used in N workouts" — class backlinks through exercise entries.
        let workoutClass = try #require(classes[.workout])
        for title in ["Mon", "Thu"] {
            let workout = store.create(workoutClass, title: title)
            let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
            try store.setClassLink("exercise", on: entry, to: classes[.benchPress])
        }
        let bench = try #require(classes[.benchPress])
        let workouts = store.backlinks(to: bench).compactMap { store.ancestor(of: $0, ofClass: workoutClass) }
        #expect(workouts.map(\.title) == ["Mon", "Thu"])
        #expect(try store.backlinks(to: #require(classes[.barbellLift])).isEmpty)
        #expect(try store.backlinks(to: #require(classes[.barbellLift]), includingSubclasses: true).count == 2)

        // Soft-deleted sources disappear from backlinks; replacing links removes old ones.
        store.softDelete(dip)
        #expect(store.backlinks(to: chest).isEmpty)
        store.restore(dip)
        try store.setLinks("primaryMuscles", on: dip, to: [triceps])
        try context.save()
        #expect(store.backlinks(to: chest).isEmpty)
        #expect(store.backlinks(to: triceps).map(\.id) == [dip.id])
    }

    @Test func classRefRejectsNonSubclasses() throws {
        let classes = try SystemCatalog.seed(in: context)
        let entry = try store.create(#require(classes[.exerciseEntry]))
        #expect(throws: ObjectStore.StoreError.targetNotAllowed(field: "exercise")) {
            try store.setClassLink("exercise", on: entry, to: classes[.muscle])
        }
    }

    // MARK: Seeding

    @Test func seedingIsIdempotentWithStableIDs() throws {
        let first = try SystemCatalog.seed(in: context)
        let second = try SystemCatalog.seed(in: context)
        #expect(try context.fetchCount(FetchDescriptor<ClassDef>()) == SystemCatalog.Key.allCases.count)
        #expect(first.mapValues(\.id) == second.mapValues(\.id))
        #expect(first[.benchPress]?.id == SystemCatalog.stableID("system.benchPress"))

        // A fresh store on another "device" derives the same ids.
        let otherContainer = TesseraSchema.makeContainer(inMemory: true)
        let otherContext = otherContainer.mainContext
        let other = try SystemCatalog.seed(in: otherContext)
        #expect(other[.set].flatMap { ClassResolver.field("e1rm", of: $0)?.id } ==
            first[.set].flatMap { ClassResolver.field("e1rm", of: $0)?.id })
    }

    @Test func reseedingAddsFieldsMissingFromOlderInstalls() throws {
        let classes = try SystemCatalog.seed(in: context)
        let task = try #require(classes[.task])
        let startsAt = try #require(task.ownFields?.first { $0.key == "startsAt" })
        context.delete(startsAt)
        try context.save()
        #expect(ClassResolver.field("startsAt", of: task) == nil)

        try SystemCatalog.seed(in: context)
        #expect(ClassResolver.field("startsAt", of: task)?.id == SystemCatalog.stableID("system.task.startsAt"))
        #expect(task.ownFields?.filter { $0.key == "isDone" }.count == 1)
    }

    @Test func valuesSurviveFieldRename() throws {
        let classes = try SystemCatalog.seed(in: context)
        let set = try store.create(#require(classes[.set]))
        try store.set("reps", to: .number(8), on: set)
        let reps = try #require((classes[.set]?.ownFields ?? []).first { $0.key == "reps" })
        reps.name = "Repetitions"
        #expect(store.value("reps", of: set) == .number(8))
    }
}
