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

    /// QA on #1063: the word under a week dab is the routine's short name as shown, never its first raw word.
    @Test func theWeekCaptionNeverShowsAPrivateRoutinesWord() {
        #expect(DayColumn.caption("Knee rehab day", store: model.store) == "Private")
        #expect(DayColumn.caption("Push Day A", store: model.store) == "Push")
    }

    /// OL28 / OL29: a link to a deleted object opens "Not on this phone anymore.", never a blank page.
    @Test func aDeletedObjectOpensAsGone() throws {
        let note = try model.engine.perform(CreateNote(body: "milk run"), by: .user).output
        #expect(ObjectPage.live(note) != nil)
        try model.engine.perform(DeleteObject(object: note.id), by: .user)
        #expect(ObjectPage.live(model.object(note.id)) == nil)
        #expect(ObjectPage.live(nil) == nil)
        #expect(ObjectPageCopy.gone == "Not on this phone anymore.")
    }

    /// OL35: New subclass goes through the op log, says "New Bench Press, made." and its UNDO takes the class back.
    @Test func newSubclassIsMadeWithAReceiptAndUndoes() throws {
        let bench = try #require(model.classDef(.benchPress))
        let result = try model.engine.perform(CreateClass(parent: bench.id), by: .user)
        #expect(ObjectPageCopy.made(result.output.name) == "New Bench Press, made.")
        #expect(model.classDef(id: result.output.id) != nil)
        _ = model.engine.undo(result.record)
        #expect(model.classDef(id: result.output.id) == nil)
    }

    /// Product on class names: plain by default; a name that trips the walled-words check reads "Private class".
    @Test func aWalledClassNameReadsPrivateClass() throws {
        let bench = try #require(model.classDef(.benchPress))
        #expect(ClassTitle.shown(bench, in: model.store) == "Bench Press")
        let result = try model.engine.perform(CreateClass(parent: bench.id, name: "Rent 1200 lifts"), by: .user)
        #expect(ClassTitle.shown(result.output, in: model.store) == "Private class")
    }
}
