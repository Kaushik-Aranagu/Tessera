import Foundation
import SwiftUI
@testable import Tessera
import TesseraCore
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

    /// A key's VoiceOver hint says what happens, never the gesture; tap keys keep none.
    @Test func paintKeyHintSaysWhatHappens() {
        let hold = PaintKey(hint: "Finishes the workout", action: {}, label: { _ in Text("Finish") })
        #expect(hold.hint == "Finishes the workout")
        let tap = PaintKey(isTap: true, action: {}, label: { _ in Text("Skip rest") })
        #expect(tap.hint.isEmpty)
        let withMeta = PaintKey(isSilent: true, hint: "Restores this backup", action: {},
                                label: { _ in Text("Replace") }, meta: { Text("Hold") })
        #expect(withMeta.hint == "Restores this backup")
    }

    /// The house clock in Shared (the widget extension can't link TesseraCore) must read exactly as Core's.
    @Test func houseClockMatchesCoreHouseTime() {
        for (hour, minute) in [(0, 0), (0, 5), (9, 0), (12, 0), (12, 30), (18, 12), (23, 59)] {
            let moment = date(hour, minute)
            #expect(HouseClock.time(moment, calendar: calendar) == HouseTime.clock(moment, calendar: calendar))
        }
    }

    /// Rider 0r: the Resume key's progress counts each entry's "targetSets", not a "sets" field nothing writes.
    @Test func plannedSetsReadTargetSets() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        let store = model.store
        let workout = try store.create(#require(model.classDef(.workout)), title: "Push Day A")
        let entries = [4.0, 3, 5].map { sets in
            let entry = store.create(model.classDef(.exerciseEntry)!, parent: workout)
            try? store.set("targetSets", to: .number(sets), on: entry)
            return entry
        }
        #expect(NowPage.plannedSets(entries, store: store) == 12)
        let unplanned = try store.create(#require(model.classDef(.exerciseEntry)), parent: workout)
        #expect(NowPage.plannedSets(entries + [unplanned], store: store) == 15)
    }
}
