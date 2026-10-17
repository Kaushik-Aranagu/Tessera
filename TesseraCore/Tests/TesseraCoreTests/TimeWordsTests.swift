import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Research time-words-sweep (board 0q, decisions 12:35 PM PT Oct 16): one 12-hour house time, and his 4 am day
/// wherever a day is named.
struct TimeWordsTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @Test func oneTwelveHourTime() {
        // TW9 to TW18: he never reads a 24-hour time.
        #expect(HouseTime.clock(Self.at(16, 18, 30), calendar: Self.calendar) == "6:30 pm")
        #expect(HouseTime.clock(Self.at(16, 19), calendar: Self.calendar) == "7 pm")
        #expect(HouseTime.clock(Self.at(16, 0, 5), calendar: Self.calendar) == "12:05 am")
        #expect(HouseTime.clock(Self.at(16, 12), calendar: Self.calendar) == "12 pm")
    }

    @Test func memoryNamesHisDay() {
        // TW26: a cook at 12:30 am Oct 17 was on his Oct 16.
        let line = TessMemory.when(Self.at(17, 0, 30), now: Self.at(20, 12), calendar: Self.calendar)
        #expect(line == "on Oct 16")
    }

    @Test func aTimeTessPicksNeverLandsInQuietHours() {
        // Product 0ab: "call mom thu" typed at 1 am Friday (his Thursday) lands at 7 am, not 2 am.
        let (date, _) = TessDates.extract(from: ["call", "mom", "thu"], now: Self.at(16, 1), calendar: Self.calendar)
        #expect(date == Self.at(16, 7))
        // "today" said at 23:10 would be midnight: 7 am instead.
        let (late, _) = TessDates.extract(from: ["call", "mom", "today"], now: Self.at(15, 23, 10),
                                          calendar: Self.calendar)
        #expect(late == Self.at(16, 7))
        // A time he says himself is kept.
        let (said, _) = TessDates.extract(from: ["call", "mom", "thu", "at", "1am"], now: Self.at(14, 12),
                                          calendar: Self.calendar)
        #expect(said == Self.at(15, 1))
    }

    @Test func aWeekdayCountsFromHisDay() throws {
        // TW29: "thu" said at 1 am Friday (still his Thursday, Oct 15) is today, not next week.
        let (date, _) = TessDates.extract(from: ["call", "mom", "thu"], now: Self.at(16, 1), calendar: Self.calendar)
        let found = try #require(date)
        #expect(found < Self.at(16, 12) && found > Self.at(16, 1))
        // Said on Friday afternoon, "thu" is next Thursday.
        let (next, _) = TessDates.extract(from: ["call", "mom", "thu"], now: Self.at(16, 15), calendar: Self.calendar)
        #expect(try #require(next) > Self.at(21, 0))
    }

    @Test @MainActor func notNowNeverLandsInQuietHours() throws {
        // Product 0ab, QA F1 on #553: the moved time itself leaves quiet hours, to its next 7 am.
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let calendar = Self.calendar
        // 11:20 pm Tuesday, a task at 11 pm: tomorrow 11 pm is quiet, so 7 am that Wednesday.
        let late = try engine.perform(CreateTask(title: "Stretch", startsAt: Self.at(13, 23)), by: .user).output
        try engine.perform(MoveTask(task: late.id, time: Self.at(13, 23, 20), calendar: calendar), by: .user)
        #expect(store.value("startsAt", of: late)?.dateValue == Self.at(14, 7))
        // 8 pm Tuesday, a task at 6:30 am Wednesday: Thursday 6:30 am is quiet, so Thursday 7 am, a full day on.
        let early = try engine.perform(CreateTask(title: "Run", startsAt: Self.at(14, 6, 30)), by: .user).output
        try engine.perform(MoveTask(task: early.id, time: Self.at(13, 20), calendar: calendar), by: .user)
        #expect(store.value("startsAt", of: early)?.dateValue == Self.at(15, 7))
        // A task at 9 am moves to 9 am, untouched.
        let morning = try engine.perform(CreateTask(title: "Call", startsAt: Self.at(14, 9)), by: .user).output
        try engine.perform(MoveTask(task: morning.id, time: Self.at(13, 20), calendar: calendar), by: .user)
        #expect(store.value("startsAt", of: morning)?.dateValue == Self.at(15, 9))
    }

    @Test @MainActor func tessSaysTheQuietHourMoveWithItsDay() async throws {
        // Design on #553: "Call mom, tomorrow 7 am." at 11:10 pm; "Call mom, Friday 7 am." at 1 am Friday.
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let tess = TessCaptureEngine(engine: engine)
        let late = await tess.capture("call mom today", context: TessContext(now: Self.at(15, 23, 10),
                                                                             calendar: Self.calendar))
        #expect(late.line == "Call mom, tomorrow 7 am.", "\(late.line)")
        let early = await tess.capture(
            "call mom thu",
            context: TessContext(now: Self.at(16, 1), calendar: Self.calendar)
        )
        #expect(early.line == "Call mom, Friday 7 am.", "\(early.line)")
    }

    @Test @MainActor func notNowOnUntimedTaskLateSnapsToSeven() throws {
        // Research evening-quiet EQ26: "Not now" on an untimed task at Thu 11:20 pm lands Fri 7:00 am.
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let task = try engine.perform(CreateTask(title: "Read"), by: .user).output
        try engine.perform(MoveTask(task: task.id, time: Self.at(15, 23, 20), calendar: Self.calendar), by: .user)
        #expect(store.value("startsAt", of: task)?.dateValue == Self.at(16, 7))
    }
}
