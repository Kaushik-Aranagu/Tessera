import Foundation
@testable import Tessera
import Testing

/// Design 72, round 2 (title-accent.md).
struct TitleAccentTests {
    @Test func theWordThatMattersIsTheMomentAfterTheComma() {
        let title = "Push Day A, bench set 2"
        #expect(TitleAccent.keyWord(in: title).map { String(title[$0]) } == "bench set 2")
        #expect(TitleAccent.keyWord(in: "Push Day A done") == nil)
        #expect(TitleAccent.keyWord(in: "Tacos,") == nil)
    }

    @Test func aMaskedTitleLeadsWithWorkoutNotPrivate() {
        let title = "Private workout"
        #expect(TitleAccent.keyWord(in: title).map { String(title[$0]) } == "workout")
        let done = "Private workout, done"
        #expect(TitleAccent.keyWord(in: done).map { String(done[$0]) } == "done")
        #expect(TitleAccent.keyWord(in: "Private ") == nil)
        for label in ["Private recipe", "Private item", "Private list", "Private note"] {
            #expect(TitleAccent.keyWord(in: label).map { String(label[$0]) } == String(label.dropFirst(8)))
        }
    }

    @Test func progressHoldsUnderTheCapUntilDone() {
        #expect(TitleAccent(progress: 0.5).shownProgress == 0.5)
        #expect(TitleAccent(progress: 0.95).shownProgress == TitleAccent.progressCap)
        #expect(TitleAccent(progress: 0.4, isDone: true).shownProgress == 1)
        #expect(TitleAccent(progress: -1).shownProgress == 0)
    }
}
