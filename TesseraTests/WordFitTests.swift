import SwiftUI
@testable import Tessera
import Testing

@MainActor
struct WordFitTests {
    private let room = WordFit.screenAvailable

    @Test func theSteppedSizeFitsTheWidestWordOrHitsTheFloor() {
        for title in ["Groceries for the week", "Sheet-pan chicken and vegetables", "Bench Press", "Hamstring curls"] {
            let fitted = WordFit.largest(fitting: title, points: 48, from: .accessibility5)
            let points = WordFit.points(48, at: fitted)
            let start = WordFit.points(48, at: .accessibility5)
            let fits = WordFit.widestWord(title, points: points) * 1.08 <= room
            #expect(fits || points < 0.6 * start || fitted <= .xxxLarge,
                    "\(title) must fit at the stepped size or be at the floor")
        }
    }

    @Test func aLongWordStepsTheTitleDown() {
        let fitted = WordFit.largest(fitting: "Groceries for the week", points: 48, from: .accessibility5)
        #expect(fitted < .accessibility5)
    }

    @Test func titlesAtOrBelowXxxLargeAreUntouched() {
        #expect(WordFit.largest(fitting: "Groceries", points: 48, from: .large) == .large)
        #expect(WordFit.largest(fitting: "Groceries", points: 48, from: .xxxLarge) == .xxxLarge)
    }

    @Test func aNarrowerContainerStepsFurtherThanTheScreen() {
        let wide = WordFit.largest(fitting: "Groceries", points: 48, from: .accessibility5, available: 354)
        let narrow = WordFit.largest(fitting: "Groceries", points: 48, from: .accessibility5, available: 280)
        #expect(narrow < wide, "a narrower container steps strictly further down")
    }
}
