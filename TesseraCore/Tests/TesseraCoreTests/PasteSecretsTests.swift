import Foundation
@testable import TesseraCore
import Testing

/// Research 137 (docs/research/fixtures/secret-words-paste.md): in pasted text and fetched pages, a line with a secret
/// and a value is cut; the recipe reads as before. Every value below is a made-up placeholder.
@MainActor
struct PasteSecretsTests {
    @Test(arguments: [
        "wifi: TacoNet / tacocat24", "door code 4417", "Grandma's iPad PIN 0420", "Passcode is one two three four",
        "netflix password hunter2", "Conf line 555-0100, PIN: 7781", "Costco member # 1112 2233 4455",
        "Gift card code: X7Q2-PLMN-4417", "Account #: 0000 1234 5678", "Member account 0000 1234 5678",
        "Your order PIN: 4417", "Use code CHEF4417 for 10% off", "WiFi - TacoNet pw tacocat24", "alarm code 9 9 1 2",
        "Book a table, zip code 94110 delivery only",
    ])
    func privateLinesAreCut(_ line: String) {
        #expect(SecretWords.isPrivateLine(line), "\(line)")
    }

    @Test(arguments: [
        "garage 4417", "PIN the dough to the board with two forks", "Remove the pin bones from the salmon",
        "Use code 3 oven setting (fan)", "Account for resting time: 10 min", "Pinch of salt", "2 cups spinach",
        "A combination of spices: cumin, coriander", "Spice combination: cumin", "Sign up for our promo code!",
        "Download the password-protected PDF", "password protected PDF", "Pair with a Pinot noir", "Step 4: cook code",
    ])
    func nearMissesPassUnchanged(_ line: String) {
        #expect(!SecretWords.isPrivateLine(line), "\(line)")
    }

    @Test func aPastedRecipeKeepsEverythingButThePrivateLine() throws {
        // P1: a Notes-app recipe whose last line is the wifi; "salt\nwifi" is two words now (PL2).
        let text = """
        Garlic bread
        Ingredients
        1 baguette
        2 cloves garlic
        Pinch of salt
        Method
        1. Rub the garlic on the bread and bake 10 minutes.
        wifi: TacoNet / tacocat24
        """
        let cut = SecretWords.cut(text)
        #expect(cut.cut == 1 && !cut.text.contains("tacocat") && cut.text.contains("Pinch of salt"))
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let recipe = try engine.perform(CreateRecipe(text: text), by: .user).output
        #expect(store.value("sourceText", of: recipe)?.stringValue?.contains("tacocat") == false)
        #expect(recipe.title == "Garlic bread")
        let lines = CreateRecipe.lines(of: text, corrections: nil)
        #expect(lines.last.map {
            if case .ignored = $0.kind {
                true
            } else {
                false
            }
        } == true)
        #expect(!store.context.objects.values.contains { $0.title.contains("tacocat") })
        // P15: nothing but private lines saves nothing.
        #expect(throws: ActionError.self) {
            try engine.perform(CreateRecipe(text: "Bank PIN 0420\nalarm code 9912\nwifi: TacoNet tacocat24"), by: .user)
        }
    }
}
