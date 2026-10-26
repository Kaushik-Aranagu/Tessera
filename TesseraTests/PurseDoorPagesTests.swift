import Foundation
@testable import Tessera
import Testing

/// Purse's door pages are never empty: real rows where data exists, else one honest row; never a figure.
@MainActor
struct PurseDoorPagesTests {
    private static func series(_ name: String, values: [Double]) -> PurseSeries {
        PurseSeries(name: name, shape: .flow, solid: values, forecast: [], prior: [], floor: nil, daysInMonth: 31)
    }

    private static let categories = [
        PurseCategory(id: "month", name: "This month", indices: [series("you", values: [0, 10])]),
        PurseCategory(id: "kinds", name: "Kinds", indices: [series("lunch", values: [0, 4]),
                                                          series("coffee", values: [])]),
        PurseCategory(id: "saving", name: "Saving", indices: []),
        PurseCategory(id: "investing", name: "Investing", indices: []),
        PurseCategory(id: "debts", name: "Debts", indices: []),
        PurseCategory(id: "mine", name: "Mine", indices: []),
    ]

    @Test func everyDoorHasAtLeastOneRow() {
        let pages = PurseRoomContent.Facts.pages([:], categories: Self.categories)
        for category in Self.categories {
            #expect(!(pages[category.id] ?? []).isEmpty, "\(category.id) page is empty")
        }
        #expect(pages["saving"]?.first?.title == "Not set up yet")
        #expect(pages["kinds"]?.map(\.title) == ["Lunch", "Coffee"])
        #expect(pages["month"]?.first?.title == "Nothing logged yet")
    }

    @Test func pagesCarryNoFigures() {
        let pages = PurseRoomContent.Facts.pages([:], categories: Self.categories)
        for row in pages.values.flatMap(\.self) {
            #expect(!(row.title + row.detail).contains { $0.isNumber }, "\(row.title) \(row.detail)")
        }
    }

    @Test func doorLinesAreHonest() {
        let pages = PurseRoomContent.Facts.pages([:], categories: Self.categories)
        #expect(PurseRoomContent.doorLine(id: "saving", rows: pages["saving"] ?? [], isFirst: false)
            == "Not set up yet.")
        #expect(PurseRoomContent.doorLine(id: "month", rows: pages["month"] ?? [], isFirst: true)
            == "Nothing here yet.")
        #expect(PurseRoomContent.doorLine(id: "kinds", rows: pages["kinds"] ?? [], isFirst: false)
            == "2 indices, no figures here.")
    }

    @Test func aPageScreenIsNeverEmpty() {
        var facts = PurseRoomContent.Facts()
        facts.categories = Self.categories
        facts.doors = PurseRoomContent.Facts.doors(Self.categories)
        facts.rows = PurseRoomContent.Facts.pages([:], categories: Self.categories)
        let content = PurseRoomContent(facts: facts)
        for category in Self.categories {
            let screen = content.screen(for: .door(PurseRoomContent.room, category.id), state: RoomState())
            guard case let .list(rows) = screen[.page]?.payload else {
                Issue.record("no page for \(category.id)")
                continue
            }
            #expect(!rows.isEmpty)
        }
    }
}
