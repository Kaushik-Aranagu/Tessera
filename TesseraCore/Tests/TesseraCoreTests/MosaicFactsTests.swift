import Foundation
@testable import TesseraCore
import Testing

/// Home mosaic (sheet 199, homeMosaic): sun, sky, captions and what finished, all on the phone.
@MainActor
struct MosaicFactsTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 22) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func facts(_ now: Date, events: [HandsEvent] = []) -> MosaicFacts {
        MosaicFacts.make(engine: engine, now: now, calendar: calendar, place: (37.8, -122.4), events: events)
    }

    // MARK: Sun

    @Test func sunriseAndSunsetFollowTheRealSky() throws {
        let sun = try #require(SunTimes.day(latitude: 37.77, longitude: -122.42, on: at(12), calendar: calendar))
        // San Francisco on Oct 22 (daylight time): solar noon about 12:54 pm and a 10 h 57 min day, so about 7:25 am and
        // 6:23 pm. The same algorithm gives 9:26 UT against the published 9:25 for the Almanac's own example.
        #expect(abs(sun.sunrise.timeIntervalSince(at(7, 25))) < 5 * 60)
        #expect(abs(sun.sunset.timeIntervalSince(at(18, 23))) < 5 * 60)
        // Polar night has no sunrise to draw: the caller falls back.
        #expect(SunTimes.day(latitude: 89, longitude: 0, on: at(12, day: 22), calendar: calendar) == nil)
        let approx = SunTimes.approximate(on: at(12), calendar: calendar)
        #expect(approx.sunrise < approx.sunset)
    }

    @Test func thePlaceIsRoundedBeforeUse() throws {
        let one = try #require(SunTimes.day(latitude: 37.7749, longitude: -122.4194, on: at(12), calendar: calendar))
        let two = try #require(SunTimes.day(latitude: 37.8, longitude: -122.4, on: at(12), calendar: calendar))
        #expect(one == two)
    }

    // MARK: Sky

    @Test func theSkyHitsTheNinePointsOfTheTable() {
        let mosaic = facts(at(12))
        let rise = mosaic.sunrise, set = mosaic.sunset
        #expect(mosaic.sky(at: rise) == MosaicRGB(red: 233, green: 185, blue: 160))
        #expect(mosaic.sky(at: rise.addingTimeInterval(3600)) == MosaicRGB(red: 240, green: 214, blue: 180))
        #expect(mosaic.sky(at: set.addingTimeInterval(-3600)) == MosaicRGB(red: 214, green: 160, blue: 138))
        #expect(mosaic.sky(at: set) == MosaicRGB(red: 176, green: 122, blue: 140))
        #expect(mosaic.sky(at: set.addingTimeInterval(3600)) == MosaicRGB(red: 104, green: 98, blue: 146))
        #expect(mosaic.sky(at: at(22)) == MosaicRGB(red: 58, green: 54, blue: 90))
        #expect(mosaic.sky(atHour: 24) == MosaicRGB(red: 36, green: 34, blue: 58))
        #expect(mosaic.sky(atHour: 0) == MosaicRGB(red: 36, green: 34, blue: 58))
    }

    @Test func theSkyMixesBetweenStopsWithoutJumps() {
        let mosaic = facts(at(12))
        var last = mosaic.sky(atHour: 0)
        for tenth in 1 ... 240 {
            let now = mosaic.sky(atHour: Double(tenth) / 10)
            #expect(abs(now.red - last.red) <= 40 && abs(now.green - last.green) <= 40 && abs(now.blue - last.blue) <=
                40)
            last = now
        }
    }

    // MARK: Captions

    @Test func theCaptionsReadLikeThePage() throws {
        _ = try engine.perform(CreateTask(title: "Tacos", startsAt: at(18, 5)), by: .user)
        let mosaic = facts(at(17, 42))
        #expect(mosaic.freeMinutes == 23)
        #expect(mosaic.caption(for: .day) == "Free 23 min, then Tacos.")
        #expect(mosaic.caption(for: .next) == "23 min until Tacos.")
        #expect(mosaic.caption(for: .time) == "5:42 pm. Thursday.")
        #expect(mosaic.caption(for: .sky).hasPrefix("Sunset at 6:"))
        #expect(facts(at(20)).caption(for: .sky).hasPrefix("Sunset was at "))
        #expect(facts(at(5)).caption(for: .sky).hasPrefix("Sunrise at "))
        #expect(mosaic.caption(for: .done) == "Nothing done yet today.")
        #expect(facts(at(19)).caption(for: .day) == "Nothing else is timed today.")
    }

    @Test func aPrivateOrWalledTitleIsMaskedInEveryCaption() throws {
        _ = try engine.perform(CreateTask(title: "Lexapro refill", startsAt: at(18, 5)), by: .user)
        let mosaic = facts(at(17, 42))
        for scene in MosaicScene.allCases {
            #expect(!mosaic.caption(for: scene).lowercased().contains("lexapro"))
        }
        #expect(mosaic.nextTimed?.title == "Private task")
        let event = HandsEvent(app: .training, label: "Private workout", start: at(17, 50), end: at(18, 30),
                               hands: [], isFixed: false)
        #expect(facts(at(17, 42), events: [event]).nextTimed?.title == "Private workout")
    }

    // MARK: Finished

    @Test func finishedTodayCountsWhatEndedWithNoTitles() throws {
        let task = try engine.perform(CreateTask(title: "Lexapro refill"), by: .user).output
        try engine.perform(SetTaskDone(task: task.id), by: .user)
        let other = try engine.perform(CreateTask(title: "Mail forms"), by: .user).output
        try engine.perform(SetTaskDone(task: other.id), by: .user)
        try engine.perform(SetTaskDone(task: other.id, done: false), by: .user)
        let mosaic = facts(.now)
        #expect(mosaic.finishedToday.count == 1)
        #expect(mosaic.caption(for: .done) == "Done today: 1 thing.")
        #expect(!mosaic.caption(for: .done).contains("Lexapro"))
    }

    @Test func theDayRollsOverAtMidnight() {
        let evening = facts(at(23, 50)), morning = facts(at(0, 10, day: 23))
        #expect(morning.rolledOver(since: evening))
        #expect(!facts(at(23, 55)).rolledOver(since: evening))
    }
}
