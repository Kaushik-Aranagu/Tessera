import Foundation
@testable import TesseraCore
import Testing

/// Board 0ai mask (Research private-field-mask PM1 to PM20): a private object shows only its label. The objects
/// mirror the fixture's O1 to O8; every value is a made-up placeholder.
@MainActor
struct ObjectPrivacyTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    func label(_ object: ObjectRecord) -> String? {
        ObjectPrivacy.label(of: object, in: store, classes: classes)
    }

    func memory(_ title: String, rule: String? = nil, isPrivate: Bool) throws -> ObjectRecord {
        let memory = try store.create(#require(classes[.tessMemory]), title: title)
        if let rule {
            try store.set("rule", to: .text(rule), on: memory)
        }
        try store.set("isPrivate", to: .bool(isPrivate), on: memory)
        return memory
    }

    @Test func privateMemoriesShowOnlyTheirLabel() throws {
        // O1 (PM1 to PM3): flagged and holding a code; O2 (PM15): flagged, a body fact in the title only.
        #expect(try label(memory("Your door code is 4417", rule: "door code is 4417", isPrivate: true))
            == "Private memory")
        #expect(try label(memory("Your left shoulder gets sore after presses", isPrivate: true)) == "Private memory")
        // O8 (PM10): a plain noticed line stays itself; flipped private (PM12) it masks; back again (PM13) it shows.
        let evening = try memory("You like to train in the evening", rule: "training.hours", isPrivate: false)
        #expect(label(evening) == nil)
        try store.set("isPrivate", to: .bool(true), on: evening)
        #expect(label(evening) == "Private memory")
        try store.set("isPrivate", to: .bool(false), on: evening)
        #expect(label(evening) == nil)
    }

    @Test func privateNotesShowOnlyTheirLabel() throws {
        // O3 (PM5, PM14): a secret forces it private. O4 (PM6): private by its flag alone.
        let secret = try engine.perform(CreateNote(body: "wifi password is hunter2"), by: .user).output
        #expect(label(secret) == "Private note")
        let flagged = try engine.perform(CreateNote(body: "took advil 400 today", isPrivate: true), by: .user).output
        #expect(label(flagged) == "Private note")
        // PM16: a note from before #422, titled with the words and no flag, masks by its words.
        let old = try store.create(#require(classes[.note]), title: "wifi password is hunter2")
        #expect(label(old) == "Private note")
        // O6 (PM8): a plain note shows; made private by an edit (PM11) it masks.
        let bag = try engine.perform(CreateNote(body: "Gym bag in the car"), by: .user).output
        #expect(label(bag) == nil)
        try engine.perform(EditNote(note: bag.id, body: "Gym bag in the car, locker code 4417", title: nil), by: .user)
        #expect(label(bag) == "Private note")
    }

    @Test func tasksMaskByTitleAndWorkoutsHideTheirNotes() throws {
        // O7 (PM9): a plain task shows. A task titled with a body fact masks (PM7 once the medicine words land).
        let plain = try engine.perform(CreateTask(title: "Call the dentist"), by: .user).output
        #expect(label(plain) == nil)
        let advil = try store.create(#require(classes[.task]), title: "Take advil 400mg")
        #expect(label(advil) == "Private task")
        // Product 5:07 PM PT: a workout's notes are a body fact, never printed on the generic page.
        let workout = try store.create(#require(classes[.workout]), title: "Push A")
        #expect(ObjectPrivacy.hidesNotes(of: workout, classes: classes))
        #expect(!ObjectPrivacy.hidesNotes(of: plain, classes: classes))
    }
}
