import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

@MainActor
struct SchemaFollowupTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let store: ObjectStore
    let engine: ActionEngine

    init() throws {
        store = ObjectStore(context: container.mainContext)
        classes = try SystemCatalog.seed(in: container.mainContext)
        engine = ActionEngine(store: store, classes: classes)
    }

    // MARK: UUIDv7

    @Test func newIdsAreTimeOrderedVersion7() throws {
        let early = UUID.v7(at: Date(timeIntervalSince1970: 1_700_000_000))
        let late = UUID.v7(at: Date(timeIntervalSince1970: 1_700_000_001))
        #expect(early.uuidString < late.uuidString)
        #expect(early.v7Date == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(UUID().v7Date == nil)
        #expect(Set((0 ..< 1000).map { _ in UUID.v7() }).count == 1000)

        let note = try store.create(#require(classes[.note]), title: "x")
        #expect(note.id.v7Date != nil)
        let record = try engine.perform(CreateTask(title: "y"), by: .user).record
        #expect(record.id.v7Date != nil)
        // System classes keep their deterministic ids so devices agree.
        #expect(classes[.benchPress]?.id == SystemCatalog.stableID("system.benchPress"))
    }

    // MARK: Units

    @Test func massIsStoredInKilogramsAndShownInTheEnteredUnit() throws {
        #expect(MassUnit.pounds.toKilograms(225) == 225 / MassUnit.poundsPerKilogram)
        #expect(MassUnit.pounds.fromKilograms(80) == 176.5)
        #expect(MassUnit.pounds.format(kilograms: 102.058) == "225 lb")
        #expect(MassUnit.kilograms.format(kilograms: 82.5) == "82.5 kg")
        #expect(MassUnit(parsing: "LBS") == .pounds)

        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        let result = try engine.perform(LogSet(entry: entry.id, weight: 225, reps: 5, unit: .pounds), by: .user)
        let set = result.output
        let kilograms = try #require(store.number("weight", of: set))
        #expect(abs(kilograms - 102.058) < 0.001)
        #expect(store.value("enteredUnit", of: set) == .choice("lb"))
        #expect(result.record.summary == "Logged bench press 225 lb × 5")
        // e1RM and records work in kilograms whatever was typed.
        #expect(store.number("e1rm", of: set).map { abs($0 - kilograms * (1 + 5.0 / 30)) < 0.001 } == true)
        // Validation is in kilograms too: 1,000 kg ≈ 2,205 lb.
        #expect(throws: ActionError.self) {
            try engine.perform(LogSet(entry: entry.id, weight: 2300, reps: 1, unit: .pounds), by: .user)
        }
    }

    @Test func tessUnderstandsPounds() async throws {
        let tess = TessCaptureEngine(engine: engine)
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        let entry = try engine.perform(AddExercise(workout: workout.id, exercise: #require(classes[.benchPress]).id),
                                       by: .user).output
        let capture = await tess.capture("185 lb x 5", context: TessContext(entry: entry.id))
        #expect(capture.line == "Set 1 logged. 185 lb × 5.")
        let set = try #require(entry.orderedChildren.first)
        #expect(store.value("enteredUnit", of: set) == .choice("lb"))
        #expect(store.number("weight", of: set).map { abs($0 - 83.915) < 0.01 } == true)
    }

    // MARK: Versioned package with a user overlay

    @Test func packageUpgradesApplyUnderThePersonsEdits() throws {
        let context = container.mainContext
        let bench = try #require(classes[.benchPress])
        let set = try #require(classes[.set])
        #expect(bench.packageID == "system")
        #expect(bench.packageVersion == SystemCatalog.package.version)

        // The person renames Bench Press and a Set field; an older package version is installed.
        bench.name = "Flat Bench"
        bench.markUserModified()
        let reps = try #require(set.ownFields?.first { $0.key == "reps" })
        reps.name = "Repetitions"
        reps.markUserModified()
        let weight = try #require(set.ownFields?.first { $0.key == "weight" })
        weight.name = "Load (old name)"
        let rpe = try #require(set.ownFields?.first { $0.key == "rpe" })
        rpe.name = "Effort (old name)"
        for classDef in try SystemCatalog.existing(in: context).values {
            classDef.packageVersion = 1
        }

        try SystemCatalog.seed(in: context)
        // Edits survive; untouched shipped names are refreshed.
        #expect(bench.name == "Flat Bench")
        #expect(reps.name == "Repetitions")
        #expect(weight.name == "Weight")
        #expect(rpe.name == "RPE")
        #expect(set.packageVersion == SystemCatalog.package.version)
    }
}
