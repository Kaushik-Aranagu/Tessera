import Foundation
@testable import Tessera
import Testing

/// Routines day v2 (feature 162): the day as one sentence; no streak or miss words; the switch defaults Off.
struct RoutinesDayTests {
    private let night = RoutinesDayWords.Next(name: "Night", startMinuteOfDay: 21 * 60 + 50)

    @Test func pauseAndBusyStayHiddenUntilTheyDoSomething() {
        #expect(!RoutinesDayWords.showsPauseBusy)
    }

    @Test func runningWithANext() {
        #expect(RoutinesDayWords.sentence(running: "Morning", next: night, total: 2)
            == "Morning is running. Night is next, usually 9:50 pm")
    }

    @Test func nothingRunningWithANext() {
        #expect(RoutinesDayWords.sentence(running: nil, next: night, total: 2)
            == "Nothing is running. Night is next, usually 9:50 pm")
        #expect(RoutinesDayWords.sentence(running: nil, next: .init(name: "Night", startMinuteOfDay: nil), total: 1)
            == "Nothing is running. Night is next")
    }

    @Test func runningAloneAndEverythingDone() {
        #expect(RoutinesDayWords.sentence(running: "Morning", next: nil, total: 1) == "Morning is running")
        #expect(RoutinesDayWords.sentence(running: nil, next: nil, total: 2) == "Everything is done today")
        #expect(RoutinesDayWords.sentence(running: nil, next: nil, total: 0) == "Nothing is set up yet")
    }

    @Test func aPrivateRoutineIsSaidWithoutATime() {
        let next = RoutinesDayWords.Next(name: RoutinesLandingWords.privateName, startMinuteOfDay: nil)
        #expect(RoutinesDayWords.sentence(running: RoutinesLandingWords.privateName, next: next, total: 2)
            == "Private routine is running. Private routine is next")
    }

    @Test func noWordEverTalksStreaksOrMisses() {
        let all = [RoutinesDayWords.sentence(running: "Morning", next: night, total: 2),
                   RoutinesDayWords.sentence(running: nil, next: night, total: 2),
                   RoutinesDayWords.sentence(running: nil, next: nil, total: 2),
                   RoutinesDayWords.sentence(running: nil, next: nil, total: 0),
                   RoutinesDayWords.pause, RoutinesDayWords.busy]
        for line in all {
            let lower = line.lowercased()
            for word in ["streak", "miss", "broke", "lost", "behind"] {
                #expect(!lower.contains(word))
            }
        }
    }

    @Test func theSwitchesDefaultOff() {
        for id in [RoutinesDaySwitch.choiceID, WeekThreadSwitch.choiceID] {
            let choice = ReviewChoices.all.first { $0.id == id }
            #expect(choice?.defaultValue == "Off")
            #expect(choice?.readiness == .live)
        }
    }
}
