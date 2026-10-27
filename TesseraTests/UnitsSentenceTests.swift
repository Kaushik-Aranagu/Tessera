@testable import Tessera
import TesseraCore
import Testing

/// The Units row in Settings: one sentence, each unit a value word that steps to the kind's other unit.
struct UnitsSentenceTests {
    @Test func theSentenceReadsInOrder() {
        let words = UnitsCopy.kinds.enumerated().map { UnitsCopy.lead($1, first: $0 == 0) + UnitsCopy.standard($1) }
        #expect(words
            .joined(separator: ",") == "Weights in kg, distances in km, lengths in cm, temperatures in °C")
    }

    @Test func aTapStepsToTheOtherUnitAndBack() {
        #expect(UnitsCopy.next(after: "kg", in: .weight) == "lb")
        #expect(UnitsCopy.next(after: "lb", in: .weight) == "kg")
        #expect(UnitsCopy.next(after: "°C", in: .temperature) == "°F")
    }
}
