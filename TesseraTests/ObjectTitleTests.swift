@testable import Tessera
import TesseraCore
import Testing

/// Hunt 22 OL03 / OL11 / OL02: every row that names an object reads one shown title: its private label, else its
/// title, else its class name and place. Never blank, never "Untitled", never a private workout's words.
@MainActor
struct ObjectTitleTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func shown(_ object: ObjectRecord) -> String {
        ObjectTitle.shown(object, in: model.store, classes: model.classes)
    }

    @Test func linkRowsNeverShowRawWorkoutTitleOrBlank() throws {
        let workoutClass = try #require(model.classes[.workout])
        let rehab = try model.store.create(workoutClass, title: "Knee rehab day")
        #expect(shown(rehab) == "Private workout")
        let routine = try model.store.create(#require(model.classes[.routine]), title: "Therapy legs")
        #expect(shown(routine) == "Private workout")
        let push = try model.store.create(workoutClass, title: "Push A")
        #expect(shown(push) == "Push A")
    }

    @Test func anEmptyTitleReadsItsClassAndPlace() throws {
        let workout = try model.store.create(#require(model.classes[.workout]), title: "Push A")
        let entryClass = try #require(model.classes[.exerciseEntry])
        _ = try model.store.create(entryClass, title: "Bench", parent: workout)
        let second = try model.store.create(entryClass, title: "  ", parent: workout)
        #expect(shown(second) == "\(entryClass.name) 2")
        let loose = try model.store.create(#require(model.classes[.note]), title: "")
        #expect(shown(loose) == model.classes[.note]?.name)
        #expect(![shown(second), shown(loose)].contains { $0.isEmpty || $0 == "Untitled" })
    }
}
