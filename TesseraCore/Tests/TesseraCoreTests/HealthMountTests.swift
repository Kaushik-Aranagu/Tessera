import Foundation
@testable import TesseraCore
import Testing

/// M4 slice 2: the Health mount (docs/research/calendar-health-fixtures.md H01 to H17). "Now" is Tuesday 2026-10-20
/// 08:00 in Los Angeles unless a case says otherwise.
@MainActor
struct HealthMountTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    /// `day` 19 or 20 of October at `hh:mm`.
    func at(_ day: Int, _ time: String) -> Date {
        let parts = time.split(separator: ":").map { Int($0)! }
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: parts[0], minute: parts[1]))!
    }

    var now: Date {
        at(20, "08:00")
    }

    func watch(_ value: SleepValue, _ from: (Int, String), _ to: (Int, String)) -> SleepSample {
        SleepSample(value: value, start: at(from.0, from.1), end: at(to.0, to.1),
                    sourceBundle: "com.apple.health.W1", productType: "Watch7,1")
    }

    func phone(_ value: SleepValue, _ from: (Int, String), _ to: (Int, String)) -> SleepSample {
        SleepSample(value: value, start: at(from.0, from.1), end: at(to.0, to.1), productType: "iPhone18,1")
    }

    func night(_ samples: [SleepSample], now: Date? = nil) -> SleepNightResult? {
        SleepNightBuilder.night(from: samples, now: now ?? self.now, calendar: calendar)
    }

    @Test func h01TheWatchWinsAndTheIPhoneOnlyFillsInBed() throws {
        let result = try #require(night([
            phone(.inBed, (19, "22:50"), (20, "06:55")),
            watch(.asleepCore, (19, "23:10"), (20, "01:00")), watch(.asleepDeep, (20, "01:00"), (20, "02:10")),
            watch(.asleepREM, (20, "02:10"), (20, "03:00")), watch(.awake, (20, "03:00"), (20, "03:15")),
            watch(.asleepCore, (20, "03:15"), (20, "06:40")),
        ]))
        #expect(result.asleepMinutes == 435 && result.inBedMinutes == 485 && result.source == "Apple Watch")
        #expect(result.coreMinutes == 315 && result.deepMinutes == 70 && result.remMinutes == 50)
        #expect(result.awakeMinutes == 15 && result.date == calendar.startOfDay(for: now))
    }

    @Test func h02TwoAsleepSourcesAreNeverSummed() throws {
        let app = SleepSample(value: .asleepUnspecified, start: at(19, "23:00"), end: at(20, "07:05"),
                              sourceBundle: "com.tantsissa.AutoSleep", productType: "iPhone18,1")
        let result = try #require(night([watch(.asleepCore, (19, "23:20"), (20, "06:50")), app]))
        #expect(result.asleepMinutes == 450 && result.source == "Apple Watch") // the Watch's own span
    }

    @Test func h03IPhoneOnlyReadsAsInBedAndNeverAsSlept() throws {
        let result = try #require(night([phone(.inBed, (19, "23:05"), (20, "06:50"))]))
        #expect(result.asleepMinutes == nil && result.inBedMinutes == 465 && result.basis == "inBed")
        #expect(result.source == "iPhone")
    }

    @Test func h04ANightBelongsToTheDayItEnds() throws {
        let result = try #require(night([watch(.asleepCore, (19, "23:40"), (20, "07:05"))]))
        #expect(result.date == calendar.startOfDay(for: at(20, "12:00")) && result.asleepMinutes == 445)
    }

    @Test func h05ANapIsIgnored() throws {
        let result = try #require(night([
            watch(.asleepCore, (19, "23:30"), (20, "06:30")),
            watch(.asleepCore, (20, "12:40"), (20, "13:20")),
        ], now: at(20, "16:00")))
        #expect(result.asleepMinutes == 420)
    }

    @Test func h06HeadlineIsAsleepNotInBedAndAwakeIsSubtracted() throws {
        let result = try #require(night([
            watch(.inBed, (19, "22:30"), (20, "07:00")), watch(.asleepCore, (19, "23:05"), (20, "03:00")),
            watch(.awake, (20, "03:00"), (20, "03:25")), watch(.asleepREM, (20, "03:25"), (20, "06:35")),
        ]))
        #expect(result.asleepMinutes == 425 && result.inBedMinutes == 510 && result.awakeMinutes == 25)
    }

    @Test func h07UnspecifiedCountsAsAsleepWithNoStages() throws {
        let app = SleepSample(value: .asleepUnspecified, start: at(19, "23:15"), end: at(20, "06:45"),
                              sourceBundle: "com.example.sleepapp", productType: "iPhone18,1")
        let result = try #require(night([app]))
        #expect(result.asleepMinutes == 450 && result.coreMinutes == nil && result.source == "com.example.sleepapp")
    }

    @Test func h08TheFullerNonWatchSourceWinsWhole() throws {
        func app(_ bundle: String, _ end: String) -> SleepSample {
            SleepSample(value: .asleepUnspecified, start: at(19, "23:30"), end: at(20, end), sourceBundle: bundle,
                        productType: "")
        }
        let result = try #require(night([app("com.example.ringapp", "06:00"), app("com.example.mattress", "06:40")]))
        #expect(result.asleepMinutes == 430 && result.source == "com.example.mattress")
    }

    @Test func h09ATrackerThatStoppedEarlyIsPartial() throws {
        let result = try #require(night([
            watch(.asleepCore, (19, "23:30"), (20, "03:10")), phone(.inBed, (19, "23:00"), (20, "06:55")),
        ]))
        #expect(result.asleepMinutes == 220 && result.inBedMinutes == 475 && result.partial)
    }

    @Test func h11NoDataIsNoNight() {
        #expect(night([]) == nil)
    }

    @Test func h10AndSyncUpsertsByDateAndLateSyncFillsIn() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        func sync(_ inputs: HealthInputs) throws {
            try engine.perform(SyncHealth(inputs: inputs, now: now, zone: "America/Los_Angeles"), by: .system)
        }
        let nights = { store.objects(of: engine.classes[.sleepNight]!).filter { !$0.isDeleted } }
        try sync(HealthInputs()) // the Watch has not synced: nothing is written
        #expect(nights().isEmpty && engine.history(limit: 5).isEmpty)
        let synced = [watch(.asleepCore, (19, "23:05"), (20, "03:00")), watch(.awake, (20, "03:00"), (20, "03:25")),
                      watch(.asleepREM, (20, "03:25"), (20, "06:35"))]
        try sync(HealthInputs(sleep: synced))
        #expect(nights().count == 1)
        // Recomputed on the next foreground, upserted by date: still one object.
        try sync(HealthInputs(sleep: synced + [watch(.asleepCore, (20, "06:35"), (20, "06:50"))]))
        let object = try #require(nights().first)
        #expect(nights().count == 1 && store.number("asleepMinutes", of: object) == 440)
    }

    @Test func h13StepsAndH15RestingHeartRate() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let fresh = HealthInputs(stepsToday: 7900, restingHeartRate: 54, restingHeartRateAt: at(20, "06:58"))
        try engine.perform(SyncHealth(inputs: fresh, now: now, zone: "America/Los_Angeles"), by: .system)
        let stepsClass = try #require(engine.classes[.stepsDay])
        let steps = try #require(store.objects(of: stepsClass).first)
        #expect(store.number("count", of: steps) == 7900)
        let heartClass = try #require(engine.classes[.restingHeartRate])
        let heart = try #require(store.objects(of: heartClass).first)
        #expect(store.number("bpm", of: heart) == 54)
    }

    @Test func h14AndH15AStaleRestingHeartRateIsHidden() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let heartClass = try #require(engine.classes[.restingHeartRate])
        let stale = HealthInputs(
            restingHeartRate: 57,
            restingHeartRateAt: at(19, "07:02").addingTimeInterval(-86400 * 2)
        )
        try engine.perform(SyncHealth(inputs: stale, now: now, zone: "America/Los_Angeles"), by: .system)
        #expect(store.objects(of: heartClass).isEmpty)
        try engine.perform(SyncHealth(inputs: HealthInputs(), now: now, zone: "America/Los_Angeles"), by: .system)
        #expect(store.objects(of: heartClass).isEmpty)
    }

    @Test func h17AReadErrorChangesNothing() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let sleepClass = try #require(engine.classes[.sleepNight])
        let sleep = [watch(.asleepCore, (19, "23:05"), (20, "06:35"))]
        try engine.perform(SyncHealth(inputs: HealthInputs(sleep: sleep), now: now, zone: "America/Los_Angeles"),
                           by: .system)
        let before = engine.history(limit: 20).count
        try engine.perform(SyncHealth(inputs: HealthInputs(readFailed: true), now: now, zone: "America/Los_Angeles"),
                           by: .system)
        #expect(engine.history(limit: 20).count == before)
        #expect(store.objects(of: sleepClass).count == 1)
    }
}
