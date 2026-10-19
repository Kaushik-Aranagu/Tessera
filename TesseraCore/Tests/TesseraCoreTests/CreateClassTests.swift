import Foundation
@testable import TesseraCore
import Testing

/// OL35: a new subclass is an op-log entry, so its 10 s UNDO takes it back.
@MainActor
struct CreateClassTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func newSubclassIsLoggedAndUndoRemovesIt() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let parent = try #require(engine.classes[.exercise])
        let before = store.allClasses().count
        let made = try engine.perform(CreateClass(parent: parent.id), by: .user)
        let subclass = made.output
        #expect(subclass.name == "New \(parent.name)" && subclass.parent?.id == parent.id)
        #expect(store.allClasses().count == before + 1)
        #expect(made.record.ops == [.createClass(classID: subclass.id, parent: parent.id, name: subclass.name,
                                                 symbolName: subclass.symbolName, colorRole: subclass.colorRole)])
        #expect(made.record.summary == "Created \(subclass.name)")

        engine.undo(made.record)
        #expect(store.classDef(id: subclass.id) == nil && store.allClasses().count == before)
        #expect(!(parent.subclasses ?? []).contains { $0.id == subclass.id })
        // Redo brings the same class back, with the same id.
        engine.redo(made.record)
        let back = try #require(store.classDef(id: subclass.id))
        #expect(back.name == subclass.name && back.parent?.id == parent.id)
    }

    @Test func aClassInUseCannotBeUndoneAway() throws {
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let parent = try #require(engine.classes[.note])
        let made = try engine.perform(CreateClass(parent: parent.id, name: "Idea"), by: .user)
        store.create(made.output, title: "x")
        engine.undo(made.record)
        #expect(store.classDef(id: made.output.id) != nil, "a class with an object must stay")
    }
}
