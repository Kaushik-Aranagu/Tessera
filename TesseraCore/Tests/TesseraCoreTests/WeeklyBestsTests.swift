import Foundation
@testable import TesseraCore
import Testing

/// Sheet 210: twelve weekly bests and the best week index, for the Training room's lintel.
@MainActor
struct WeeklyBestsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }

    /// Thursday, October 22, 2026, 12:00.
    var now: Date {
        Date(timeIntervalSince1970: 1_792_670_400)
    }

    init() throws {
        classes = try store.prepareCatalog()
    }

    var ledger: TrainingLedger {
        TrainingLedger(store: store, classes: classes)
    }

    func lift(daysAgo: Double, _ sets: [(Double, Double)], warmup: Bool = false) throws {
        let ended = now.addingTimeInterval(-daysAgo * 86400)
        let workout = try store.create(#require(classes[.workout]), title: "Push")
        try store.set("endedAt", to: .date(ended), on: workout)
        let entry = try store.create(#require(classes[.exerciseEntry]), parent: workout)
        try store.setClassLink("exercise", on: entry, to: #require(classes[.benchPress]))
        for set in sets {
            let made = try ledger.logSet(weight: set.0, reps: set.1, isWarmup: warmup, in: entry)
            try store.set("loggedAt", to: .date(ended), on: made)
        }
    }

    func bests() throws -> WeeklyBests {
        try ledger.weeklyBests(of: #require(classes[.benchPress]), now: now, calendar: calendar)
    }

    @Test func nothingLoggedIsEmpty() throws {
        let result = try bests()
        #expect(result.bests.count == 12 && result.isEmpty && result.whenWords == nil)
    }

    @Test func eachWeekKeepsItsBestAndTheBestWeekIsFound() throws {
        try lift(daysAgo: 1, [(80, 5)]) // this week
        try lift(daysAgo: 8, [(90, 5), (70, 5)]) // last week
        try lift(daysAgo: 22, [(100, 5)]) // three weeks ago: the best
        try lift(daysAgo: 60, [(60, 5)])
        let result = try bests()
        #expect(result.bests.compactMap(\.self).count == 4)
        #expect(result.bestIndex == 8)
        #expect(result.weeksAgo == 3 && result.whenWords == "three weeks ago")
        #expect(result.bestWeight == 100 && result.bestReps == 5)
        #expect(result.bests[11] != nil && result.bests[10]! > result.bests[11]!)
    }

    @Test func olderThanTwelveWeeksAndFutureAreLeftOut() throws {
        try lift(daysAgo: 100, [(150, 5)])
        try lift(daysAgo: 2, [(80, 5)])
        let result = try bests()
        #expect(result.bests.compactMap(\.self).count == 1)
        #expect(result.weeksAgo == 0 && result.whenWords == "this week")
    }

    @Test func aTieGoesToTheLaterWeekAndLastWeekReadsLastWeek() throws {
        try lift(daysAgo: 9, [(100, 5)])
        try lift(daysAgo: 16, [(100, 5)])
        let result = try bests()
        #expect(result.weeksAgo == 1 && result.whenWords == "last week")
    }

    @Test func warmupsDoNotCount() throws {
        try lift(daysAgo: 2, [(200, 5)], warmup: true)
        #expect(try bests().isEmpty)
    }
}
