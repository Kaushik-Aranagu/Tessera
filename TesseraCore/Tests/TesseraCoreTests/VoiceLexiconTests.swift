@testable import TesseraTess
import Testing

@Suite("Voice lexicon")
struct VoiceLexiconTests {
    private let lexicon = VoiceLexicon(names: [("Romanian deadlift", 5), ("Bench press", 2), ("Milk", 2), ("Deck", 1)])

    @Test func nearSpellingPullsOntoTheName() {
        #expect(lexicon.resolve("log romanian dead lift") == "log Romanian deadlift")
        #expect(lexicon.resolve("add benchpress") == "add Bench press")
    }

    @Test func shortAndUnknownWordsAreLeftAlone() {
        #expect(lexicon.resolve("add silk to the list") == "add silk to the list")
        #expect(lexicon.resolve("") == "")
    }

    @Test func exactNameKeepsItsSpelling() {
        #expect(lexicon.resolve("open deck") == "open Deck")
    }

    @Test func contextOrdersFocusedFirst() {
        #expect(lexicon.contextualStrings(limit: 1) == ["Romanian deadlift"])
    }

    @Test func moneyNamesNeverReachTheRecogniser() {
        let frame = TessFrame(room: "purse", elements: [
            ElementMeaning(place: .page, items: [
                ElementItem(kind: "spend", name: "Rent", taint: .deviceOnly),
                ElementItem(kind: "note", name: "Groceries"),
            ]),
        ])
        let strings = frame.vocabulary.contextualStrings()
        #expect(strings.contains("Groceries"))
        #expect(!strings.contains("Rent"))
    }
}
