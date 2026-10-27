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

    @Test func tilesLaunchSixMillisecondsApartAndFlyForFourHundredTwentyMilliseconds() {
        let value = lend()
        #expect(abs(value.launch(1) - value.launch(0) - 0.006) < 1e-9)
        #expect(value.progress(0, at: 10) == 0 && value.progress(0, at: 10.42) == 1)
        #expect(abs(value.landedAt - (10 + Double(value.tiles.count - 1) * 0.006 + 0.42)) < 1e-9)
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

@MainActor
struct MosaicSignEngineTests {
    private func engine(reduceMotion: Bool = false) -> MosaicScreenEngine {
        let size = CGSize(width: 402, height: 874)
        let engine = MosaicScreenEngine(size: size, coreTop: 480)
        engine.reduceMotion = reduceMotion
        engine.configure(size: size, coreTop: 480, dark: false, ground: (1, 1, 1))
        engine.snapWindow()
        return engine
    }

    private func request(_ kind: ThingSignKind) -> MosaicSignRequest {
        MosaicSignRequest(kind: kind, column: 70, row: 100, accent: (0.75, 0.27, 0.17))
    }

    @Test func aRequestLendsTilesAndTheirSourcesBecomeGaps() throws {
        let engine = engine()
        engine.step(to: 1)
        engine.showSign(request(.training))
        let lend = try #require(engine.signLend)
        #expect(lend.tiles.count == ThingSignArt.cells(.training, elapsed: 0, still: true).count)
        engine.step(to: 1.2)
        let source = try #require(lend.tiles.first)
        let gap = engine.signGap(at: engine.grid.index(column: source.sourceColumn, row: source.sourceRow))
        #expect(gap != nil && gap! > 0.5)
        #expect(engine.signIsMoving)
    }

    @Test func aNewSignCollapsesTheOldOneAndFeedsTheNextAfterOneHundredFortyMilliseconds() throws {
        let engine = engine()
        engine.step(to: 1)
        engine.showSign(request(.training))
        engine.step(to: 4)
        engine.showSign(request(.groceries))
        #expect(engine.signOld?.start == engine.clock)
        #expect(try #require(engine.signLend).start == engine.clock + 0.14)
        #expect(!engine.collapsingSign().isEmpty)
        engine.step(to: 5)
        #expect(engine.collapsingSign().isEmpty)
    }

    @Test func underReduceMotionTheSignIsSimplyThere() throws {
        let engine = engine(reduceMotion: true)
        engine.showSign(request(.weather))
        let lend = try #require(engine.signLend)
        #expect(engine.clock >= lend.landedAt)
        #expect(engine.signOld == nil && !engine.signIsMoving)
    }
}
