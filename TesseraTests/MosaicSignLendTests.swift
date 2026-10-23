import Foundation
@testable import Tessera
import Testing

struct MosaicSignLendTests {
    private let core = (left: 0, top: 0, width: 50, height: 28)

    private func lend(_ kind: ThingSignKind = .training) -> MosaicSignLend {
        let cells = ThingSignArt.cells(kind, elapsed: 0)
        let tiles = MosaicSignLend.lend(cells: cells, originColumn: 70, originRow: 4, core: core)
        return MosaicSignLend(tiles: tiles, start: 10, kind: kind, share: 0.5)
    }

    @Test func oneDistinctMosaicTileIsLentForEverySignTile() {
        let value = lend()
        #expect(value.tiles.count == ThingSignArt.cells(.training, elapsed: 0).count)
        #expect(Set(value.tiles.map { [$0.sourceColumn, $0.sourceRow] }).count == value.tiles.count)
        #expect(value.tiles.allSatisfy { (0 ..< 50).contains($0.sourceColumn) && (0 ..< 28).contains($0.sourceRow) })
        #expect(value == lend(), "deterministic")
    }

    @Test func tilesLaunchSevenMillisecondsApartAndFlyForFiveHundredSixtyMilliseconds() {
        let value = lend()
        #expect(abs(value.launch(1) - value.launch(0) - 0.007) < 1e-9)
        #expect(value.progress(0, at: 10) == 0 && value.progress(0, at: 10.56) == 1)
        #expect(abs(value.landedAt - (10 + Double(value.tiles.count - 1) * 0.007 + 0.56)) < 1e-9)
    }

    @Test func theArcLiftsTwentySixPointsAndSwellsToOneAndAHalfMidFlight() {
        let mid = MosaicSignLend.arc(0.5)
        #expect(mid.lift == 26 && mid.scale == 1.5)
        #expect(MosaicSignLend.arc(0).lift == 0 && MosaicSignLend.arc(1).scale <= 1.0001)
    }

    @Test func aLentTileIsAGapAtOnceAndRefillsAfterFourHundredFiftyMilliseconds() {
        let value = lend()
        #expect(value.gap(sourceIndex: 0, tile: 0, at: 9.9) == 0)
        #expect(value.gap(sourceIndex: 0, tile: 0, at: 10) == 0.88)
        #expect(value.gap(sourceIndex: 0, tile: 0, at: 10.44) == 0.88)
        #expect(value.gap(sourceIndex: 0, tile: 0, at: 10 + 0.45 + 1.1) == 0)
    }

    @Test func anOldSignCollapsesFromTheEdgesInwardAndSinksFourPoints() {
        let edge = ThingSignCell(0, 5), inner = ThingSignCell(8, 8)
        #expect(MosaicSignLend.collapse(cell: edge, elapsed: 0).scale == 1)
        let early = 0.1
        #expect(MosaicSignLend.collapse(cell: edge, elapsed: early).scale
            < MosaicSignLend.collapse(cell: inner, elapsed: early).scale)
        let done = MosaicSignLend.collapse(cell: inner, elapsed: MosaicSignLend.collapseTotal)
        #expect(done.scale == 0 && done.sink == 4)
        #expect(MosaicSignLend.feedDelay == 0.14)
    }
}
