import Foundation
import SwiftUI
@testable import Tessera
import TesseraCore
import Testing

/// Bridge per sheet 283 (QA, Oct 25): the one-thing box is the widget (header, a one-line Big line, Middle, Small, the
/// 80 pt sign), the dial wears the ship names with Lists folded into the Log, and no key word wears an underline.
@MainActor
struct BridgeWidgetTests {
    @Test func theWidgetSlotsMatchTheSheet() {
        #expect(HomeOneThing.height == LandingPlace.widget.frame.height)
        // The sign sits in its glyph place, 298, 444, 80 x 80.
        #expect(LandingPlace.widget.frame.minY + HomeOneThing.signTop == LandingPlace.Widget.glyph.minY)
        #expect(LandingPlace.widget.frame.maxX - 80 == LandingPlace.Widget.glyph.minX)
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
        let cut = HomeOneThing.cut("Call the plumber about the kitchen sink tomorrow", width: 262)
        #expect(!cut.contains("...") && !cut.contains("…"))
        #expect("Call the plumber about the kitchen sink tomorrow".hasPrefix(cut))
        #expect(cut.count < 30)
        #expect(HomeOneThing.cut("Tacos", width: 262) == "Tacos")
    }

    @Test func theMiddleLinesKeyWordHasNoUnderline() {
        let text = HomeOneThing.midText("Packing, 2 left", keyword: "Packing", accent: .green)
        #expect(text.runs.allSatisfy { $0.underlineStyle == nil })
    }

    @Test func theDialWearsShipNamesWithListsFoldedIntoTheLog() {
        let rows = AppsListRows.make([])
        #expect(!rows.contains { $0.app == .lists })
        let names = Set(rows.map(\.name))
        #expect(names.isSuperset(of: ["Deck", "Galley", "Purse", "Log", "Watch"]))
        #expect(!names.contains("Training") && !names.contains("Kitchen") && !names.contains("Money"))
        #expect(rows.map(\.name) == ["Log", "Lookout", "Deck", "Galley", "Watch", "Purse", "To do", "Settings"])
        #expect(rows.first { $0.name == "Lookout" }?.door == .lookout)
        #expect(rows.first { $0.name == "Settings" }?.door == .settings)
        #expect(rows.first { $0.name == "Galley" }?.door == .app(.kitchen))
    }
}
