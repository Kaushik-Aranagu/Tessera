import Foundation
@testable import Tessera
import Testing

/// Routines landing words (build sheet LR-1 to LR-6, LR-9 to LR-13, LR-19): fixed templates, no streaks, no misses.
struct RoutinesLandingWordsTests {
    @Test func theSubtitleCountsAndNeverShames() {
        #expect(RoutinesLandingWords.subtitle(total: 0, doneToday: 0) == "Nothing set up yet")
        #expect(RoutinesLandingWords.subtitle(total: 1, doneToday: 0) == "1 routine")
        #expect(RoutinesLandingWords.subtitle(total: 5, doneToday: 0) == "5 routines")
        #expect(RoutinesLandingWords.subtitle(total: 2, doneToday: 1) == "2 routines, 1 done today")
        #expect(RoutinesLandingWords.subtitle(total: 2, doneToday: 2) == "All done today")
    }

    @Test func aLineBeforeSevenRunsCountsSteps() {
        #expect(RoutinesLandingWords.stepsLine(name: "Push A", count: 5, workout: true) == "Push A, 5 exercises")
        #expect(RoutinesLandingWords.stepsLine(name: "Morning", count: 6, workout: false) == "Morning, 6 steps")
        #expect(RoutinesLandingWords.stepsLine(name: "Push A", count: 1, workout: true) == "Push A, 1 exercise")
    }

    @Test func aLineAfterSevenRunsGivesTheUsualStartAndLength() {
        #expect(RoutinesLandingWords.usualLine(name: "Morning", days: 14, startMinuteOfDay: 6 * 60 + 40,
                                               lengthMinutes: 22) == "Morning, 14 days, usually 6:40, 22 min")
        #expect(RoutinesLandingWords.usualLine(name: "Night", days: 11, startMinuteOfDay: 18 * 60 + 35,
                                               lengthMinutes: 95) == "Night, 11 days, usually 6:35 pm, 1 hr 35 min")
    }

    @Test func aFinishedRoutineSaysWhenItWasDone() {
        var parts = DateComponents()
        parts.year = 2026; parts.month = 10; parts.day = 22; parts.hour = 6; parts.minute = 58
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: parts) ?? .now
        #expect(RoutinesLandingWords.doneLine(name: "Morning", at: date, calendar: calendar) == "Morning, done at 6:58")
    }

    @Test func noLineEverMentionsAMissOrAStreak() {
        let lines = [RoutinesLandingWords.subtitle(total: 3, doneToday: 1),
                     RoutinesLandingWords.usualLine(name: "Morning", days: 3, startMinuteOfDay: 400, lengthMinutes: 20),
                     RoutinesLandingWords.stepsLine(name: "Night", count: 6, workout: false)]
        for line in lines {
            #expect(!line.lowercased().contains("missed") && !line.lowercased().contains("streak")
                && !line.lowercased().contains("skipped"))
        }
    }

    @Test func theClockReadsTheHouseWay() {
        #expect(RoutinesLandingWords.clock(6 * 60 + 40) == "6:40")
        #expect(RoutinesLandingWords.clock(12 * 60 + 5) == "12:05 pm")
        #expect(RoutinesLandingWords.clock(18 * 60 + 15) == "6:15 pm")
        #expect(RoutinesLandingWords.clock(10) == "12:10 am")
    }

    @Test func theRailValueFallsBackToStepsBeforeSevenRuns() {
        #expect(RoutinesLandingWords.railValue(days: nil, startMinuteOfDay: nil, lengthMinutes: nil, count: 6,
                                               workout: false) == "6 steps")
        #expect(RoutinesLandingWords.railValue(days: 14, startMinuteOfDay: 400, lengthMinutes: 22, count: 6,
                                               workout: false) == "14 days, usually 6:40, 22 min")
    }

    @Test func theVoiceReadsTheCountsInWords() {
        #expect(RoutinesLandingWords.spokenLine(name: "Morning", days: 14, startMinuteOfDay: 400, lengthMinutes: 22)
            == "Morning. Ran 14 of the last 30 days. Usually starts 6:40. Usually 22 minutes")
        #expect(RoutinesLandingWords.spokenTop(name: "Morning", step: "Shoes on", onStep: "4 minutes on this step")
            == "Morning is running. Step: Shoes on. 4 minutes on this step")
    }

    @Test func aUsualStartFallsInItsPlace() {
        #expect(RoutinePlace.of(startMinuteOfDay: 6 * 60 + 40) == .morning)
        #expect(RoutinePlace.of(startMinuteOfDay: 12 * 60) == .midday)
        #expect(RoutinePlace.of(startMinuteOfDay: 18 * 60 + 15) == .evening)
        #expect(RoutinePlace.of(startMinuteOfDay: 22 * 60) == .night)
        #expect(RoutinePlace.of(startMinuteOfDay: 2 * 60) == .night)
        #expect(RoutinePlace.of(startMinuteOfDay: nil) == .anyTime)
    }

    @Test func theKnobTurnsAroundTheKinds() {
        #expect(BrowseKind.all.next == .daily && BrowseKind.workouts.next == .all)
        #expect(BrowseKind.all.previous == .workouts)
    }
}
