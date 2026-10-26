import Foundation
@testable import TesseraCore
import Testing

@MainActor
struct NoteTests {
    @Test func atLinksBecomeBacklinks() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let notes = NoteList(store: store, classes: classes)
        let bench = try #require(classes[.benchPress])
        let plan = try #require(store.object(id: StarterContent.planID))
        let pushA = try #require(store.linkedObjects("routines", of: plan).first)

        let note = try engine.perform(CreateNote(body: "@Bench Press felt heavy today.\nMaybe deload @[Push A]?"),
                                      by: .user).output
        #expect(note.title == "@Bench Press felt heavy today.")
        #expect(store.linkedObjects("about", of: note).count == 2)
        #expect(notes.notes(about: bench).map(\.id) == [note.id])
        #expect(notes.notes(about: pushA).map(\.id) == [note.id])
        #expect(notes.recent().map(\.id) == [note.id])

        // Editing the text re-links; undo puts the links back.
        let edit = try engine.perform(EditNote(note: note.id, body: "Felt fine on @[Push A]"), by: .user)
        #expect(notes.notes(about: bench).isEmpty)
        engine.undo(edit.record)
        #expect(notes.notes(about: bench).map(\.id) == [note.id])
        #expect(throws: ActionError.self) { try engine.perform(CreateNote(body: "   "), by: .user) }
    }
}
