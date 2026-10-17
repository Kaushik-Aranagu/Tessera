import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct ExportTests {
    @Test func exportRestoresEverythingIntoAnEmptyStore() throws {
        let source = TesseraSchema.makeContainer(inMemory: true)
        let classes = try SystemCatalog.seed(in: source.mainContext)
        let store = ObjectStore(context: source.mainContext)
        let engine = ActionEngine(store: store, classes: classes)
        let bench = try #require(classes[.benchPress])
        let paused = ClassDef(name: "Paused Bench Press", parent: bench)
        source.mainContext.insert(paused)
        let chest = try store.create(#require(classes[.muscle]), title: "Chest")
        try store.setLinks("primaryMuscles", on: store.ensureClassObject(of: bench), to: [chest])
        let routine = try engine.perform(CreateRoutine(title: "Push Day A"), by: .user).output
        try engine.perform(AddSlot(routine: routine.id, exercise: paused.id), by: .user)
        let workout = try engine.perform(StartRoutine(routine: routine.id), by: .user).output
        let entry = try #require(workout.orderedChildren.first)
        try engine.perform(LogSet(entry: entry.id, weight: 80, reps: 8, rpe: 8), by: .tess)
        try engine.perform(FinishWorkout(workout: workout.id), by: .user)
        try source.mainContext.save()

        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let data = try TesseraExport(context: source.mainContext, maskingPrivate: false).encoded()
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("\"format\" : \"tessera-export\""))
        #expect(text.contains("Paused Bench Press"))

        let target = TesseraSchema.makeContainer(inMemory: true)
        try TesseraExport.decode(data).restore(into: target.mainContext)
        let restored = ObjectStore(context: target.mainContext)
        let restoredClasses = try SystemCatalog.existing(in: target.mainContext)
        let ledger = TrainingLedger(store: restored, classes: restoredClasses)
        let restoredBench = try #require(restoredClasses[.benchPress])

        // Inheritance, class objects, history, records and the op log all survive with the same ids.
        #expect(ledger.records(for: restoredBench).bestE1RM?.weight == 80)
        let restoredPaused = try #require(restored.classDef(id: paused.id))
        #expect(restored.linkedObjects("primaryMuscles", ofClass: restoredPaused).map(\.title) == ["Chest"])
        let restoredEngine = ActionEngine(store: restored, classes: restoredClasses)
        #expect(restoredEngine.history().map(\.summary).contains("Logged paused bench press 80 × 8"))
        #expect(restoredEngine.history().count == ActionEngine(store: store, classes: classes).history().count)
        // Undo still works on restored history.
        let logged = try #require(restoredEngine.history().first { $0.action == "logSet" })
        restoredEngine.undo(logged)
        #expect(ledger.records(for: restoredBench).isEmpty)
        // Re-exporting gives the same content.
        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let again = try TesseraExport(context: target.mainContext, maskingPrivate: false)
        let original = try TesseraExport.decode(data)
        #expect(again.objects.count == original.objects.count && again.links.count == original.links.count)
    }

    @Test func restoreRefusesANonEmptyStoreOrAForeignFile() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        try SystemCatalog.seed(in: container.mainContext)
        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let export = try TesseraExport(context: container.mainContext, maskingPrivate: false)
        #expect(throws: ExportError.storeNotEmpty) { try export.restore(into: container.mainContext) }
        #expect(throws: ExportError.notAnExport) { try TesseraExport.decode(Data("{}".utf8)) }
        var future = export
        future.version = 99
        #expect(throws: ExportError.newerVersion(99)) { try TesseraExport.decode(future.encoded()) }
    }
}
