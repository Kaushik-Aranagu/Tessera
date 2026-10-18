import Foundation
@testable import TesseraCore
import Testing

/// Pantry v2 spec V1 to V5: the shapes and the not-ours list. The state and the Groceries row come with the catalog
/// bump; this is the reader.
@MainActor
struct PantryPhraseTests {
    @Test(arguments: [
        "out of milk", "we're out of milk", "we are out of milk", "i'm out of milk", "i am out of milk",
        "all out of milk", "just out of milk", "ran out of milk", "we ran out of milk", "we've run out of milk",
        "no more milk", "no milk left", "milk is out", "milk's out", "milk is gone", "milk's gone", "Out of milk.",
        "out of the milk again", "we're out of some milk today",
    ])
    func theOutShapesAreRead(_ phrase: String) {
        #expect(PantryPhrase.parse(phrase) == PantryPhrase(kind: .out, items: ["milk"]), "\(phrase)")
    }

    @Test func eggsAreAreOutAndSeveralItemsSplit() {
        #expect(PantryPhrase.parse("eggs are out")?.items == ["eggs"])
        #expect(PantryPhrase.parse("out of milk, eggs and rice")?.items == ["milk", "eggs", "rice"])
        #expect(PantryPhrase.parse("out of mac and cheese")?.items == ["mac and cheese"])
        #expect(PantryPhrase.parse("out of 2% milk")?.items == ["2% milk"])
    }

    @Test(arguments: ["low on rice", "running low on rice", "rice is low", "rice's low"])
    func theLowShapesAreRead(_ phrase: String) {
        #expect(PantryPhrase.parse(phrase) == PantryPhrase(kind: .low, items: ["rice"]), "\(phrase)")
    }

    @Test func haveSetsInAndGotSetsInWithTheBoughtDay() {
        for phrase in ["have rice", "i have rice", "we have some rice", "restocked rice"] {
            #expect(PantryPhrase.parse(phrase) == PantryPhrase(kind: .have, items: ["rice"]), "\(phrase)")
        }
        for phrase in ["got rice", "bought rice", "picked up rice", "bought more rice"] {
            #expect(PantryPhrase.parse(phrase) == PantryPhrase(kind: .bought, items: ["rice"]), "\(phrase)")
        }
    }

    @Test(arguments: ["pantry", "open pantry", "show pantry", "what's out", "what am i out of", "what do i have"])
    func thePantryPhrasesOpenPantry(_ phrase: String) {
        #expect(PantryPhrase.parse(phrase)?.kind == .open, "\(phrase)")
    }

    @Test func whatDoIHaveTomorrowIsTheSchedule() {
        #expect(PantryPhrase.parse("what do i have tomorrow") == nil)
        #expect(PantryPhrase.parse("what do i have", hasDate: true)?.kind == .open) // exact words still open
    }

    @Test(arguments: [
        "out of breath", "out of stock", "out of time", "out of bed", "no more reps", "no more meetings",
        "have a call at 3", "have a lemon", "have 2 lemons", "out of 5", "no more 2",
        "the milk is out", "my milk is out", "remind me we're out of milk", "todo out of milk", "task out of milk",
    ])
    func theNotOursListIsNotRead(_ phrase: String) {
        #expect(PantryPhrase.parse(phrase) == nil, "\(phrase)")
    }

    @Test func aDayOrTimeIsNeverOurs() {
        #expect(PantryPhrase.parse("we'll be out of milk thu", hasDate: true) == nil)
        #expect(PantryPhrase.parse("got milk sat", hasDate: true) == nil)
    }

    @Test func onlyAPlacedNameIsKept() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(AddGroceries(lines: ["saffron"]), by: .user)
        // Known by the shop guide, known as an ingredient, and not known.
        #expect(PantryPhrase.parse("out of milk")?.resolve(in: store, classes: classes) != nil)
        #expect(PantryPhrase.parse("out of fancy milk")?.resolve(in: store, classes: classes) != nil)
        #expect(PantryPhrase.parse("out of saffron")?.resolve(in: store, classes: classes) != nil)
        #expect(PantryPhrase.parse("out of chalk")?.resolve(in: store, classes: classes) == nil)
        // "have" is stricter: the whole name must be known.
        #expect(PantryPhrase.parse("have milk")?.resolve(in: store, classes: classes) != nil)
        #expect(PantryPhrase.parse("have fancy milk")?.resolve(in: store, classes: classes) == nil)
    }
}
