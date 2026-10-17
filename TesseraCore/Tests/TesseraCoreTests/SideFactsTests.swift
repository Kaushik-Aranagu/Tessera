import Foundation
@testable import TesseraCore
import Testing

/// The 0ak must-fixes (Research screens-inventory-check.md PL1 to PL3): a side never shows what its front hides.
@MainActor
struct SideFactsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    @Test func anExercisesHiddenNotesKeepTheirPrivateLines() {
        // PL1: a health word and a secret word never reach the side, its glance or "Ask about this".
        let lines = SideFacts.setupLines("Handles at 4\nleft knee sore, locker code 4471\nSeat at 3\nwifi is tacocat",
                                         store: store)
        #expect(lines.shown == ["Handles at 4", "Seat at 3"])
        #expect(lines.keptPrivate == 2 && lines.keptLine == "2 lines kept private")
        #expect(SideFacts.setupLines(nil, store: store) == SideFacts.Lines(shown: [], keptPrivate: 0))
    }

    @Test func theDefaultSideNeverPrintsAPrivateObjectOrAWalledValue() throws {
        // PL2: a private note shows its count only; a plain object loses any walled value; every catalog field runs.
        let note = try engine.perform(CreateNote(body: "Gym bag in the car"), by: .user).output
        let secret = try engine.perform(CreateNote(body: "wifi password is hunter2"), by: .user).output
        #expect(SideFacts.defaultFields(of: secret, in: store, classes: classes) == nil)
        let shown = try #require(SideFacts.defaultFields(of: note, in: store, classes: classes))
        #expect(shown.contains { $0.value.contains("Gym bag") })
        // Money in the body makes the note private by its words: the side shows its count only.
        try store.set("body", to: .text("rent 2100 due"), on: note)
        #expect(SideFacts.defaultFields(of: note, in: store, classes: classes) == nil)
        // A plain object's walled value is dropped, the rest shown.
        let task = try engine.perform(CreateTask(title: "Fix bike light"), by: .user).output
        try store.set("notes", to: .richText("door code 4417"), on: task)
        let fields = try #require(SideFacts.defaultFields(of: task, in: store, classes: classes))
        #expect(!fields.contains { $0.value.contains("4417") })
        #expect(SideFacts.isShowable("Fix bike light", lastWeightKg: nil))
        #expect(!SideFacts.isShowable("rent 2100 due", lastWeightKg: nil))
        for classDef in classes.values {
            for object in store.objects(of: classDef) {
                for field in SideFacts.defaultFields(of: object, in: store, classes: classes) ?? [] {
                    #expect(SideFacts.isShowable(field.value, lastWeightKg: nil), "\(classDef.name).\(field.key)")
                }
            }
        }
    }

    @Test func aClassGlanceNeverNamesAPrivateObject() throws {
        // PL3: private objects count, are never the most used, and the newest shows only its label.
        try engine.perform(CreateNote(body: "Gym bag in the car"), by: .user)
        let secret = try engine.perform(CreateNote(body: "door code 4417"), by: .user).output
        secret.createdAt = .now.addingTimeInterval(60)
        let noteClass = try #require(classes[.note])
        let glance = SideFacts.classGlance(noteClass, engine: engine)
        #expect(glance.privateCount == 1 && glance.privateLine == "1 private")
        #expect(glance.newest == SecretWords.title && glance.newestID == secret.id)
        #expect(glance.mostUsedID != secret.id)
        #expect(glance.countLine == "\(glance.count) objects")
    }
}
