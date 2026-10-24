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
}
