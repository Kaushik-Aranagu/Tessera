import Foundation
@testable import Tessera
import TesseraCore
import Testing

struct MosaicMomentHostTests {
    @Test func announcementTicksTimerIsRigidTheRestAreSoft() {
        #expect(MosaicMomentMapping.beat(.announcement) == .tick)
        #expect(MosaicMomentMapping.beat(.timer) == .rigid)
        #expect(MosaicMomentMapping.beat(.tess) == .soft)
        #expect(MosaicMomentMapping.beat(.weather(.snow)) == .soft)
        #expect(MosaicMomentMapping.beat(.finished) == .soft)
    }

    @Test func nightIsQuietAndTheDayIsNot() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let night = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 23)))
        let noon = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 12)))
        #expect(MosaicMomentMapping.isQuiet(night, calendar: calendar))
        #expect(!MosaicMomentMapping.isQuiet(noon, calendar: calendar))
    }
}
