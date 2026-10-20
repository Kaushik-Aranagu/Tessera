import Foundation
@testable import Tessera
import Testing

/// Sheet 99: the "Reading layout" switch and its size lookup.
@MainActor
struct ReadingLayoutTests {
    private func suite(_ name: String) throws -> UserDefaults {
        let suite = try #require(UserDefaults(suiteName: name))
        suite.removePersistentDomain(forName: name)
        return suite
    }

    @Test func theDefaultIsToday() throws {
        let defaults = try suite("ReadingLayoutDefault")
        #expect(ReadingLayout.current(defaults: defaults) == .today)
        #expect(ReviewChoices.all.first { $0.id == "readingLayout" }?.defaultValue == "Today")
        #expect(ReviewChoices.all.first { $0.id == "readingLayout" }?.readiness == .live)
    }

    @Test func anUnknownValueFallsBackToToday() throws {
        let defaults = try suite("ReadingLayoutUnknown")
        defaults.set("Sheet 100", forKey: "review.readingLayout")
        #expect(ReadingLayout.current(defaults: defaults) == .today)
        defaults.set("Sheet 99", forKey: "review.readingLayout")
        #expect(ReadingLayout.current(defaults: defaults) == .sheet99)
    }

    @Test func todayKeepsTodaysSizes() {
        let today: [ReadingSlot: CGFloat] = [
            .pageHead: 56, .aisleHead: 44, .shopAisle: 56, .contextLine: 21, .detailLine: 18, .queueHead: 34,
            .queueDetail: 18, .restoreHead: 44, .exerciseName: 56, .todayNumber: 44, .rowNumeral: 24,
            .historyNumber: 21, .historyDate: 18, .note: 18,
        ]
        for slot in ReadingSlot.allCases {
            #expect(ReadingSlot.size(slot, in: .today) == today[slot])
        }
    }

    @Test func sheet99UsesOnlyItsSizes() {
        #expect(ReadingSlot.size(.aisleHead, in: .sheet99) == 16)
        #expect(ReadingSlot.size(.queueHead, in: .sheet99) == 16)
        #expect(ReadingSlot.size(.pageHead, in: .sheet99) == 44)
        #expect(ReadingSlot.size(.todayNumber, in: .sheet99) == 56)
        #expect(ReadingSlot.size(.rowNumeral, in: .sheet99) == 28)
        for slot in ReadingSlot.allCases {
            #expect(ReadingSlot.sanctioned.contains(ReadingSlot.size(slot, in: .sheet99)))
        }
    }
}
