import Foundation
@testable import Tessera
import Testing

@MainActor
struct HomeBoardTests {
    private func line(_ text: String) -> BoardLine {
        BoardLine(segments: [DepartureSegment(text: text, kind: .plain)], target: .today)
    }

    @Test func aLineFitsItsRowAtTwentyFourLetters() {
        #expect(HomeBoard.fits(line("Push day at 6:30 pm.")))
        #expect(!HomeBoard.fits(line("Free 2 hr 19 min, then Stretch & mobility.")))
    }

    @Test func aLongLineIsCutAtAWordEdgeAndKeepsAWord() {
        let cut = HomeBoard.cut(line("Free 2 hr 19 min, then Stretch and mobility."))
        #expect(HomeBoard.fits(cut))
        #expect(cut.segments.map(\.text).joined(separator: " ").hasPrefix("Free"))
        #expect(HomeBoard.cut(line("Supercalifragilisticexpialidocious")).segments.first?.text.isEmpty == false)
    }

    @Test func aCutNeverEndsOnAStopWord() {
        let cut = HomeBoard.cut(line("Stretch and mobility at the climbing gym tonight"), width: 270)
        #expect(!HomeBoard.endsOnStopWord(cut.segments.map(\.text).joined(separator: " ")))
        #expect(TodayRoomView.forms(of: "Lunch with Sam")
            .allSatisfy { $0 == "Lunch with Sam" || !HomeBoard.endsOnStopWord($0) })
    }

    @Test func theBoardAlwaysHasThreeRowsAndTheRotationWraps() {
        let notices = [line("One."), line("Two."), line("Three.")]
        let date = HomeBoard.date(now: Date())
        for rotation in 0 ..< 5 {
            let board = HomeBoard.lines(date: date, notices: notices, rotation: rotation, moment: nil)
            #expect(board.count == 3)
            #expect(board[1] == notices[rotation % 3] && board[2] == notices[(rotation + 1) % 3])
        }
        #expect(HomeBoard.lines(date: date, notices: [], rotation: 0, moment: nil).count == 3)
    }

    // MARK: Home 236 slots and fit

    @Test func theSlotsHoldTheBoardsOwnNumbersAtBothDesignedHeights() {
        let small = HomeSlots.make(screenHeight: 844)
        #expect(small.boardTop == 66 && small.mosaicTop == 188 && small.thingTop == 374 && small.thing == 204)
        #expect(small.appsTop == 602)
        let large = HomeSlots.make(screenHeight: 874)
        #expect(large.boardTop == 84 && large.mosaicTop == 210 && large.thingTop == 400 && large.thing == 212)
        #expect(large.appsTop == 640)
    }

    @Test func theOneThingIsClampedAndTheAppsLeaveRoomForTheFoot() {
        #expect(HomeSlots.make(screenHeight: 1000).thing <= 232)
        #expect(HomeSlots.make(screenHeight: 700).thing >= 196)
        for height in [CGFloat(844), 874, 932] {
            let slots = HomeSlots.make(screenHeight: height)
            #expect(slots.appsTop + HomeSlots.appsHeight <= height - 80)
        }
    }

    @Test func aLineIsCutAtWholeWordsAndNeverEndsOnAStopWord() {
        let fit = HomeFit.fit("Bench best 205 lb, 3 weeks ago with", family: "Figtree", weight: .medium, size: 15,
                              width: 120, floor: 15)
        #expect(!fit.text.contains("…") && !HomeBoard.endsOnStopWord(fit.text))
        #expect(HomeFit.width(fit.text, family: "Figtree", weight: .medium, size: 15) <= 120
            || !fit.text.contains(" "))
    }

    @Test func oneOverLongWordStaysWholeAndStepsDownToTheFloor() {
        let fit = HomeFit.fit("Supercalifragilisticexpialidocious", family: "Figtree", weight: .bold, size: 38,
                              width: 100)
        #expect(fit.text == "Supercalifragilisticexpialidocious" && fit.size == (38 * 0.75).rounded(.up))
    }
}
