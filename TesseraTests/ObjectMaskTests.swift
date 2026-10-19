@testable import Tessera
import TesseraCore
import Testing

/// G141: an ingredient, list item or list with a walled title prints only its label on the object page.
@MainActor
struct ObjectMaskTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func label(_ object: ObjectRecord) -> String? {
        ObjectMask.label(of: object, in: model.store, classes: model.classes)
    }

    @Test func aPrivateIngredientReadsPrivateItem() throws {
        try model.engine.perform(AddGroceries(lines: ["advil", "milk"]), by: .user)
        let groceries = Groceries(store: model.store, classes: model.classes)
        let rows = groceries.shoppingOrder()
        let advil = try #require(rows.first { $0.text.lowercased().contains("advil") }.flatMap {
            groceries.ingredient(of: $0.object)
        })
        let milk = try #require(rows.first { $0.text == "milk" }.flatMap { groceries.ingredient(of: $0.object) })
        #expect(label(advil) == "Private item")
        #expect(label(milk) == nil)
        let advilRow = try #require(rows.first { $0.text.lowercased().contains("advil") })
        #expect(label(advilRow.object) == "Private item")
    }

    @Test func aPrivateListReadsPrivateList() throws {
        let list = try model.engine.perform(CreateList(name: "Rent 1200 stuff"), by: .user).output
        #expect(label(list) == "Private list")
        let packing = try model.engine.perform(CreateList(name: "Packing"), by: .user).output
        #expect(label(packing) == nil)
    }

    /// QA on #912: the same set as a private list item; "blood orange" is food.
    @Test func dentistIsPrivateAndBloodOrangeIsNot() throws {
        let list = try model.engine.perform(CreateList(name: "Errands"), by: .user).output
        let dentist = try model.engine.perform(AddListItem(list: list.id, text: "dentist"), by: .user).output
        let orange = try model.engine.perform(AddListItem(list: list.id, text: "blood orange"), by: .user).output
        #expect(label(dentist) == "Private item")
        #expect(label(orange) == nil)
        let run = try model.engine.perform(CreateList(name: "Dentist run"), by: .user).output
        #expect(label(run) == "Private list")
    }
}
