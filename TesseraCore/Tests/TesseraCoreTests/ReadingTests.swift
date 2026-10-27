import Foundation
@testable import TesseraCore
import Testing

/// Reading slices 1 to 3 (docs/product/ship-list-m5-reading.md with its Oct 17 amendments).
@MainActor
struct ReadingTests {
    let store = ObjectStore.open(inMemory: true)
    let start = Date(timeIntervalSince1970: 1_792_000_000)
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func engine() throws -> ActionEngine {
        try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test func queuingBuildsOneBookAndTheThingComesFirst() throws {
        let engine = try engine()
        let made = try engine.perform(QueueBook(title: "Dune", author: "Frank Herbert", pages: 612), by: .user)
        #expect(made.record.receipt == "Dune, in the queue" && made.record.summary == "Dune, in the queue")
        #expect(store.value("state", of: made.output)?.stringValue == "queued")
        // Queuing again returns the same book, never a second copy.
        let again = try engine.perform(QueueBook(title: "dune"), by: .user).output
        #expect(again.id == made.output.id)
        #expect(Bookshelf(store: store, classes: engine.classes).queued().count == 1)
    }

    @Test func aBookIsFoundByExactTitleThenByEveryWord() throws {
        let engine = try engine()
        try engine.perform(QueueBook(title: "Dune"), by: .user)
        try engine.perform(QueueBook(title: "The Left Hand of Darkness"), by: .user)
        let shelf = Bookshelf(store: store, classes: engine.classes)
        #expect(shelf.book(named: "dune")?.title == "Dune")
        #expect(shelf.book(named: "left hand")?.title == "The Left Hand of Darkness")
        #expect(shelf.book(named: "darkness left")?.title == "The Left Hand of Darkness")
        #expect(shelf.book(named: "Emma") == nil && shelf.book(named: "  ") == nil)
    }

    @Test func startingOpensASuspendedProcessAtTheSavedPageAndNeverTakesNow() throws {
        let engine = try engine()
        // A workout is running; reading must not displace it.
        let plan = try #require(store.object(id: StarterContent.planID))
        let routine = try #require(store.linkedObjects("routines", of: plan).first)
        try engine.perform(StartRoutine(routine: routine.id, time: start), by: .user)
        let book = try engine.perform(QueueBook(title: "Dune"), by: .user).output
        let started = try engine.perform(StartReading(book: book.id, time: start), by: .user)
        #expect(started.record.receipt == "Dune, started")
        let table = ProcessTable(engine: engine)
        let process = try #require(table.process(for: book))
        #expect(process.state == .suspended && process.ownerApp == "Reading" && process.nextStep == "Dune, p 0")
        #expect(table.running()?.subject?.id != book.id)
    }

    @Test func thePageIsSavedWithoutChangingStateAndSaysFromTo() throws {
        let engine = try engine()
        let book = try engine.perform(QueueBook(title: "Dune", pages: 612), by: .user).output
        try engine.perform(StartReading(book: book.id, time: start), by: .user)
        try engine.perform(SetBookPage(book: book.id, page: 120, time: start), by: .user)
        let moved = try engine.perform(
            SetBookPage(book: book.id, page: 142, time: start.addingTimeInterval(60)),
            by: .user
        )
        #expect(moved.record.summary == "Dune, p 120 to 142" && moved.record.receipt == "Dune, p 142 of 612")
        let process = try #require(ProcessTable(engine: engine).process(for: book))
        #expect(process.nextStep == "Dune, p 142" && process.resumePoint?.index == 142 && process.state == .suspended)
        #expect(store.value("state", of: book)?.stringValue == "reading")
        // Past the known count: kept as said, and the line asks, never finishing on its own.
        let past = try engine.perform(SetBookPage(book: book.id, page: 650), by: .user)
        #expect(past.record.receipt == "Dune, p 650 of 612. Last page. Finished?")
        #expect(store.value("state", of: book)?.stringValue == "reading")
        engine.undo(past.record)
        #expect(Bookshelf(store: engine.store, classes: engine.classes).page(of: book) == 142)
    }

    @Test func finishingKeepsTheReviewAndEndsTheProcessAndUndoBringsItBack() throws {
        let engine = try engine()
        let book = try engine.perform(QueueBook(title: "Dune"), by: .user).output
        try engine.perform(StartReading(book: book.id, time: start), by: .user)
        let done = try engine.perform(
            FinishBook(book: book.id, review: "slow start, great end", time: start),
            by: .user
        )
        #expect(done.record.summary == "Dune, finished: slow start, great end")
        #expect(done.record.receipt == "Dune, finished: slow start, great end")
        #expect(ProcessTable(engine: engine).process(for: book) == nil)
        #expect(Bookshelf(store: store, classes: engine.classes).finished().map(\.title) == ["Dune"])
        engine.undo(done.record)
        #expect(store.value("state", of: book)?.stringValue == "reading")
        #expect(ProcessTable(engine: engine).process(for: book) != nil)
        let bare = try engine.perform(FinishBook(book: book.id), by: .user)
        #expect(bare.record.receipt == "Dune, finished. One line on it?")
    }

    @Test func settingAsideKeepsTheBookAndStartAgainRestoresItAtItsPage() throws {
        let engine = try engine()
        let book = try engine.perform(QueueBook(title: "Dune"), by: .user).output
        try engine.perform(StartReading(book: book.id, time: start), by: .user)
        try engine.perform(SetBookPage(book: book.id, page: 90), by: .user)
        let aside = try engine.perform(SetBookAside(book: book.id), by: .user)
        #expect(aside.record.receipt == "Dune, set aside")
        #expect(Bookshelf(store: store, classes: engine.classes).dropped().count == 1)
        try engine.perform(StartReading(book: book.id, time: start.addingTimeInterval(3600)), by: .user)
        #expect(store.value("state", of: book)?.stringValue == "reading")
        #expect(ProcessTable(engine: engine).process(for: book)?.nextStep == "Dune, p 90")
    }

    @Test func aBookIsNeverPutAwayAtSevenDays() throws {
        let engine = try engine()
        let book = try engine.perform(QueueBook(title: "Dune"), by: .user).output
        try engine.perform(StartReading(book: book.id, time: start), by: .user)
        let table = ProcessTable(engine: engine)
        _ = table.tidy(now: start.addingTimeInterval(30 * 86400))
        #expect(table.process(for: book)?.state == .suspended)
        #expect(store.value("state", of: book)?.stringValue == "reading")
    }

    @Test func theEveningSlotIsSevenToElevenAndOnlyWhenNothingElseIsGoing() throws {
        let engine = try engine()
        let book = try engine.perform(QueueBook(title: "Dune"), by: .user).output
        let noon = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 12)))
        try engine.perform(StartReading(book: book.id, time: noon), by: .user)
        let shelf = Bookshelf(store: store, classes: engine.classes)
        func pick(_ hour: Int, runs: Bool = false, timed: Bool = false, minute: Int = 0) -> String? {
            let when = calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: hour, minute: minute))!
            return shelf.eveningPick(at: when, calendar: calendar, somethingRuns: runs, timedItemCurrent: timed)?
                .nextStep
        }
        #expect(pick(18, minute: 59) == nil)
        #expect(pick(19) == "Dune, p 0" && pick(22, minute: 59) == "Dune, p 0")
        #expect(pick(23) == nil && pick(7) == nil)
        #expect(pick(20, runs: true) == nil && pick(20, timed: true) == nil)
    }

    @Test func aPrivateBookReadsPrivateBookAndABareTitleNeverMasks() throws {
        let engine = try engine()
        let book = try engine.perform(QueueBook(title: "Dune"), by: .user).output
        #expect(ObjectPrivacy.label(of: book, in: store, classes: engine.classes) == nil)
        let rent = try engine.perform(QueueBook(title: "Rent"), by: .user).output
        #expect(ObjectPrivacy.label(of: rent, in: store, classes: engine.classes) == nil)
        try engine.perform(EditBook(book: book.id, isPrivate: true), by: .user)
        #expect(ObjectPrivacy.label(of: book, in: store, classes: engine.classes) == "Private book")
        let json = try String(decoding: TesseraExport(context: store.context).encoded(), as: UTF8.self)
        #expect(!json.contains("Dune") && json.contains("Rent"))
    }
}
