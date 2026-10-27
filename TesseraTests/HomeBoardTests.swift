import Foundation
import SwiftUI
@testable import Tessera
import Testing

@MainActor
struct HomeBoardTests {
    private func line(_ text: String) -> BoardLine {
        BoardLine(segments: [DepartureSegment(text: text, kind: .plain)], target: .today)
    }

    @Test func aLineFitsItsRowAtTwentyFourLetters() {
        #expect(HomeBoard.fits(line("Push day at 6:30 pm")))
        #expect(!HomeBoard.fits(line("Free 2 hr 19 min, then Stretch & mobility")))
    }

    @Test func aLongLineIsCutAtAWordEdgeAndKeepsAWord() {
        let cut = HomeBoard.cut(line("Free 2 hr 19 min, then Stretch and mobility"))
        #expect(HomeBoard.fits(cut))
        #expect(cut.segments.map(\.text).joined(separator: " ").hasPrefix("Free"))
        #expect(HomeBoard.cut(line("Supercalifragilisticexpialidocious")).segments.first?.text.isEmpty == false)
    }

    @Test func theFirstDrawCutsForTheNarrowestBoardSoNothingClips() {
        let cut = HomeBoard.cut(line("Stretch & mobility at 12:05 pm"), width: HomeBoard.firstDrawWidth)
        #expect(HomeBoard.fits(cut, width: HomeBoard.firstDrawWidth))
    }

    @Test func aCutNeverEndsOnAStopWord() {
        let cut = HomeBoard.cut(line("Stretch and mobility at the climbing gym tonight"), width: 270)
        #expect(!HomeBoard.endsOnStopWord(cut.segments.map(\.text).joined(separator: " ")))
        #expect(TodayRoomView.forms(of: "Lunch with Sam")
            .allSatisfy { $0 == "Lunch with Sam" || !HomeBoard.endsOnStopWord($0) })
    }

    @Test func theBoardAlwaysHasThreeRowsAndTheRotationWraps() {
        let notices = [line("One"), line("Two"), line("Three")]
        let date = HomeBoard.date(now: Date())
        for rotation in 0 ..< 5 {
            let board = HomeBoard.lines(date: date, notices: notices, rotation: rotation, moment: nil)
            #expect(board.count == 3)
            #expect(board[1] == notices[rotation % 3] && board[2] == notices[(rotation + 1) % 3])
        }
        #expect(HomeBoard.lines(date: date, notices: [], rotation: 0, moment: nil).count == 3)
    }

    /// The page caps type at AX1, so the one-thing cut at AX1 and AX3 is the same, and a larger size never cuts less.
    @Test func oneThingCutStopsGrowingAtAX1() {
        let line = "Bench best 205 lb, 3 weeks ago with a long tail"
        let ax1 = HomeOneThing.cut(line, width: 262, typeSize: .accessibility1)
        #expect(HomeOneThing.cut(line, width: 262, typeSize: .accessibility3) == ax1)
        #expect(HomeOneThing.cut(line, width: 262, typeSize: .accessibility5) == ax1)
        let large = HomeOneThing.cut(line, width: 262, typeSize: .large)
        #expect(large.count >= ax1.count)
    }

    /// No overlap: the Big word's line always fits its 64 pt slot, at every text size.
    @Test func bigWordFitsItsSlotAtEverySize() {
        let sizes: [DynamicTypeSize] = [.xSmall, .large, .xxxLarge, .accessibility1, .accessibility3, .accessibility5]
        for typeSize in sizes {
            let size = HomeOneThing.bigSize(typeSize)
            #expect(HomeOneThing.bigLineHeight(size) <= HomeOneThing.bigSlot)
            #expect(size >= 30)
        }
    }

    /// Kaushik, Oct 26: no full stop on a shown line, and the board must not get one to flip.
    @Test func boardSegmentsCarryNoFullStop() {
        let segments = [DepartureSegment(text: "Pasta", kind: .plain), DepartureSegment(text: "tonight.", kind: .plain),
                        DepartureSegment(text: "Dr. Lin at 2.5 km.", kind: .plain)]
        let shown = HomeBoard.unstopped(segments).map(\.text)
        #expect(shown == ["Pasta", "tonight", "Dr. Lin at 2.5 km"])
    }
}
