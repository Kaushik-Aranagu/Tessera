import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// PN-MENTION: a plain note opens as the note editor; a private note stays on the masked object page.
@MainActor
struct PrivateNoteObjectTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func aPrivateNoteStaysOnTheMaskedPage() throws {
        let secret = try model.engine.perform(CreateNote(body: "Spare key\nUnder the blue pot", isPrivate: true),
                                              by: .user).output
        #expect(!ObjectPage.opensAsNote(secret, model: model))
        #expect(ObjectPrivacy.label(of: secret, in: model.store, classes: model.classes) == "Private note")

        let plain = try model.engine.perform(CreateNote(body: "Garage gym\nRubber floor"), by: .user).output
        #expect(ObjectPage.opensAsNote(plain, model: model))
    }
}
