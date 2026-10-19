import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// The calendar and Health mirrors (and held notices) never reach the op log, a backup copy of any kind, or an
/// export (Kaushik's standing rule: health and calendar values stay out of backups and logs).
@MainActor
struct MirrorPrivacyTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    func at(_ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: hour))!
    }

    func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A store holding one of each mirror, plus a plain note that must survive.
    func mirrored(at url: URL) throws -> (ObjectStore, ActionEngine) {
        let store = try ObjectStore(context: TesseraContext(url: url))
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let event = CalendarEventInput(externalID: "chemo", title: "Oncology quokkaclinic", start: at(10), end: at(11),
                                       calendarName: "Work", selfStatus: .accepted)
        try engine.perform(SyncCalendar(inputs: [event], windowStart: at(0), windowEnd: at(23)), by: .system)
        let sleep = [SleepSample(value: .asleepCore, start: at(0).addingTimeInterval(-3600), end: at(6),
                                 sourceBundle: "w", productType: "Watch7,1")]
        try engine.perform(SyncHealth(inputs: HealthInputs(sleep: sleep, stepsToday: 4242, restingHeartRate: 61,
                                                           restingHeartRateAt: at(7)),
                                      now: at(8), zone: "America/Los_Angeles"), by: .system)
        try engine.perform(HoldNotice(title: "zebraheld notice"), by: .system)
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        store.save()
        return (store, engine)
    }

    @Test func theMirrorsWriteNoOpsAtAll() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let (store, engine) = try mirrored(at: dir.appendingPathComponent("tessera.sqlite"))
        let mirrorIDs = PrivateWords.mirrorIDs(in: store.context)
        #expect(mirrorIDs.count >= 5)
        for record in store.context.all(OpRecord.self) {
            #expect(record.objectIDs.allSatisfy { !mirrorIDs.contains($0) }, "\(record.action)")
        }
        #expect(engine.history(limit: 50)
            .allSatisfy { !["syncCalendar", "syncHealth", "holdNotice"].contains($0.action) })
    }

    @Test func theSharedExportLeavesTheMirrorsOut() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let (store, _) = try mirrored(at: dir.appendingPathComponent("tessera.sqlite"))
        let json = try String(decoding: TesseraExport(context: store.context).encoded(), as: UTF8.self)
        #expect(!json.contains("quokkaclinic") && !json.contains("4242") && !json.contains("zebraheld"))
        #expect(json.contains("Bench felt heavy"))
    }

    @Test func noBackupCopyHoldsThemNotTheLocalOneNorTheICloudOne() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let (store, _) = try mirrored(at: dir.appendingPathComponent("tessera.sqlite"))
        let local = dir.appendingPathComponent("local.tessera")
        let icloud = dir.appendingPathComponent("icloud.tessera")
        try TesseraBackup.write(from: store.context, to: local)
        try TesseraBackup.write(from: store.context, to: icloud, leavingOutPrivate: true)
        for copy in [local, icloud] {
            let queue = try DatabaseQueue(path: copy.path)
            let rows: [String] = try queue.read { try String.fetchAll($0, sql: "SELECT title FROM object") }
            let values: [String] = try queue.read {
                try Data.fetchAll($0, sql: "SELECT \"values\" FROM object WHERE \"values\" IS NOT NULL")
                    .map { String(decoding: $0, as: UTF8.self) }
            }
            let text = (rows + values).joined(separator: " ")
            #expect(!text.contains("quokkaclinic") && !text.contains("zebraheld"), "\(copy.lastPathComponent)")
            #expect((rows + values).contains { $0.contains("Bench felt heavy") }, "the plain note is kept")
        }
    }
}
