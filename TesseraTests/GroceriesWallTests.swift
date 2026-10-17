@testable import Tessera
import TesseraCore
import Testing

/// The Groceries Add line through Core's wall: walled lines stay in the draft with their line, the rest go on.
@MainActor
struct GroceriesAddWallTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    @Test func aMixedBatchKeepsTheWalledLinesWithTheirReason() {
        let split = GroceriesWall.split(["milk", "rent $1200", "wifi password hunter2"], store: model.store)
        #expect(split.kept == ["milk"])
        #expect(split.walled.map(\.reason) == [.money, .secret])
    }

    @Test func aKeyShapedLineIsTheKeyLine() {
        let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)
        let split = GroceriesWall.split([fake], store: model.store)
        #expect(split.kept.isEmpty && split.walled.first?.reason == .key)
        #expect(GroceriesWall.line(.key) == claudeKeyLine)
    }

    @Test func linesSayWhyAndNeverEchoTheValue() {
        #expect(GroceriesWall.line(.money) == "That stays on this phone.")
        #expect(GroceriesWall.line(.secret) == "That one stays out of Groceries.")
    }

    @Test func aPriceComesOffButTheThingGoesOn() {
        let split = GroceriesWall.split(["milk 4.99"], store: model.store)
        #expect(split.kept == ["milk 4.99"] && split.walled.isEmpty, "Core strips the price as it adds")
    }

    @Test func theStrongestReasonIsSpokenAndAKeyNeverReturnsToTheDraft() {
        let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)
        let split = GroceriesWall.split(["rent $1200", fake, "wifi password hunter2", "eggs"], store: model.store)
        #expect(split.kept == ["eggs"])
        #expect(GroceriesWall.spoken(split.walled) == claudeKeyLine, "key, then secret, then money")
        #expect(GroceriesWall.heldDraft(split.walled) == "rent $1200, wifi password hunter2")
        let noKey = GroceriesWall.split(["rent $1200", "wifi password hunter2"], store: model.store)
        #expect(GroceriesWall.spoken(noKey.walled) == "That one stays out of Groceries.")
    }

    @Test func sumOnlyAndMedicineLines() {
        let split = GroceriesWall.split(["$40 at costco", "advil"], store: model.store)
        #expect(split.walled.map(\.line) == ["$40 at costco"] && split.walled.first?.reason == .money)
        #expect(split.kept == ["advil"], "a medicine goes on, masked as Private item where it shows")
    }

    @Test func aBareWeightStaysOnThePhone() throws {
        // His last weight, kept the way master keeps one (a weigh-in private note); the line is a body fact.
        try model.engine.perform(CreateNote(body: "82 kg this morning", isPrivate: true), by: .user)
        let split = GroceriesWall.split(["82.4"], store: model.store)
        #expect(split.kept.isEmpty && split.walled.first?.reason == .money)
        #expect(GroceriesWall.spoken(split.walled) == "That stays on this phone.")
    }

    @Test func theDraftRoundTrips() {
        let split = GroceriesWall.split(GroceriesCopy.lines(in: "milk, rent $1200, eggs"), store: model.store)
        let again = GroceriesWall.split(
            GroceriesCopy.lines(in: GroceriesWall.heldDraft(split.walled)),
            store: model.store
        )
        #expect(again.kept.isEmpty && again.walled.map(\.line) == split.walled.map(\.line))
    }

    @Test func keptLinesSpeakTheEnginesReceiptWithUndo() {
        let outcome = GroceriesWall.add("milk, eggs", engine: model.engine, store: model.store)
        #expect(outcome.draft.isEmpty && outcome.undo != nil)
        #expect(outcome.voice == "Milk and eggs, on Groceries.")
    }

    @Test func aMixedBatchKeepsTheReceiptAndUndoWithTheWallLineAfter() {
        let outcome = GroceriesWall.add("eggs, rent $1200", engine: model.engine, store: model.store)
        #expect(outcome.draft == "rent $1200" && outcome.undo != nil)
        #expect(outcome.voice == "Eggs, on Groceries. That stays on this phone.")
    }

    @Test func onlyWalledLinesHaveNoUndo() {
        let outcome = GroceriesWall.add("rent $1200", engine: model.engine, store: model.store)
        #expect(outcome.draft == "rent $1200" && outcome.undo == nil)
        #expect(outcome.voice == "That stays on this phone.")
    }

    @Test func aKeyIsClearedAndNeverComesBack() {
        let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)
        let outcome = GroceriesWall.add("\(fake), wifi password hunter2", engine: model.engine, store: model.store)
        #expect(outcome.draft == "wifi password hunter2" && outcome.voice == claudeKeyLine && outcome.undo == nil)
    }

    @Test func aRefusedWriteKeepsTheDraftButNeverTheKey() {
        let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)
        let outcome = GroceriesWall.add("milk, \(fake), rent $1200", store: model.store) { _ in nil }
        #expect(outcome.draft == "milk, rent $1200" && !looksLikeClaudeKey(outcome.draft))
        #expect(outcome.voice == "Didn't save that. Try again." && outcome.undo == nil)
    }
}
