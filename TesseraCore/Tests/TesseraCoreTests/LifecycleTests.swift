import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct LifecycleTests {
    @Test func theAppNeedsNothingButTheStore() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        #expect(store.classDef(named: "Bench Press")?.id == classes[.benchPress]?.id)
        #expect(store.allClasses().count > ExerciseLibrary.seeds.count)

        let custom = store.createClass(name: "Paused Bench Press", parent: classes[.benchPress])
        #expect(store.lineage(of: custom).dropLast().last?.id == classes[.benchPress]?.id)
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateTask(title: "Stretch"), by: .user)
        store.save()

        store.resetUserData()
        #expect(store.classDef(named: "Paused Bench Press") == nil)
        #expect(try store.objects(of: #require(classes[.task])).isEmpty)
        #expect(engine.history().isEmpty)
        #expect(store.classDef(named: "Bench Press") != nil)
    }
}
