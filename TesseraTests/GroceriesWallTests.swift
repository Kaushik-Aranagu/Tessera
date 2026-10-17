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
}
