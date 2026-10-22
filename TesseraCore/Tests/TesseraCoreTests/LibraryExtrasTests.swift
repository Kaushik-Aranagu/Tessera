import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct LibraryExtrasTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let engine: ActionEngine

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
    }

    // MARK: The data

    @Test func fortyExtrasWithMusclesEquipmentAndOurOwnCues() {
        let extras = LibraryExtras.all
        #expect(extras.count == 40)
        #expect(Set(extras.map(\.id)).count == 40)
        #expect(Set(extras.map(\.name)).count == 40)
        for extra in extras {
            #expect(!extra.primary.isEmpty, "\(extra.name) has no primary muscle")
            #expect(!extra.cue.isEmpty && !extra.sourceID.isEmpty)
            #expect(!extra.cue.contains("|"))
        }
    }

    @Test func everyMuscleWordInTheTableIsOneOfTheEighteen() {
        // A misspelt muscle would be dropped silently by the parser; count the words in the raw table instead.
        var words = 0
        for line in LibraryExtras.exerciseTable.split(separator: "\n") {
            let parts = line.split(separator: "|", omittingEmptySubsequences: false)
            for field in [parts[3], parts[4]] where !field.isEmpty {
                words += field.split(separator: ",").count
            }
        }
        let parsed = LibraryExtras.all.reduce(0) { $0 + $1.primary.count + $1.secondary.count }
        #expect(parsed == words)
    }

    @Test func noExtraRepeatsOneWeAlreadyWrote() {
        let ours = Set(ExerciseLibrary.seeds.flatMap { [$0.name] + $0.aliases }.map(LibraryExtras.normalised))
        for extra in LibraryExtras.all {
            #expect(!ours.contains(LibraryExtras.normalised(extra.name)), "\(extra.name) is already built in")
        }
    }

    @Test func shouldersAreSplitAndBackIsUpperBack() throws {
        let arnold = try #require(LibraryExtras.exercise(named: "Arnold Press"))
        #expect(arnold.primary == [.frontDelts, .sideDelts])
        let rear = try #require(LibraryExtras.exercise(named: "Bent-Over Rear Delt Raise"))
        #expect(rear.primary == [.rearDelts] && rear.secondary == [.upperBack])
        let upright = try #require(LibraryExtras.exercise(named: "Dumbbell Upright Row"))
        #expect(upright.primary == [.sideDelts, .upperBack])
        let twist = try #require(LibraryExtras.exercise(named: "Russian Twist"))
        #expect(twist.primary == [.obliques])
    }

    // MARK: Search

    @Test func searchByMuscleByEquipmentAndByWords() {
        #expect(LibraryExtras.search(muscle: .obliques).map(\.name).sorted()
            == ["Cable Wood Chop", "Russian Twist", "Side Plank"])
        #expect(LibraryExtras.search(equipment: .band).count == 4)
        #expect(LibraryExtras.search("bands back").map(\.name).contains("Band Pull-Apart"))
        #expect(LibraryExtras.search("bands back").allSatisfy { $0.equipment == .band })
        #expect(LibraryExtras.search("quads")
            .allSatisfy { $0.primary.contains(.quads) || $0.secondary.contains(.quads) })
        // A primary mover ranks before a helper.
        let chest = LibraryExtras.search(muscle: .chest)
        #expect(chest.first.map { $0.primary.contains(.chest) } == true)
        #expect(chest.contains { $0.secondary.contains(.chest) && !$0.primary.contains(.chest) })
        // Name, muscle and equipment in one box.
        #expect(LibraryExtras.search("fly dumbbell").map(\.name).sorted() == ["Dumbbell Fly", "Incline Dumbbell Fly"])
        #expect(LibraryExtras.search("curl", equipment: .cable).isEmpty)
        #expect(LibraryExtras.search("zzz").isEmpty)
        #expect(LibraryExtras.search(place: .home).allSatisfy { $0.place == .home })
    }

    // MARK: The workouts

    @Test func fourteenWorkoutsAndEveryExerciseResolves() {
        let workouts = ReadyWorkouts.all
        #expect(workouts.count == 14)
        for group in ReadyWorkout.Group.allCases {
            let expected = group == .short ? 2 : 3
            #expect(workouts.filter { $0.group == group }.count == expected, "\(group)")
        }
        #expect(Set(workouts.map(\.id)).count == 14)
        for workout in workouts {
            #expect(!workout.slots.isEmpty && !workout.muscles.isEmpty)
            for slot in workout.slots {
                #expect(ReadyWorkouts.details(of: slot.exercise) != nil, "\(workout.title): \(slot.exercise)")
                #expect(slot.repMin <= slot.repMax && slot.sets > 0)
            }
        }
        #expect(workouts.filter { $0.place == .home }.count == 5)
    }

    @Test func workoutsAreFoundByMuscleEquipmentAndPlace() {
        let band = ReadyWorkouts.search(equipment: .band)
        #expect(band.map(\.title) == ["Pull at Home"])
        #expect(ReadyWorkouts.search("biceps", equipment: .band).count == 1)
        #expect(ReadyWorkouts.search(place: .home).count == 5)
        #expect(ReadyWorkouts.search("push").allSatisfy { $0.group == .push })
        #expect(ReadyWorkouts.search(group: .legs, muscle: .calves).count == 3)
        let chestHome = ReadyWorkouts.search(muscle: .chest, equipment: .dumbbell, place: .home)
        #expect(chestHome.contains { $0.title == "Full Body at Home" })
        #expect(ReadyWorkouts.search("hamstrings").contains { $0.title == "Leg Day" })
    }

    // MARK: Copy on first use

    @Test func anExtraIsAdoptedOnceAndIsARealExercise() throws {
        try ExerciseLibraryInstaller.installIfNeeded(store: store, classes: classes)
        let incline = try #require(LibraryExtras.exercise(named: "Incline Push-Up"))
        #expect(LibraryAdopter.adoptedClass(of: incline, store: store) == nil)
        let first = try LibraryAdopter.adopt(incline, store: store, classes: classes)
        let second = try LibraryAdopter.adopt(incline, store: store, classes: classes)
        #expect(first.id == second.id && first.id == LibraryAdopter.classID(for: incline))
        #expect(first.parent?.name == "Horizontal Push")
        #expect(store.equipmentKind(of: first) == .bodyweight)
        let exercise = try #require(classes[.exercise])
        #expect(store.isConcreteExercise(first, root: exercise))
        let profile = try #require(store.classObject(of: first))
        #expect(store.linkedObjects("primaryMuscles", of: profile).map(\.title) == ["Chest"])
        #expect(Set(store.linkedObjects("secondaryMuscles", of: profile).map(\.title)) == ["Triceps", "Front Delts"])
        #expect(store.value("notes", of: profile) == .richText(incline.cue))
        #expect(store.value("logType", of: profile)?.stringValue == "bodyweightPlus")
        // The same id on every device.
        let other = TesseraSchema.makeContainer(inMemory: true)
        let otherStore = ObjectStore(context: other.mainContext)
        let otherClasses = try SystemCatalog.seed(in: other.mainContext)
        let copy = try LibraryAdopter.adopt(incline, store: otherStore, classes: otherClasses)
        #expect(copy.id == first.id)
    }

    @Test func holdsAreLoggedByTimeAndCoreMovesAreCore() throws {
        let side = try #require(LibraryExtras.exercise(named: "Side Plank"))
        #expect(LibraryAdopter.logType(for: side) == .duration)
        #expect(LibraryAdopter.pattern(for: side) == .core)
        let lunge = try #require(LibraryExtras.exercise(named: "Bodyweight Lunge"))
        #expect(LibraryAdopter.pattern(for: lunge) == .lunge)
        let crunch = try #require(LibraryExtras.exercise(named: "Crunch"))
        #expect(LibraryAdopter.logType(for: crunch) == .repsOnly)
    }

    @Test func addingAWorkoutMakesARoutineThatUndoes() throws {
        let workout = try #require(ReadyWorkouts.workout(id: "W06")) // Pull at Home: extras and built-ins
        let routine = try ReadyWorkouts.add(workout, using: engine)
        #expect(routine.title == "Pull at Home")
        #expect(RoutineKind.of(routine, in: store) == .pull)
        let slots = (routine.children ?? []).filter { !$0.isDeleted }
        #expect(slots.count == workout.slots.count)
        let names = slots.compactMap { store.linkedClass("exercise", of: $0)?.name }
        #expect(names.contains("Inverted Row") && names.contains("One-Arm Dumbbell Row"))
        let inverted = try #require(LibraryExtras.exercise(named: "Inverted Row"))
        #expect(LibraryAdopter.adoptedClass(of: inverted, store: store) != nil)
        let slot = try #require(slots.first)
        #expect(store.value("sets", of: slot)?.numericValue == Double(workout.slots[0].sets))
    }

    @Test func aWorkoutOfBuiltInsAdoptsNothing() throws {
        let before = store.allClasses().count
        let workout = try #require(ReadyWorkouts.workout(id: "W04")) // Pull Day
        try ReadyWorkouts.add(workout, using: engine)
        let adopted = store.allClasses().filter { $0.packageID == LibraryAdopter.packageID }
        #expect(adopted.isEmpty)
        #expect(store.allClasses().count >= before)
    }

    @Test func benchPressStaysTheOneBenchPress() throws {
        let workout = try #require(ReadyWorkouts.workout(id: "W01"))
        let routine = try ReadyWorkouts.add(workout, using: engine)
        let first = try #require((routine.children ?? []).first)
        #expect(store.linkedClass("exercise", of: first)?.id == classes[.benchPress]?.id)
    }
}

@MainActor
struct LibraryLowsTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let engine: ActionEngine

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
    }

    private func adopted() -> [ClassDef] {
        store.allClasses().filter { $0.packageID == LibraryAdopter.packageID }
    }

    @Test func undoingAWorkoutLetsTheUnusedCopiesGo() throws {
        let workout = try #require(ReadyWorkouts.workout(id: "W06"))
        let added = try ReadyWorkouts.addWithRecords(workout, using: engine)
        let count = adopted().count
        #expect(count > 0)
        // Still in use: nothing is removed.
        #expect(LibraryAdopter.removeUnused(store: store) == 0)
        for record in added.records.reversed() {
            engine.undo(record)
        }
        #expect(LibraryAdopter.removeUnused(store: store) == count)
        #expect(adopted().isEmpty)
        // Adding it again works from a clean start.
        _ = try ReadyWorkouts.add(workout, using: engine)
        #expect(adopted().count == count)
    }

    @Test func aCopyThatIsStillScheduledStays() throws {
        let one = try #require(ReadyWorkouts.workout(id: "W06"))
        let two = try #require(ReadyWorkouts.workout(id: "W14"))
        let first = try ReadyWorkouts.addWithRecords(one, using: engine)
        _ = try ReadyWorkouts.add(two, using: engine)
        for record in first.records.reversed() {
            engine.undo(record)
        }
        LibraryAdopter.removeUnused(store: store)
        let names = Set(adopted().map(\.name))
        #expect(names.contains("Superman")) // both workouts use it
        #expect(!names.contains("Band Pull-Apart")) // only the first did
    }

    @Test func aFailedAdoptionLeavesNothingBehind() throws {
        let extra = try #require(LibraryExtras.exercise(named: "Dead Bug"))
        let before = store.allClasses().count
        // A failure midway, after the class exists, takes the half-built class back.
        struct Boom: Error {}
        #expect(throws: Boom.self) {
            try LibraryAdopter.adopt(extra, store: store, classes: classes, afterCreate: { throw Boom() })
        }
        #expect(store.allClasses().count == before)
        #expect(LibraryAdopter.adoptedClass(of: extra, store: store) == nil)
        #expect(store.allClasses().filter { $0.name == "Dead Bug" }.isEmpty)
        // No strength class: it throws before making anything.
        var none = classes
        none[.strengthExercise] = nil
        #expect(throws: (any Error).self) { try LibraryAdopter.adopt(extra, store: store, classes: none) }
        #expect(store.allClasses().count == before)
        #expect(LibraryAdopter.adoptedClass(of: extra, store: store) == nil)
    }

    @Test func aWorkoutWithAnUnknownExerciseMakesNothing() throws {
        let real = try #require(ReadyWorkouts.workout(id: "W06"))
        let bad = ReadyWorkout(id: "X", title: "Broken", group: .short, place: .home, level: .beginner, minutes: 10,
                               about: "", slots: real.slots + [.init(
                                   exercise: "Nonesuch",
                                   sets: 3,
                                   repMin: 8,
                                   repMax: 8
                               )])
        let routines = try store.objects(of: #require(classes[.routine])).count
        #expect(throws: ReadyWorkouts.AddError.unknownExercise("Nonesuch")) {
            try ReadyWorkouts.add(bad, using: engine)
        }
        #expect(try store.objects(of: #require(classes[.routine])).count == routines)
        #expect(adopted().isEmpty)
    }

    @Test func theCatalogUpgradeLeavesTheCopiesAlone() throws {
        let extra = try #require(LibraryExtras.exercise(named: "Superman"))
        let copy = try LibraryAdopter.adopt(extra, store: store, classes: classes)
        let parent = copy.parent?.id
        _ = try SystemCatalog.seed(in: container.mainContext)
        try ExerciseLibraryInstaller.installIfNeeded(store: store, classes: classes)
        let again = try #require(LibraryAdopter.adoptedClass(of: extra, store: store))
        #expect(again.packageID == LibraryAdopter.packageID)
        #expect(again.parent?.id == parent)
        #expect(store.allClasses().filter { $0.id == copy.id }.count == 1)
    }

    @Test func readingTheLibraryChangesNothing() {
        let objects = container.mainContext.all(ObjectRecord.self).count
        let classCount = store.allClasses().count
        _ = LibraryExtras.all
        _ = LibraryExtras.search("curl")
        _ = LibraryExtras.search(muscle: .chest, equipment: .dumbbell, place: .gym)
        _ = ReadyWorkouts.all.map(\.muscles)
        _ = ReadyWorkouts.search("legs")
        _ = ReadyWorkouts.search(equipment: .band)
        #expect(container.mainContext.all(ObjectRecord.self).count == objects)
        #expect(store.allClasses().count == classCount)
    }

    @Test func anEditedCopyIsHisAndStaysEvenWhenNothingUsesIt() throws {
        let one = try #require(LibraryExtras.exercise(named: "Superman"))
        let two = try #require(LibraryExtras.exercise(named: "Dead Bug"))
        let three = try #require(LibraryExtras.exercise(named: "Crunch"))
        let renamed = try LibraryAdopter.adopt(one, store: store, classes: classes)
        let retuned = try LibraryAdopter.adopt(two, store: store, classes: classes)
        _ = try LibraryAdopter.adopt(three, store: store, classes: classes)
        renamed.name = "My Superman"
        try store.set("repMax", to: .number(20), on: store.ensureClassObject(of: retuned))
        #expect(LibraryAdopter.removeUnused(store: store) == 1) // only the untouched Crunch goes
        #expect(LibraryAdopter.adoptedClass(of: one, store: store) != nil)
        #expect(LibraryAdopter.adoptedClass(of: two, store: store) != nil)
        #expect(LibraryAdopter.adoptedClass(of: three, store: store) == nil)
    }
}
