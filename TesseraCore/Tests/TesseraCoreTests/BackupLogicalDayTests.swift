import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// docs/research/backup-logical-day.md: the daily copy is named and written by his day (04:00 to 04:00).
@MainActor
struct BackupLogicalDayTests {
    let dir: URL
    let store: ObjectStore
    let backups: URL
    let la = TesseraDayTests.calendar

    init() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        let classes = try store.prepareCatalog()
        // Something he did, so the store is worth a copy (an empty one never is: restore walk, risk 1).
        try ActionEngine(store: store, classes: classes).perform(CreateNote(body: "Bench felt heavy"), by: .user)
        store.save()
        backups = dir.appendingPathComponent("Backups")
    }

    /// A second store in its own folder with `notes` notes, for copies with more or fewer of his actions.
    func otherStore(notes: Int) throws -> ObjectStore {
        let folder = dir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let other = try ObjectStore(context: TesseraContext(url: folder.appendingPathComponent("tessera.sqlite")))
        let engine = try ActionEngine(store: other, classes: other.prepareCatalog())
        for index in 0 ..< notes {
            try engine.perform(CreateNote(body: "Note \(index)"), by: .user)
        }
        other.save()
        return other
    }

    @Test func anEmptyStoreIsNeverCopied() throws {
        // Restore walk risk 1: a fresh install pointed at the folder writes nothing, so no good copy is crowded out.
        let empty = try otherStore(notes: 0)
        for day in 0 ..< 8 {
            try write(at(10, 10 + day, 12))
        }
        #expect(files().count == 7)
        let oldest = files().first
        #expect(try TesseraBackup.writeRolling(from: empty.context, in: backups, now: at(10, 18, 12), calendar: la)
            == nil)
        #expect(try TesseraBackup.writeRolling(from: empty.context, in: backups, now: at(10, 18, 0, 30),
                                               calendar: la) == nil)
        #expect(files().count == 7 && files().first == oldest)
    }

    @Test func aLateCopyWithFewerActionsLeavesTheDaysCopy() throws {
        // Between 00:00 and 04:00 the day's copy is replaced only by one holding at least as many of his actions.
        let fuller = try otherStore(notes: 3)
        #expect(try TesseraBackup.writeRolling(from: fuller.context, in: backups, now: at(10, 21, 7, 42), calendar: la)
            == backups.appendingPathComponent("Tessera-2026-10-21.tessera"))
        #expect(try write(at(10, 22, 0, 20)) == nil)
        #expect(try TesseraBackup.userOps(at: backups.appendingPathComponent("Tessera-2026-10-21.tessera")) == 3)
        #expect(try TesseraBackup.writeRolling(from: fuller.context, in: backups, now: at(10, 22, 0, 30), calendar: la)
            != nil)
    }

    @Test func aRestoreRewritesTodaysCopy() throws {
        // Restore walk risk 2: after a restore, today's copy (the store from before) is rewritten at once.
        try write(at(10, 21, 7, 42))
        #expect(try write(at(10, 21, 12)) == nil)
        let marker = TesseraBackup.restoreMarker(for: dir.appendingPathComponent("tessera.sqlite"))
        try String(at(10, 21, 11).timeIntervalSince1970).write(to: marker, atomically: true, encoding: .utf8)
        #expect(try write(at(10, 21, 12)) == "Tessera-2026-10-21.tessera")
        #expect(try created("Tessera-2026-10-21.tessera") == at(10, 21, 12))
        #expect(try write(at(10, 21, 13)) == nil)
    }

    func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0, year: Int = 2026,
            in calendar: Calendar? = nil) -> Date
    {
        (calendar ?? la).date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @discardableResult
    func write(_ now: Date, in calendar: Calendar? = nil) throws -> String? {
        try TesseraBackup.writeRolling(from: store.context, in: backups, now: now, calendar: calendar ?? la)?
            .lastPathComponent
    }

    func files() -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: backups.path)) ?? []).sorted()
    }

    func created(_ name: String) throws -> Date {
        try TesseraBackup.inspect(backups.appendingPathComponent(name)).createdAt
    }

    @Test func t1NormalDayWritesOnceAfterFour() throws {
        #expect(try write(at(10, 21, 7, 42)) == "Tessera-2026-10-21.tessera")
        #expect(try write(at(10, 21, 12, 10)) == nil)
        #expect(try write(at(10, 21, 21)) == nil)
        #expect(try write(at(10, 22, 7, 42)) == "Tessera-2026-10-22.tessera")
    }

    @Test func t2LateNightReplacesThePreviousLogicalDay() throws {
        try write(at(10, 21, 7, 42))
        #expect(try write(at(10, 21, 23, 10)) == nil)
        #expect(try write(at(10, 22, 0, 20)) == "Tessera-2026-10-21.tessera")
        #expect(try created("Tessera-2026-10-21.tessera") == at(10, 22, 0, 20))
        #expect(try write(at(10, 22, 3, 59)) == "Tessera-2026-10-21.tessera")
        #expect(try write(at(10, 22, 4)) == "Tessera-2026-10-22.tessera")
        #expect(try write(at(10, 22, 7, 42)) == nil)
        #expect(files() == ["Tessera-2026-10-21.tessera", "Tessera-2026-10-22.tessera"])
    }

    @Test func t4FirstEverCopyAfterMidnightTakesYesterdaysName() throws {
        #expect(try write(at(10, 20, 1, 10)) == "Tessera-2026-10-19.tessera")
        #expect(try write(at(10, 20, 7, 30)) == "Tessera-2026-10-20.tessera")
    }

    @Test func t6FallBackBothOneThirtiesReplaceSaturday() throws {
        try write(at(10, 31, 8))
        #expect(try write(Date(timeIntervalSince1970: 1_793_521_800)) == "Tessera-2026-10-31.tessera") // 01:30 PDT
        #expect(try write(Date(timeIntervalSince1970: 1_793_525_400)) == "Tessera-2026-10-31.tessera") // 01:30 PST
        #expect(try write(at(11, 1, 3, 30)) == "Tessera-2026-10-31.tessera")
        #expect(try write(at(11, 1, 4, 5)) == "Tessera-2026-11-01.tessera")
    }

    @Test func t7SpringForwardThreeTenIsStillSaturday() throws {
        try write(at(3, 13, 8, year: 2027))
        #expect(try write(at(3, 14, 1, 50, year: 2027)) == "Tessera-2027-03-13.tessera")
        #expect(try write(at(3, 14, 3, 10, year: 2027)) == "Tessera-2027-03-13.tessera")
        #expect(try write(at(3, 14, 4, 5, year: 2027)) == "Tessera-2027-03-14.tessera")
    }

    @Test func t8TravelKeysByTheZoneInForce() throws {
        var newYork = la
        newYork.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        try write(at(10, 26, 7, 30))
        #expect(try write(at(10, 27, 6, 50, in: newYork), in: newYork) == "Tessera-2026-10-27.tessera")
        #expect(try write(at(10, 28, 1, 15, in: newYork), in: newYork) == "Tessera-2026-10-27.tessera")
        #expect(try write(at(10, 28, 7, in: newYork), in: newYork) == "Tessera-2026-10-28.tessera")
        #expect(try write(at(10, 29, 0, 30)) == "Tessera-2026-10-28.tessera")
        #expect(try write(at(10, 29, 7, 30)) == "Tessera-2026-10-29.tessera")
    }

    @Test func t9ClockSetBackNeverDeletesTheCopyJustWritten() throws {
        for day in 16 ... 22 {
            try write(at(10, day, 8))
        }
        #expect(try write(at(10, 10, 12)) == "Tessera-2026-10-10.tessera")
        #expect(files().count == 8 && files().contains("Tessera-2026-10-10.tessera"))
        // Clock back to normal: the 7 newest days stay.
        try write(at(10, 23, 7, 30))
        #expect(files().first == "Tessera-2026-10-17.tessera" && files().count == 7)
        // Behind the newest copy: no replace of an existing day.
        #expect(try write(at(10, 23, 1)) == nil)
    }

    @Test func t10PruneKeepsSevenNewestLogicalDays() throws {
        for day in [10, 12, 14, 16, 18, 19, 20] {
            try write(at(10, day, 8))
        }
        #expect(try write(at(10, 21, 0, 30)) == "Tessera-2026-10-20.tessera")
        #expect(files().count == 7)
        try write(at(10, 21, 7, 42))
        #expect(files() == ["12", "14", "16", "18", "19", "20", "21"].map { "Tessera-2026-10-\($0).tessera" })
    }

    @Test func t12AStrayPartialIsCleanedUp() throws {
        try FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)
        let stray = backups.appendingPathComponent(".Tessera-2026-10-18.tessera.partial")
        FileManager.default.createFile(atPath: stray.path, contents: Data("x".utf8))
        try write(at(10, 21, 12))
        #expect(files() == ["Tessera-2026-10-21.tessera"])
    }

    @Test func t5RestoreIsMarkedAndKeepsThreeBeforeRestoreCopies() throws {
        try write(at(10, 18, 8))
        let source = backups.appendingPathComponent("Tessera-2026-10-18.tessera")
        // A restore applies at launch, before the store opens: use a closed store file.
        let storeURL = dir.appendingPathComponent("closed.sqlite")
        try FileManager.default.copyItem(at: source, to: storeURL)
        let kept = dir.appendingPathComponent("Kept")
        for minute in 0 ..< 4 {
            _ = try TesseraBackup.stageRestore(from: source, storeURL: storeURL)
            #expect(TesseraBackup.applyPendingRestore(to: storeURL, keepIn: kept, now: at(10, 20, 10, minute)))
        }
        let befores = try FileManager.default.contentsOfDirectory(atPath: kept.path).filter {
            $0.hasPrefix("Before-restore-")
        }
        #expect(befores.count == TesseraBackup.keepBeforeRestore)
        // A copy written after a restore carries when it happened.
        let reopened = try ObjectStore(context: TesseraContext(url: storeURL))
        let copy = dir.appendingPathComponent("after.tessera")
        try TesseraBackup.write(from: reopened.context, to: copy, now: at(10, 21, 8))
        #expect(try TesseraBackup.inspect(copy).restoredAt == at(10, 20, 10, 3))
        TesseraSchema.clearLaunchNote()
    }
}
