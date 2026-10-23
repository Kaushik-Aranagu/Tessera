import Foundation
@testable import Tessera
import Testing

/// Design 139, finishing: the three lines, the privacy wall, and the switch default.
struct FinishWordsTests {
    @Test func trainingSaysAllSetsInWithTheLength() {
        #expect(FinishWords.trainingLine(name: "Push Day A", minutes: 95) == "Push Day A, all sets in. 1 hr 35 min.")
        #expect(FinishWords.trainingLine(name: "Pull", minutes: 45) == "Pull, all sets in. 45 min.")
        #expect(FinishWords.trainingLine(name: "Legs", minutes: 60) == "Legs, all sets in. 1 hr.")
    }

    @Test func aPrivateNameNeverReachesALine() {
        let label = "Private workout"
        #expect(FinishWords.shownName("Lexapro day", privateLabel: label) == "Private workout")
        #expect(FinishWords.shownName("Push Day A", privateLabel: nil) == "Push Day A")
        let line = FinishWords.trainingLine(name: "Lexapro day", privateLabel: label, minutes: 50)
        #expect(line == "Private workout, all sets in. 50 min.")
        #expect(!line.contains("Lexapro"))
        let routine = FinishWords.routineLine(name: "Rent call", privateLabel: "Private routine", minutes: 12)
        #expect(routine == "Private routine, 12 min.")
    }

    @Test func theKitchenServesAtTheClock() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 19,
                                                                   minute: 2)))
        #expect(FinishWords.servedLine(at: date, calendar: calendar) == "Served at 7:02 pm.")
    }

    @Test func theRoutineSaysTomorrowOnlyAfterSevenRuns() {
        #expect(FinishWords.routineLine(name: "Morning", minutes: 22) == "Morning, 22 min.")
        #expect(FinishWords.tomorrowLine(usualStartMinuteOfDay: 6 * 60 + 40) == "Tomorrow, usually 6:40 am.")
        #expect(FinishWords.tomorrowLine(usualStartMinuteOfDay: nil) == nil)
    }

    @Test func lengthRoundsDown() {
        #expect(FinishWords.minutes(of: 95 * 60 + 59) == 95)
        #expect(FinishWords.minutes(of: -5) == 0)
    }

    @Test func theSwitchDefaultsOff() {
        let choice = ReviewChoices.all.first { $0.id == FinishWords.choiceID }
        #expect(choice?.defaultValue == "Off")
        #expect(!FinishWords.isOn(value: choice?.defaultValue))
        #expect(FinishWords.isOn(value: "On"))
        #expect(!FinishWords.isOn(value: nil))
    }
}
