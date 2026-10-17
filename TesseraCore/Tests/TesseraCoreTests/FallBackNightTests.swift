import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Research dst-nov-1 (board 0ag): the fall-back night, Sun Nov 1 2026, when 1:00 to 1:59 am happens twice in
/// Los Angeles. Fixed zone everywhere, never `.current`.
@MainActor
struct FallBackNightTests {
    private var la: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    private func utc(_ text: String) -> Date {
        try! Date(text, strategy: .iso8601) // swiftlint:disable:this force_try
    }

    @Test(arguments: [
        (["bins", "1:30am"], "2026-11-01T08:45:00Z"),
        (["bins", "1:30am"], "2026-11-01T09:10:00Z"),
        (["bins", "sun", "1:30am"], "2026-11-01T09:10:00Z"),
    ])
    func oneThirtyInTheRepeatedHourIsTheSecondPass(words: [String], now: String) {
        // DS8: the 1:30 am still ahead, 1:30 am PST, not a day or a week late.
        let (date, _) = TessDates.extract(from: words, now: utc(now), calendar: la)
        #expect(date == utc("2026-11-01T09:30:00Z"), "\(words) at \(now)")
    }

    @Test func sunOneThirtyBeforeIsFirstPass() {
        // DS7, a control: said Saturday 11 pm, it's the first 1:30.
        let (date, _) = TessDates.extract(from: ["bins", "sun", "1:30am"], now: utc("2026-11-01T06:00:00Z"),
                                          calendar: la)
        #expect(date == utc("2026-11-01T08:30:00Z"))
    }

    @Test func anOrdinaryNightHasOnePass() {
        #expect(TessDates.laterPass(hour: 1, minute: 30, of: utc("2026-10-24T07:00:00Z"),
                                    after: utc("2026-10-25T08:45:00Z"), calendar: la) == nil)
    }

    @Test func datedLiftSundayIsNoon() throws {
        // DS29: "bench 80x8 sun" said Mon Nov 2 asks about Sunday at noon PST, not 11 am.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let grammar = TessGrammar(store: store, classes: classes)
        let parse = grammar.parse(
            "bench 80x8 sun",
            context: TessContext(now: utc("2026-11-02T20:00:00Z"), calendar: la)
        )
        guard case let .askDatedLift(ask)? = parse else {
            Issue.record("not a dated lift ask: \(String(describing: parse))")
            return
        }
        #expect(ask.day == utc("2026-11-01T20:00:00Z"))
    }
}
