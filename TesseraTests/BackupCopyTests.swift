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
}
