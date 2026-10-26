import CoreGraphics
import SwiftUI
@testable import Tessera
import Testing

/// AX5: the foot's verb and object keep their own lines, and the door summary's rows grow with the type so a label
/// is never squeezed into "...".
@MainActor
struct FootAndSummaryFitTests {
    @Test func footStacksUpwardWhenTheTypeOutgrowsTheSlot() {
        // Default: 32 + 18 fits the 64 pt slot from its top, as before.
        #expect(LandingActionWord.alignment(verb: 32, object: 18) == .topLeading)
        // AX sizes: the verb and object grow past the slot and stack up from its bottom (never over each other).
        #expect(LandingActionWord.alignment(verb: 60, object: 34) == .bottomLeading)
    }

    @Test func summaryRowsNeverOverlapAtAnySize() {
        let door = DialDoor(id: "tonight", name: "Tonight", color: .brown, label: "Nothing planned yet tonight",
                            lines: ["Tacos", "Rice bowl", "Soup"])
        for (label, line) in [(CGFloat(20), CGFloat(24)), (34, 41), (48, 58)] {
            let rows = DoorSummary.rows(door, label: label, line: line)
            #expect(rows.count == 4)
            for (above, below) in zip(rows, rows.dropFirst()) {
                let height = above.isLabel ? label : line
                #expect(below.y >= above.y + height, "rows overlap at \(label)/\(line)")
            }
        }
        // The default stays the 20/24 grid.
        #expect(DoorSummary.rows(door).map(\.y) == [0, 20, 44, 68])
    }

    @Test func labelCutsNeverEndInAnEllipsis() {
        for label in ["Nothing planned yet", "Rest today", "12 exercises in 4 kinds", "Not set up yet"] {
            for form in FitLine.cuts(label) {
                #expect(!form.hasSuffix("..."))
                #expect(!form.hasSuffix("…"))
                #expect(!form.isEmpty)
            }
        }
    }
}
