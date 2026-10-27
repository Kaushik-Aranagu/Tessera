import CoreGraphics
import Foundation
import SwiftUI
@testable import Tessera
import Testing

/// Design sheets 288 and 291: no text crosses another element's frame, in any look or Dynamic Type size. Every Deck
/// door page (Today, This week, Library, Bests, Plan) keeps its rows above the action word at every screen height the
/// shell scales to and at default, large and accessibility sizes.
@MainActor
struct DeckPageOverlapTests {
    private static let sizes: [DynamicTypeSize] = [
        .xSmall, .large, .xxxLarge, .accessibility1, .accessibility2, .accessibility3, .accessibility5,
    ]
    private static let scales: [CGFloat] = [0.86, 0.93, 1, 1.1]
    nonisolated static let doors = ["today", "week", "library", "bests", "plan"]

    @Test(arguments: doors) func pageStaysAboveTheActionWord(door: String) {
        let content = DeckRoomContent(facts: DeckRoomContentTests.facts())
        let screen = content.screen(for: .door("deck", door), state: RoomState())
        #expect(screen[.page] != nil, "\(door) has a page")
        #expect(screen[.actionWord] != nil, "\(door) has an action word")
        for size in Self.sizes {
            for scale in Self.scales {
                let page = ShellLayout.screenRect(.page, in: .door, scale: scale, typeSize: size)
                let word = ShellLayout.screenRect(.actionWord, in: .door, scale: scale, typeSize: size)
                #expect(!page.intersects(word), "\(door) page crosses the action word at \(size), scale \(scale)")
                #expect(page.maxY + ShellLayout.pageFootGap <= word.minY + 0.001)
                #expect(word.maxY <= 874 * scale + 0.001, "the word stays on screen")
                #expect(page.height > 120, "the page keeps room for rows at \(size)")
            }
        }
    }

    @Test func theLandingWordStillSitsAtItsDesignFrame() {
        let word = ShellLayout.screenRect(.actionWord, in: .landing, scale: 1, typeSize: .large)
        #expect(word == LandingPlace.Foot.actionWord)
    }
}
