import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The live workout v2 words (Design 153): the top line, the context line, the last-time rule, the switch ships Off.
@MainActor
struct LiveV2Tests {
    @Test func theTopLineNamesTheExerciseAndTheSet() {
        #expect(LiveV2.topLine(exercise: "Bench press", set: 2, of: 4) == "Bench press, set 2 of 4")
        let parts = LiveV2.topParts(exercise: "Bench press", set: 2, of: 4)
        #expect(parts.name == "Bench press")
        #expect(parts.rest == ", set 2 of 4")
    }

    @Test func theTotalNeverReadsBelowTheSet() {
        #expect(LiveV2.topLine(exercise: "Row", set: 5, of: 3) == "Row, set 5 of 5")
    }

    @Test func lastTimeIsWeightForRepsWithNoSymbol() {
        #expect(LiveV2.lastTime(weightKg: 80, reps: 8, unit: .kilograms) == "Last time 80 for 8")
        #expect(LiveV2.lastTime(weightKg: 82.5, reps: 6, unit: .kilograms) == "Last time 82.5 for 6")
        #expect(LiveV2.lastTime(weightKg: 80, reps: 8, unit: .pounds) == "Last time 175 for 8")
    }

    @Test func lastTimeIsOmittedWithoutHistory() {
        #expect(LiveV2.lastTime(weightKg: nil, reps: nil, unit: .kilograms) == nil)
        #expect(LiveV2.lastTime(weightKg: 80, reps: nil, unit: .kilograms) == nil)
        #expect(LiveV2.lastTime(weightKg: .nan, reps: 8, unit: .kilograms) == nil)
    }

    @Test func theBestWorkingSetIsTheHeaviestThenTheMostReps() throws {
        let best = try #require(LiveV2.bestSet([(60, 10), (80, 6), (80, 8), (70, 12)]))
        #expect(best.weight == 80)
        #expect(best.reps == 8)
        #expect(LiveV2.bestSet([]) == nil)
    }

    @Test func theUnitTurnsBetweenKilogramsAndPounds() {
        #expect(LiveV2.turned(.kilograms) == .pounds)
        #expect(LiveV2.turned(.pounds) == .kilograms)
        #expect(LiveV2.unitWord(.kilograms, perHand: true) == "kg each")
        #expect(LiveV2.unitWord(.pounds, perHand: false) == "lb")
    }

    @Test func thePullGrowsWithTheDragAndStopsAtOne() {
        #expect(LiveV2.pressure(translation: 0) == 0)
        #expect(LiveV2.pressure(translation: -60) == 0.5)
        #expect(LiveV2.pressure(translation: 500) == 1)
        #expect(LiveV2.pressure(translation: .nan) == 0)
    }

    @Test func theSwitchShipsOff() throws {
        #expect(LiveV2.choiceID == "liveV2")
        let choice = try #require(ReviewChoices.all.first { $0.id == "liveV2" })
        #expect(choice.defaultValue == "Off")
    }
}
