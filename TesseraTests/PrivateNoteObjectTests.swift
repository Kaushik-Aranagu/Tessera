import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// PN-MENTION: a private note reached through a link never shows its text on an object page.
@MainActor
struct PrivateNoteObjectTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func aPrivateNotesFieldsHideItsText() throws {
        let note = try model.engine.perform(CreateNote(body: "Spare key\nUnder the blue pot", isPrivate: true),
                                            by: .user).output
        let classDef = try #require(note.classDef)
        let keys = PropertyList.shownFields(of: classDef, object: note, store: model.store).map(\.key)
        #expect(!keys.contains("body") && !keys.contains("isPrivate") && !keys.contains("title"))

        let plain = try model.engine.perform(CreateNote(body: "Garage gym\nRubber floor"), by: .user).output
        let plainKeys = PropertyList.shownFields(of: classDef, object: plain, store: model.store).map(\.key)
        #expect(plainKeys.contains("body"))
    }
}
