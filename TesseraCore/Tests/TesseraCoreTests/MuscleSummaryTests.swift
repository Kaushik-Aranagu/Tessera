import Foundation
@testable import TesseraCore
import Testing

/// Design sheet 107: the muscle words for each seeded day.
@MainActor
struct MuscleSummaryTests {
    func seeded() throws -> (ObjectStore, [String: ObjectRecord]) {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try ExerciseLibraryInstaller.install(
            shape: ExerciseLibraryInstaller.chosenShape,
            store: store,
            classes: classes
        )
        try StarterContent.installIfNeeded(store: store, classes: classes)
        let plan = try #require(store.object(id: StarterContent.planID))
        return (
            store,
            Dictionary(uniqueKeysWithValues: store.linkedObjects("routines", of: plan).map { ($0.title, $0) })
        )
    }

    @Test(arguments: [
        ("Push A", "chest, shoulders and triceps"), ("Pull A", "back, shoulders and biceps"),
        ("Legs A", "quads, glutes and hamstrings"), ("Push B", "chest, shoulders and triceps"),
        ("Pull B", "back, shoulders and biceps"), ("Legs B", "quads, glutes and calves"),
    ])
    func eachSeededDayNamesItsTopThreeMuscles(_ day: String, _ expected: String) throws {
        let (store, routines) = try seeded()
        let routine = try #require(routines[day])
        #expect(MuscleSummary.works(of: routine, store: store) == expected)
    }

    @Test func theFoldsAndTheHandJoin() {
        #expect(MuscleSummary.word(for: "Lats") == "back" && MuscleSummary.word(for: "Lower Back") == "back")
        #expect(MuscleSummary.word(for: "Rear Delts") == "shoulders" && MuscleSummary.word(for: "Chest") == "chest")
        #expect(MuscleSummary.word(for: "Adductors") == "inner thighs")
        #expect(MuscleSummary.sentence(["chest", "shoulders", "triceps"]) == "chest, shoulders and triceps")
        #expect(MuscleSummary.sentence(["chest", "back"]) == "chest and back")
        #expect(MuscleSummary.sentence(["chest"]) == "chest" && MuscleSummary.sentence([]) == "")
    }

    @Test func aPrivateRoutineGivesNoSentence() throws {
        let (store, routines) = try seeded()
        let routine = try #require(routines["Push A"])
        routine.title = "Knee rehab day"
        #expect(MuscleSummary.works(of: routine, store: store) == nil)
    }
}
