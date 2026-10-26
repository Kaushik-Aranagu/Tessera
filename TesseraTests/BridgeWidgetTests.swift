import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Bridge per sheet 283 (QA, Oct 25): the one-thing box is the widget (header, a one-line Big line, Middle, Small, the
/// 80 pt sign), the dial wears the ship names with Lists folded into the Log, and no key word wears an underline.
@MainActor
struct BridgeWidgetTests {
    @Test func theWidgetSlotsMatchTheSheet() {
        #expect(HomeOneThing.height == 212)
        #expect(HomeOneThing.signTop == 44)
        #expect(HomeOneThing.signRoom == 92)
    }

    @Test func theHeaderIsTheRoomsShipName() {
        #expect(HomeOneThing.header(.training) == "Deck")
        #expect(HomeOneThing.header(.groceries) == "Galley")
        #expect(HomeOneThing.header(.list) == "Log")
        #expect(HomeOneThing.header(.weather) == "Lookout")
        #expect(HomeOneThing.header(.routine) == "Watch")
    }

    @Test func aLongBigLineCutsOnAWholeWordAndNeverEllipsizes() {
        let cut = HomeOneThing.cut("Call the plumber about the kitchen sink tomorrow", size: 38, width: 262)
        #expect(!cut.contains("...") && !cut.contains("…"))
        #expect("Call the plumber about the kitchen sink tomorrow".hasPrefix(cut))
        #expect(cut.count < 30)
        #expect(HomeOneThing.cut("Tacos", size: 38, width: 262) == "Tacos")
    }

    @Test func theMiddleLinesKeyWordHasNoUnderline() {
        let thing = HomeThing(id: "t", kind: .list, big: "2 left", bigIsNumber: false, accent: .app(.lists),
                              mid: "Packing", keyword: "Packing", small: "", taskID: nil,
                              target: .room(.lists), undoLine: nil)
        let text = HomeOneThing.midText(thing)
        #expect(text.runs.allSatisfy { $0.underlineStyle == nil })
    }

    @Test func theDialWearsShipNamesWithListsFoldedIntoTheLog() {
        let rows = AppsListRows.make([])
        #expect(!rows.contains { $0.app == .lists })
        let names = Set(rows.map(\.app.shipName))
        #expect(names.isSuperset(of: ["Deck", "Galley", "Purse", "Log", "Watch"]))
        #expect(!names.contains("Training") && !names.contains("Kitchen") && !names.contains("Money"))
    }
}
