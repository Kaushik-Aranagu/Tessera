import Foundation
@testable import TesseraCore
import Testing

/// S10: the lifted ledger gives the app ledger's answers (the shape the app tests pin: a shop makes things in, a cook
/// makes them low, Produce out, staples never move).
@MainActor
struct PantryBookTests {
    let store = ObjectStore.open(inMemory: true)

    @Test func theLiftedLedgerGivesTheAppLedgersAnswers() throws {
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let tacos = try engine.perform(CreateRecipe(text: """
        Tacos
        1 lb ground beef
        2 limes
        1 tsp salt
        Method
        1. Cook.
        """), by: .user).output
        let pantry = PantryBook(store: store, classes: classes)
        #expect(PantryBook.hero(pantry.entries()) == "Nothing yet" && !pantry.hasAnyState)
        let day = Date(timeIntervalSince1970: 1_792_000_000)
        try engine.perform(AddRecipeToGroceries(recipe: tacos.id), by: .user)
        for item in store.object(id: Groceries.listID)?.orderedChildren ?? [] {
            try engine.perform(CheckListItem(item: item.id, time: day), by: .user)
        }
        try engine.perform(ClearDoneItems(list: Groceries.listID), by: .user)
        #expect(pantry.entries().count == 2 && pantry.entries()
            .allSatisfy { $0.state == .have && $0.lastBoughtAt == day })
        let cook = try engine.perform(StartCooking(recipe: tacos.id, time: day.addingTimeInterval(86400)), by: .user)
            .output
        try engine.perform(FinishCooking(cook: cook.id, time: day.addingTimeInterval(88000)), by: .user)
        let states = Dictionary(uniqueKeysWithValues: pantry.entries().map { ($0.label.lowercased(), $0.state) })
        #expect(states["ground beef"] == .low && states["limes"] == .out, "\(states)")
        #expect(states["salt"] == nil) // a staple never moves
        #expect(PantryBook.hero(pantry.entries()) == "1 out, 1 low")
    }
}
