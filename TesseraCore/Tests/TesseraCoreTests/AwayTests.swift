import Foundation
@testable import TesseraCore
import Testing

/// Together round 14, 187 awayV2: an occasion marked away quiets Home for its days. Never automatic, words only.
@MainActor
struct AwayTests {
    let store = ObjectStore.open(inMemory: true)
    let engine: ActionEngine
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    init() throws {
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func day(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    func trip(_ title: String = "Trip", links: [ObjectRecord] = []) throws -> ObjectRecord {
        try engine.perform(
            CreateOccasion(title: title, start: day(26, 0), end: day(28, 0), links: links.map(\.id)), by: .user
        ).output
    }

    func packing(items: Int, done: Int) throws -> ObjectRecord {
        let list = try store.create(#require(engine.classes[.list]), title: "Packing")
        var made: [ObjectRecord] = []
        for index in 0 ..< items {
            try made.append(engine.perform(AddListItem(list: list.id, text: "thing\(index)"), by: .user).output)
        }
        for item in made.prefix(done) {
            try engine.perform(CheckListItem(item: item.id), by: .user)
        }
        return list
    }

    func line(_ date: Date) -> String? {
        Away.line(engine: engine, now: date, calendar: calendar)
    }

    @Test func nothingIsAwayUntilItIsMarked() throws {
        _ = try trip()
        #expect(line(day(27)) == nil && !Away.isAway(engine: engine, now: day(27), calendar: calendar))
    }

    @Test func aMarkedTripSaysItsDayAndThePackingList() throws {
        let list = try packing(items: 3, done: 3)
        let occasion = try trip(links: [list])
        try engine.perform(SetAway(occasion: occasion.id, on: true), by: .user)
        #expect(line(day(27)) == "Trip, day 2. Packing is done")
        #expect(Away.day(of: occasion, store: store, now: day(26), calendar: calendar)?.day == 1)
        let open = try packing(items: 4, done: 1)
        try engine.perform(LinkToOccasion(occasion: occasion.id, thing: open.id), by: .user)
        #expect(line(day(28))?.hasPrefix("Trip, the last day") == true)
    }

    @Test func itIsQuietOnlyOnTheTripsOwnDays() throws {
        let occasion = try trip()
        try engine.perform(SetAway(occasion: occasion.id, on: true), by: .user)
        #expect(line(day(25)) == nil)
        #expect(line(day(26)) == "Trip, day 1")
        #expect(line(day(29)) == nil)
    }

    @Test func onlyOneTripIsAwayAndUndoTakesItBack() throws {
        let first = try trip("First")
        let second = try engine.perform(
            CreateOccasion(title: "Second", start: day(26, 0), end: day(27, 0)), by: .user
        ).output
        try engine.perform(SetAway(occasion: first.id, on: true), by: .user)
        let made = try engine.perform(SetAway(occasion: second.id, on: true), by: .user)
        #expect(line(day(26)) == "Second, day 1")
        try engine.undo(made.record)
        #expect(line(day(26)) == "First, day 1")
        try engine.perform(SetAway(occasion: first.id, on: false), by: .user)
        #expect(line(day(26)) == nil)
    }

    @Test func theLineIsWordsOnlyAndAPrivateTitleReadsAway() throws {
        let pool = try engine.perform(CreatePool(name: "Trip fund", opening: "500"), by: .user).output
        let occasion = try trip(links: [pool])
        try engine.perform(SetAway(occasion: occasion.id, on: true), by: .user)
        let text = try #require(line(day(27)))
        #expect(!text.contains("$") && !text.contains("500") && !text.lowercased().contains("fund"))
        // A title that later names a pool reads "Away" and the summary says nothing of it.
        try engine.perform(RenameObject(object: occasion.id, title: "Trip fund"), by: .user)
        #expect(line(day(27)) == "Away, day 2")
        let made = try engine.perform(SetAway(occasion: occasion.id, on: true), by: .user)
        #expect(made.record.summary == "Away on")
    }

    @Test func aPrivatePackingListIsNeverNamedOrCounted() throws {
        let list = try packing(items: 2, done: 0)
        try engine.perform(RenameObject(object: list.id, title: "Packing Lexapro"), by: .user)
        let occasion = try trip(links: [list])
        try engine.perform(SetAway(occasion: occasion.id, on: true), by: .user)
        #expect(line(day(27)) == "Trip, day 2")
    }

    /// A phone that already has Occasions gets the new field on the next launch, off, and keeps its trips.
    @Test func reseedingAddsAwayToAnInstallWithOccasionsAndItStartsOff() throws {
        let occasion = try trip()
        let classDef = try #require(engine.classes[.occasion])
        let field = try #require(classDef.ownFields?.first { $0.key == "away" })
        store.context.delete(field)
        try store.context.save()
        #expect(ClassResolver.field("away", of: classDef) == nil)

        try SystemCatalog.seed(in: store.context)
        let added = try #require(ClassResolver.field("away", of: classDef))
        #expect(added.id == SystemCatalog.stableID("system.occasion.away"))
        #expect(added.defaultValue == .bool(false))
        #expect(Away.current(engine: engine, now: day(27), calendar: calendar) == nil)
        #expect(store.value("start", of: occasion)?.dateValue != nil)
        try engine.perform(SetAway(occasion: occasion.id, on: true), by: .user)
        #expect(line(day(27)) == "Trip, day 2")
    }
}
