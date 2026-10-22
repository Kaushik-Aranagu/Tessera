import Foundation
import GRDB
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Height, birth year and sex; the weight he types or Health gives; calories as an estimate.
@MainActor
struct MeProfileTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test func nothingIsSaidUntilHeSaysIt() {
        #expect(MeProfile.read(in: store) == MeProfile())
        #expect(store.object(id: MeProfile.objectID) == nil)
        #expect(MeProfile.privacyLine == "That stays on this phone.")
    }

    @Test func eachFieldIsOptionalAndCanBeForgotten() throws {
        let made = try engine.perform(SetMeProfile(heightCm: 182, birthYear: 1990, sex: "female"), by: .user)
        #expect(made.record.summary == "Updated your profile")
        var me = MeProfile.read(in: store)
        #expect(me.heightCm == 182 && me.birthYear == 1990 && me.sex == "female")
        #expect(me.height?.converted(to: "in")?.formatted == "71.7 in")
        #expect(me.age(inYear: 2026) == 36)
        try engine.perform(SetMeProfile(clear: "height, sex"), by: .user)
        me = MeProfile.read(in: store)
        #expect(me.heightCm == nil && me.sex == nil && me.birthYear == 1990)
        try engine.perform(SetMeProfile(heightCm: 170), by: .user)
        #expect(MeProfile.read(in: store).birthYear == 1990)
    }

    @Test func badValuesAreRefused() {
        #expect(throws: (any Error).self) { try engine.perform(SetMeProfile(heightCm: 5), by: .user) }
        #expect(throws: (any Error).self) { try engine.perform(SetMeProfile(birthYear: 1500), by: .user) }
        #expect(throws: (any Error).self) { try engine.perform(SetMeProfile(sex: "robot"), by: .user) }
        #expect(MeProfile.read(in: store) == MeProfile())
    }

    @Test func theActionCarriesNoValueAndIsNotOfferedToTheModel() throws {
        let made = try engine.perform(SetMeProfile(heightCm: 187.25, birthYear: 1973, sex: "male"), by: .user)
        #expect(!made.record.summary.contains("187") && !made.record.summary.contains("1973"))
        #expect(!ActionRegistry.offered.contains { $0.name == "setMeProfile" })
        #expect(ActionRegistry.descriptors.contains { $0.name == "setMeProfile" })
    }

    @Test func typedValuesFollowAWeighInNotesRulesInBackupsAndExports() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "me-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let disk = try ObjectStore(context: TesseraContext(url: dir.appending(path: "tessera.sqlite")))
        let diskEngine = try ActionEngine(store: disk, classes: disk.prepareCatalog())
        // A height with five significant digits cannot turn up by chance in ids and timestamps.
        try diskEngine.perform(SetMeProfile(heightCm: 187.3719, birthYear: 1973, sex: "male"), by: .user)
        disk.save()
        let object = try #require(disk.object(id: MeProfile.objectID))
        #expect(ObjectPrivacy.label(of: object, in: disk, classes: diskEngine.classes) == "Private profile")
        // The shared export shows only the label.
        // Read as values, not characters: a random id or a timestamp can hold "1973" (the Money test had the same
        // flake).
        let shared = try TesseraExport(context: disk.context).encoded()
        #expect(try ExportLeaks.found(["male", "187.3719"], numbers: [187.3719, 1973], in: shared).isEmpty)
        // And the helper does catch a real leak.
        let leaked = try TesseraExport(context: disk.context, maskingPrivate: false).encoded()
        #expect(try !ExportLeaks.found(["male", "187.3719"], numbers: [187.3719, 1973], in: leaked).isEmpty)
        // The local backup keeps every word; the iCloud copy leaves the object and its ops out.
        let local = dir.appending(path: "local.sqlite"), icloud = dir.appending(path: "icloud.sqlite")
        try TesseraBackup.write(from: disk.context, to: local)
        try TesseraBackup.write(from: disk.context, to: icloud, leavingOutPrivate: true)
        func count(_ url: URL, _ sql: String) throws -> Int {
            try DatabaseQueue(path: url.path).read { try Int.fetchOne($0, sql: sql) ?? 0 }
        }
        #expect(try count(local, "SELECT count(*) FROM object WHERE title = 'Me'") == 1)
        #expect(try count(icloud, "SELECT count(*) FROM object WHERE title = 'Me'") == 0)
        #expect(try count(icloud, "SELECT count(*) FROM op WHERE summary = 'Updated your profile'") == 0)
    }

    @Test func aTypedWeightWinsAndAHealthWeightIsNeverStored() throws {
        #expect(MeProfile.weightKg(in: store, healthKg: nil) == nil)
        #expect(MeProfile.weightKg(in: store, healthKg: 71.2) == 71.2)
        #expect(MeProfile.weight(in: store, healthKg: 71.2)?.converted(to: "lb")?.formatted == "157 lb")
        #expect(MeProfile.weightKg(in: store, healthKg: -3) == nil)
        try engine.perform(CreateNote(body: "weighed 80 kg", isPrivate: true), by: .user)
        #expect(MeProfile.weightKg(in: store, healthKg: 71.2) == 80)
        // Passing a Health weight in writes nothing: no profile object, no op.
        #expect(store.object(id: MeProfile.objectID) == nil)
        let before = store.context.all(OpRecord.self).count
        _ = MeProfile.weightKg(in: store, healthKg: 71.2)
        #expect(store.context.all(OpRecord.self).count == before)
    }

    @Test func noClaudeOrSentFileMentionsTheProfileOrCalories() throws {
        let sources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "Sources/TesseraTess")
        let names = try FileManager.default.contentsOfDirectory(atPath: sources.path())
        var checked = 0
        for name in names where name.hasSuffix(".swift") && ["ClaudeTessModel", "PlanWording", "HomeDoneWording",
                                                             "RecipeLinkReader", "TessTools", "TessSentLog",
                                                             "DayNamer"].contains(where: name.hasPrefix)
        {
            let text = try String(contentsOf: sources.appending(path: name), encoding: .utf8)
            for word in ["MeProfile", "CaloriesBurned", "kcal", "heightCm", "birthYear", "healthKg"] {
                #expect(!text.contains(word), "\(name) mentions \(word)")
            }
            checked += 1
        }
        #expect(checked >= 5)
    }
}

struct CaloriesTests {
    @Test func theEstimateIsMetTimesKilogramsTimesHoursRoundedToTen() {
        // 6.0 x 80 kg x 1 h = 480.
        #expect(CaloriesBurned.estimate(met: 6, weightKg: 80, minutes: 60) == 480)
        // 3.5 x 70 x 0.75 = 183.75, to the nearest 10.
        #expect(CaloriesBurned.estimate(met: 3.5, weightKg: 70, minutes: 45) == 180)
        #expect(CaloriesBurned.estimate(met: 3.5, weightKg: 0, minutes: 45) == nil)
        #expect(CaloriesBurned.estimate(met: 3.5, weightKg: 70, minutes: 0) == nil)
        #expect(CaloriesBurned.line(480) == "about 480 kcal")
    }

    @Test func theSwitchIsOffUntilHeTurnsItOn() {
        #expect(CaloriesBurned.reviewKey == "caloriesBurned")
        #expect(!CaloriesBurned.isOn(nil) && !CaloriesBurned.isOn("Off") && CaloriesBurned.isOn("On"))
    }

    @Test func theMetsAreTheCompendiumsUnchanged() {
        let expected: [String: Double] = ["02022": 3.8, "02024": 2.8, "02030": 3.5, "02050": 6.0, "02052": 5.0,
                                          "02054": 3.5, "02056": 3.0, "02058": 9.8, "17018": 4.5]
        #expect(MetTable.metByCode == expected)
        #expect(MetTable.codeByExercise.count == 72)
        #expect(MetTable.codeByExercise.values.allSatisfy { expected[$0] != nil })
        #expect(MetTable.met(forExercise: "Bench Press") == 6.0 && MetTable.met(forExercise: "Back Squat") == 5.0)
        #expect(MetTable.met(forExercise: "Kettlebell Swing") == 9.8 && MetTable.met(forExercise: "Plank") == 2.8)
        #expect(MetTable.met(forExercise: "Dumbbell Curl") == 3.5 && MetTable.met(forExercise: "Unknown Move") == 3.5)
        #expect(CaloriesBurned.aboutLine
            .hasPrefix("Energy costs from the 2024 Adult Compendium of Physical Activities"))
        #expect(CaloriesBurned.aboutLine.hasSuffix("2024;13(1):6-12."))
    }
}

@MainActor
struct WorkoutCaloriesTests {
    @Test func aFinishedWorkoutAndItsExercisesGetAnEstimate() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try ExerciseLibraryInstaller.install(shape: ExerciseLibraryInstaller.chosenShape, store: store,
                                             classes: classes)
        let engine = ActionEngine(store: store, classes: classes)
        let bench = try #require(store.allClasses().first { $0.name == "Bench Press" })
        try engine.perform(LogExercise(exercise: bench.id, weight: 80, reps: 8, sets: 3), by: .user)
        let workoutClass = try #require(classes[.workout])
        let workout = try #require(store.objects(of: workoutClass).first)
        // Unfinished: no estimate.
        #expect(CaloriesBurned.forWorkout(workout, store: store, weightKg: 80) == nil)
        let start = Date(timeIntervalSince1970: 1_792_000_000)
        try store.set("startedAt", to: .date(start), on: workout)
        try store.set("endedAt", to: .date(start.addingTimeInterval(3600)), on: workout)
        // 6.0 x 80 x 1 h = 480; one exercise, so the exercise is the workout.
        #expect(CaloriesBurned.forWorkout(workout, store: store, weightKg: 80) == 480)
        let entry = try #require(workout.orderedChildren.first)
        #expect(CaloriesBurned.forExercise(entry, in: workout, store: store, weightKg: 80) == 480)
        #expect(CaloriesBurned.forWorkout(workout, store: store, weightKg: nil) == nil)
        // A workout left open for a day is not estimated.
        try store.set("endedAt", to: .date(start.addingTimeInterval(86400)), on: workout)
        #expect(CaloriesBurned.forWorkout(workout, store: store, weightKg: 80) == nil)
    }
}
