import Foundation
@testable import Tessera
import Testing

/// Restore-walk 7: the confirm names the copy's own 4 AM day, as its file name does.
struct BackupCopyTests {
    @Test func aCopyMadeAfterMidnightIsTheDayBefore() throws {
        let calendar = Calendar.current
        let late = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 15,
            hour: 1,
            minute: 30
        )))
        let evening = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: 20)))
        #expect(BackupCopy.fileDay(late) == BackupCopy.day(evening))
    }

    @Test func theLocalLineSaysTheRealCount() {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        #expect(BackupCopy
            .local(now, kept: 3, now: now) == "A copy is made every day, the last one today, and 3 are kept")
        #expect(BackupCopy
            .local(now, kept: 1, now: now) == "A copy is made every day, the last one today, and 1 is kept")
        #expect(BackupCopy.local(now, kept: 7, now: now).hasSuffix("and 7 are kept"))
        #expect(BackupCopy.local(nil, kept: 0, now: now) == "The first copy is made when you leave the app today")
    }
}
