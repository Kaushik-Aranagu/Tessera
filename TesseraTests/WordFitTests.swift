import SwiftUI
@testable import Tessera
import Testing

@MainActor
struct WordFitTests {
    @Test func aLongWordStepsTheTitleDownAtAX5ButNeverBelowTheFloor() {
        let fitted = WordFit.largest(fitting: "Groceries for the week", points: 48, from: .accessibility5)
        #expect(fitted < .accessibility5, "Groceries cannot fit at the largest size, so the title steps down")
        let word = WordFit.widestWord("Groceries", points: 48)
        #expect(word > 0)
        // A short title keeps its size.
        #expect(WordFit.largest(fitting: "Bench Press", points: 48, from: .accessibility1) <= .accessibility1)
    }

    @Test func titlesAtOrBelowXxxLargeAreUntouched() {
        #expect(WordFit.largest(fitting: "Groceries", points: 48, from: .large) == .large)
        #expect(WordFit.largest(fitting: "Groceries", points: 48, from: .xxxLarge) == .xxxLarge)
    }
}
