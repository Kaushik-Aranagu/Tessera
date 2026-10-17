import Foundation
@testable import Tessera
import Testing

/// Kitchen gap hunt G39: Claude receipts read the house clock, never "12:00 pm" or a 24-hour time.
@MainActor
struct ReceiptClockTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return calendar
    }

    private func at(_ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: hour, minute: minute)) ?? .now
    }

    @Test func onTheHourDropsTheMinutes() {
        #expect(ClaudeKeyWords.receiptTime(at(12, 0), calendar: calendar) == "Fri Oct 16, 12 pm")
        #expect(ClaudeKeyWords.receiptTime(at(9, 0), calendar: calendar) == "Fri Oct 16, 9 am")
    }

    @Test func minutesStayWhenTheyArentZero() {
        #expect(ClaudeKeyWords.receiptTime(at(19, 5), calendar: calendar) == "Fri Oct 16, 7:05 pm")
    }
}
