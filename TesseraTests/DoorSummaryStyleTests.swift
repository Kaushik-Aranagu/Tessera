import SwiftUI
@testable import Tessera
import Testing

/// Sheet 283 v6: each room's door summary change stays under 1 s, and Deck's chalk rows run 0.3 s, 0.15 s apart.
@MainActor
struct DoorSummaryStyleTests {
    @Test func everyChangeIsUnderOneSecond() {
        for style in [DoorSummaryStyle.rise, .chalk, .fog, .grow] {
            #expect(style.duration(rows: 4) < 1)
        }
    }

    @Test func chalkRowsAreStaggered() {
        let count = 3
        let total = DoorSummaryStyle.chalk.duration(rows: count)
        #expect(abs(total - 0.6) < 0.001)
        let first = ChalkWindow(index: 0, count: count)
        let last = ChalkWindow(index: 2, count: count)
        // Half way through, the first row is done and the last has not started.
        #expect(first.local(0.5) == 1)
        #expect(last.local(0.5) == 0)
        #expect(last.local(1) == 1)
    }

    @Test func deckWritesInBarlowAndOthersInFigtree() {
        #expect(DoorSummaryStyle.chalk.family == "BarlowCondensed-SemiBold")
        #expect(DoorSummaryStyle.fog.family == "Figtree")
        #expect(DoorSummaryStyle.grow.family == "Figtree")
    }

    @Test func rowsKeepTheirPlaces() {
        let door = DialDoor(id: "week", name: "This week", color: .blue, label: "Mon to Sun",
                            lines: ["Push A", "Pull A", "Legs", "Extra"])
        let rows = DoorSummary.rows(door)
        #expect(rows.count == 4)
        #expect(rows.map(\.y) == [0, 20, 44, 68])
        #expect(rows.allSatisfy { $0.id.hasPrefix("week#") })
    }
}
