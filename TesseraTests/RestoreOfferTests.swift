import Foundation
@testable import Tessera
@testable import TesseraCore
import Testing

/// B8: the quiet restore offer (G688), the launch note queue (G694) and the signing-lapse line (G693).
@Suite(.serialized) @MainActor
struct RestoreOfferTests {
    let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "restore-offer-\(UUID().uuidString)"))
        RestoreOffer.defaults = defaults
    }

    func reset() {
        RestoreOffer.defaults = .standard
    }

    private var pacific: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return calendar
    }

    private func date(_ text: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: text))
    }

    // MARK: The offer is made once

    @Test func freshStoreOffersRestoreOnceAndNotNowKeepsItGone() throws {
        defer { reset() }
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        #expect(TesseraBackup.offersRestore(in: store.context, folderPicked: false, restoreStaged: false,
                                            dismissed: RestoreOffer.isDismissed))
        RestoreOffer.dismiss()
        #expect(RestoreOffer.isDismissed)
        #expect(!TesseraBackup.offersRestore(in: store.context, folderPicked: false, restoreStaged: false,
                                             dismissed: RestoreOffer.isDismissed))
        _ = classes
    }

    @Test func hisFirstActionEndsTheOffer() throws {
        defer { reset() }
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try ActionEngine(store: store, classes: classes).perform(CreateNote(body: "Bench felt heavy"), by: .user)
        #expect(!TesseraBackup.offersRestore(in: store.context, folderPicked: false, restoreStaged: false,
                                             dismissed: RestoreOffer.isDismissed))
    }

    @Test func offerPicksTheNewestCopyFromBeforeThisStore() throws {
        let born = try date("2026-10-19T14:00:00Z")
        let old = try (url: URL(fileURLWithPath: "/a.tessera"), createdAt: date("2026-10-03T15:00:00Z"))
        let newer = try (url: URL(fileURLWithPath: "/b.tessera"), createdAt: date("2026-10-18T15:00:00Z"))
        // This store's own daily copy has nothing of his.
        let own = try (url: URL(fileURLWithPath: "/c.tessera"), createdAt: date("2026-10-19T20:00:00Z"))
        let offer = RestoreOffer.offer(fresh: true, busy: false, copies: [old, own, newer], storeBornAt: born)
        #expect(offer == .copy(url: newer.url, createdAt: newer.createdAt))
        #expect(RestoreOffer.offer(fresh: true, busy: false, copies: [own], storeBornAt: born) == .backups)
        #expect(RestoreOffer.offer(fresh: true, busy: false, copies: [], storeBornAt: born) == .backups)
    }

    @Test func noOfferOnAStoreWithHisThingsOrWhileSomethingRuns() throws {
        let copy = try (url: URL(fileURLWithPath: "/a.tessera"), createdAt: date("2026-10-03T15:00:00Z"))
        #expect(RestoreOffer.offer(fresh: false, busy: false, copies: [copy], storeBornAt: nil) == nil)
        #expect(RestoreOffer.offer(fresh: true, busy: true, copies: [copy], storeBornAt: nil) == nil)
    }

    // MARK: Copy

    @Test func offerAndWarningReadDateFirst() throws {
        let stamp = try date("2026-10-03T17:00:00Z")
        #expect(RestoreOfferCopy.day(stamp, calendar: pacific) == "3 Oct")
        #expect(RestoreOfferCopy.backups == "Have a copy from before? Backups, Restore")
        #expect(RestoreOfferCopy.notNow == "Not now")
        #expect(RestoreOfferCopy.replace == "Replace what is here")
        #expect(RestoreOfferCopy.confirm(stamp).hasPrefix("Restore the "))
        #expect(RestoreOfferCopy.confirm(stamp).hasSuffix(" backup? This replaces what is on this phone now"))
        #expect(RestoreOfferCopy.waits(for: "Push A") == "Restore waits until Push A is done")
        for line in [RestoreOfferCopy.offer(stamp), RestoreOfferCopy.inIt, RestoreOfferCopy.notInIt,
                     RestoreOfferCopy.walled, RestoreOfferCopy.staged]
        {
            #expect(!line.contains("\u{2014}"))
        }
    }

    @Test func restoredNoteCarriesTheCopysDateOnce() {
        defer { reset() }
        let stamp = Date(timeIntervalSince1970: 1_790_000_000)
        RestoreOffer.rememberStaged(stamp)
        let core = "Restored from your backup. What was here before is kept in Backups, so you can restore it again"
        let dated = RestoreOffer.dated(core)
        #expect(dated == RestoreOfferCopy.restored(stamp)
            + ". What was here before is kept in Backups, so you can restore it again")
        // Used once: a later note reads as Core wrote it.
        #expect(RestoreOffer.dated("Restored from your backup") == "Restored from your backup")
        // Other notes are never touched.
        RestoreOffer.rememberStaged(stamp)
        #expect(RestoreOffer.dated("Not saving this time") == "Not saving this time")
    }

    // MARK: The launch note queue

    @Test func twoLaunchNotesBothShowOnceOldestFirst() {
        var queue = LaunchNoteQueue(["Restored the 3 Oct backup", nil, "Couldn't open your data", ""])
        #expect(queue.current == "Restored the 3 Oct backup")
        queue.advance()
        #expect(queue.current == "Couldn't open your data")
        queue.advance()
        #expect(queue.current == nil)
        queue.advance()
        #expect(queue.current == nil)
    }

    @Test func aNoteAlreadyWaitingIsNotQueuedTwice() {
        var queue = LaunchNoteQueue(["Not saving this time"])
        queue.enqueue("Not saving this time")
        queue.enqueue("Sunday, rest day")
        #expect(queue.notes == ["Not saving this time", "Sunday, rest day"])
    }

    @Test func nowShowsOneQuietLineInOrder() {
        #expect(NowQuietLine.pick([.signingLapse, .restoreOffer, .keyQuestion]) == .keyQuestion)
        #expect(NowQuietLine.pick([.signingLapse, .restoreOffer]) == .restoreOffer)
        #expect(NowQuietLine.pick([.signingLapse]) == .signingLapse)
        #expect(NowQuietLine.pick([]) == nil)
    }

    // MARK: The signing lapse

    @Test func lapseShowsOnlyInTheLastTwoDays() throws {
        let expiry = try date("2026-10-26T13:36:00Z") // Mon Oct 26, 6:36 AM PT
        let threeDays = expiry.addingTimeInterval(-3 * 86400)
        let thirtyHours = expiry.addingTimeInterval(-30 * 3600)
        let twoHours = expiry.addingTimeInterval(-2 * 3600)
        #expect(SigningLapse.warning(expiry: expiry, now: threeDays, calendar: pacific) == nil)
        #expect(SigningLapse.warning(expiry: expiry, now: thirtyHours, calendar: pacific)
            == "This build stops opening tomorrow at 6:36 AM. Your data stays on this iPhone")
        #expect(SigningLapse.warning(expiry: expiry, now: twoHours, calendar: pacific)
            == "This build stops opening today at 6:36 AM. Your data stays on this iPhone")
        #expect(SigningLapse.warning(expiry: expiry, now: expiry.addingTimeInterval(60), calendar: pacific) == nil)
        #expect(SigningLapse.warning(expiry: nil, now: twoHours) == nil)
        // 47 hours before reads the weekday.
        #expect(SigningLapse.warning(expiry: expiry, now: expiry.addingTimeInterval(-47 * 3600), calendar: pacific)
            == "This build stops opening Monday at 6:36 AM. Your data stays on this iPhone")
    }

    @Test func profileExpiryIsReadFromTheSignedEnvelope() throws {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict><key>ExpirationDate</key><date>2026-10-26T13:36:00Z</date>
        <key>Name</key><string>iOS Team Provisioning Profile</string></dict></plist>
        """
        var data = Data([0x30, 0x82, 0x01, 0x00, 0x06, 0x09])
        data.append(Data(plist.utf8))
        data.append(Data([0xA0, 0x82, 0x00, 0x10]))
        #expect(try SigningLapse.expiry(fromProfile: data) == date("2026-10-26T13:36:00Z"))
        #expect(SigningLapse.expiry(fromProfile: Data([0x30, 0x82])) == nil)
    }

    @Test func simulatorFlagSetsTheLapseFromNow() throws {
        let now = try date("2026-10-19T21:17:00Z")
        #expect(SigningLapse.expiry(now: now, lapseDays: 1) == now.addingTimeInterval(86400))
        #expect(LaunchFlags.value(after: "-signingLapseDays", in: ["app", "-signingLapseDays", "1"])
            .flatMap(Double.init) == (LaunchFlags.allowed ? 1 : nil))
    }
}

/// QA on #1157: a fast double tap on Restore must not pass "Replace what is here".
struct RestoreTwoStepTests {
    final class Clock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 1_790_000_000)
    }

    @Test func aSecondTapAtPointTwoSecondsIsIgnoredAndAtPointFiveGoesThrough() {
        let clock = Clock()
        var step = RestoreTwoStep { clock.now }
        #expect(!step.accepts())
        step.arm()
        clock.now += 0.2
        #expect(!step.accepts())
        clock.now += 0.3
        #expect(step.accepts())
        step.reset()
        #expect(!step.accepts() && !step.isArmed)
    }
}
