import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The finished workout's page words (Design 150): one sentence, one numbers line, the switch ships Off.
struct FinishedWorkoutTests {
    @Test func theSentenceNamesDateLengthSetsAndTheBest() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 21))
        #expect(FinishedWorkoutWords.sentence(date: date, minutes: 52, sets: 18, best: "Bench")
            == "Oct 21, 52 min, 18 sets. Bench was your best.")
        #expect(FinishedWorkoutWords
            .sentence(date: date, minutes: 95, sets: 1, best: nil) == "Oct 21, 1 hr 35 min, 1 set.")
    }

    @Test func theNumbersLineSaysWeightForReps() {
        #expect(FinishedWorkoutWords.dataLine([(80, 8), (80, 8), (82.5, 6)], unit: .kilograms)
            == "80 for 8, 80 for 8, 82.5 for 6")
    }

    @Test func theBestSetIsTheOneWithTheHighestEstimatedMax() {
        #expect(FinishedWorkoutWords.bestIndex([(80, 8), (82.5, 6), (85, 3)]) == 0)
        #expect(FinishedWorkoutWords.bestIndex([]) == nil)
    }

    @Test func theSwitchShipsOff() throws {
        let choice = try #require(ReviewChoices.all.first { $0.id == "pagesV2" })
        #expect(choice.defaultValue == "Off")
        #expect(choice.readiness == .live)
    }
}
