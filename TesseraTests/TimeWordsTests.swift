import Foundation
@testable import Tessera
import Testing

/// Builder A's time words (docs/research/time-words-sweep.md TW5, TW13, TW16) and the hold key's VoiceOver hint.
@MainActor
struct TimeWordsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    /// Oct 16, 2026 is a Friday.
    private func date(day: Int = 16, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @Test func houseClockIsTwelveHourLowerCase() {
        #expect(HouseClock.time(date(18, 12), calendar: calendar) == "6:12 pm")
        #expect(HouseClock.time(date(20), calendar: calendar) == "8 pm")
        #expect(HouseClock.time(date(0, 50), calendar: calendar) == "12:50 am")
        #expect(HouseClock.time(date(12), calendar: calendar) == "12 pm")
        #expect(HouseClock.time(date(9, 5), calendar: calendar) == "9:05 am")
    }

    @Test func finishLineTakesItsWeekdayFromTheFourAmDay() {
        let line = WorkoutFinishView.dayLine(startedAt: date(23, 40), endedAt: date(day: 17, 0, 50),
                                             calendar: calendar)
        #expect(line == "Friday, 11:40 pm to 12:50 am")
        let afterMidnight = WorkoutFinishView.dayLine(startedAt: date(day: 17, 1, 10), endedAt: date(day: 17, 2),
                                                      calendar: calendar)
        #expect(afterMidnight == "Friday, 1:10 am to 2 am")
        let morning = WorkoutFinishView.dayLine(startedAt: date(day: 17, 6, 2), endedAt: date(day: 17, 7, 10),
                                                calendar: calendar)
        #expect(morning == "Saturday, 6:02 am to 7:10 am")
    }

    @Test func doneWordNeverSaysThisNight() {
        #expect(TrainingPage.doneWhen(date(5, 30), calendar: calendar) == "done early this morning")
        #expect(TrainingPage.doneWhen(date(9), calendar: calendar) == "done this morning")
        #expect(TrainingPage.doneWhen(date(14), calendar: calendar) == "done this afternoon")
        #expect(TrainingPage.doneWhen(date(18), calendar: calendar) == "done this evening")
        #expect(TrainingPage.doneWhen(date(21, 30), calendar: calendar) == "done tonight")
        #expect(TrainingPage.doneWhen(date(day: 17, 1), calendar: calendar) == "done tonight")
    }

    @Test func holdKeysNeverTellVoiceOverToHold() {
        #expect(PaintKeyHint.hint(isTap: false) == "Double tap to finish")
        #expect(PaintKeyHint.hint(isTap: true).isEmpty)
    }
}
