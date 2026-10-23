import Foundation
@testable import Tessera
import Testing

/// Sheet 210: the lintel's ridge.
struct TrainingLintelTests {
    @Test func theRidgeIsTwelveWeeksSmoothSteppedAcrossTheWidthAndTheBestIsHighest() throws {
        let bests: [Double?] = [100, 102, nil, 110, 108, 115, 120, 118, 125, 130, 128, 140]
        let tops = LintelRidge.tops(bests, columns: 100)
        #expect(tops.count == 100)
        #expect(try #require(tops.last) < tops.first!, "a rising lift ends higher (a smaller row)")
        #expect(tops.min() == tops.last)
        // Smooth: neighbouring columns differ by at most a row or two, never a bar's step.
        #expect(zip(tops, tops.dropFirst()).allSatisfy { abs($0 - $1) <= 2 })
        #expect(tops.allSatisfy { $0 >= 2 && $0 <= LintelRidge.rows - 3 })
    }

    @Test func aWeekWithNoSetHoldsTheLastLevelAndNoHistoryIsALevelLine() {
        #expect(LintelRidge.filled([nil, 100, nil, 120, nil]) == [100, 100, 100, 120, 120])
        let flat = LintelRidge.tops(Array(repeating: nil, count: 12), columns: 50)
        #expect(Set(flat).count == 1)
    }

    @Test func theTopRowIsFullAccentAndTheFillFadesInWholeSteps() {
        #expect(LintelRidge.towardPage(row: 20, top: 20) == 0)
        let first = LintelRidge.towardPage(row: 21, top: 20)
        #expect(first >= 0.41 && first <= 0.5)
        let deeper = LintelRidge.towardPage(row: 40, top: 20)
        #expect(deeper > first && deeper <= 1)
        for row in 21 ... 43 {
            let value = LintelRidge.towardPage(row: row, top: 20) * 12
            #expect(abs(value - value.rounded()) < 1e-9, "whole 1/12 steps, never an alpha ramp")
        }
    }

    @Test func theBottomNineRowsBlendIntoThePageInBayerSteps() {
        let rows = LintelRidge.rows
        #expect((0 ..< 40).allSatisfy { LintelRidge.keepsEdgeTile(column: $0, row: 10) })
        func kept(_ row: Int) -> Int {
            (0 ..< 64).filter { LintelRidge.keepsEdgeTile(column: $0, row: row) }.count
        }
        #expect(kept(rows - 9) > kept(rows - 5) && kept(rows - 5) > kept(rows - 1))
        #expect(kept(rows - 1) < 64)
    }

    @Test func columnsFlipFromTheLeftNineMillisecondsApartInTwoHundredSixtyMilliseconds() {
        #expect(LintelRidge.flip(column: 0, time: 0).scale == 1)
        let mid = LintelRidge.flip(column: 0, time: 0.13)
        #expect(mid.scale < 0.01 && mid.isNew)
        #expect(!LintelRidge.flip(column: 50, time: 0.13).isNew)
        #expect(LintelRidge.flip(column: 10, time: 1).isNew && LintelRidge.flip(column: 10, time: 1).scale == 1)
        #expect(abs(LintelRidge.totalSeconds(columns: 100) - (0.9 + 0.26)) < 1e-9)
    }

    @Test func theBestWeeksGlintFallsOnItsOwnColumns() {
        let last = LintelRidge.weekColumns(11, columns: 100)
        let first = LintelRidge.weekColumns(0, columns: 100)
        #expect(last.upperBound == 100 && first.lowerBound == 0)
        #expect(last.count >= 5 && last.count <= 12)
    }
}
