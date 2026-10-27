import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Home is the mosaic (sheet 202, the skin edge): the grid, the rim, the mirror, the scatter, the seamless clone, the
/// shield and the flip.
@MainActor
struct MosaicScreenTests {
    private let size = CGSize(width: 402, height: 874)
    private var grid: MosaicScreenGrid {
        MosaicScreenGrid(size: size, coreTop: 480)
    }

    private func engine() -> MosaicScreenEngine {
        let engine = MosaicScreenEngine(size: size, coreTop: 480)
        engine.configure(size: size, coreTop: 480, dark: false, ground: (0.98, 0.98, 0.97))
        engine.snapWindow()
        return engine
    }

    @Test func theGridIsTheWholeScreenOnAFourPointStepWithThreePointTwoTiles() {
        #expect(grid.columns == 101 && grid.rows == 219)
        #expect(MosaicScreenGrid.step == 4 && MosaicScreenGrid.side == 3.2)
        let rect = grid.rect(column: 3, row: 5)
        #expect(abs(rect.width - 3.2) < 1e-9 && abs(rect.height - 3.2) < 1e-9)
        // The tile sits centred in its 4 pt cell.
        #expect(abs(rect.midX - 14) < 1e-9 && abs(rect.midY - 22) < 1e-9)
        #expect(grid.tile(at: CGPoint(x: 14, y: 22)) == (3, 5))
    }

    @Test func theCoreGrowsLeftFromTheRightMarginWithItsTopOnTheOldBlocksTop() {
        let core = grid.core(columns: 50, rows: 28)
        #expect(core.width == 50 && core.height == 28)
        #expect(core.top == 120)
        #expect(core.right == grid.columns - 1 - MosaicScreenGrid.gutterTiles)
        // A wider face grows left and keeps the same right edge.
        #expect(grid.core(columns: 88, rows: 28).right == core.right)
        #expect(grid.core(columns: 72, rows: 28).left > grid.core(columns: 88, rows: 28).left)
    }

    @Test func theCornersAreASuperellipseBetweenASquareAndACircle() {
        #expect(MosaicRim.cornerRadius(columns: 50, rows: 28) == 6)
        #expect(MosaicRim.cornerRadius(columns: 50, rows: 8) == 4)
        #expect(MosaicRim.cornerRadius(columns: 6, rows: 28) == 3)
        let core = grid.core(columns: 50, rows: 28)
        // Straight edge: the last tile inside is half a tile in, the first outside half a tile out.
        let middle = core.top + 14
        #expect(abs(MosaicRim.signedDistance(column: core.left, row: middle, core: core) - -0.5) < 1e-9)
        #expect(abs(MosaicRim.signedDistance(column: core.left - 1, row: middle, core: core) - 0.5) < 1e-9)
        // The corner tile is cut: outside the shape, though inside the rectangle. A square would keep it, a circle
        // would
        // cut it further.
        let corner = MosaicRim.signedDistance(column: core.left, row: core.top, core: core)
        #expect(corner > 0)
        let qx = 5.5, radius = 6.0
        let square = qx - radius, circle = (2 * qx * qx).squareRoot() - radius
        #expect(corner > square && corner < circle)
        // Deep inside it keeps going negative (the ramp starts 8 tiles in), down to the depth at the middle.
        #expect(MosaicRim.signedDistance(column: core.left + 25, row: middle, core: core) < -8)
        #expect(MosaicRim.signedDistance(column: core.left + 8, row: middle, core: core) < -8)
        #expect(abs(MosaicRim.signedDistance(column: core.left + 3, row: middle, core: core) - -3.5) < 1e-9)
    }

    @Test func theRampStartsEightTilesInsideAndRunsSixteenOutInTwentyFourths() {
        #expect(MosaicRim.reach == 16 && MosaicRim.inner == 8 && MosaicRim.steps == 24)
        for column in 0 ..< 4 {
            for row in 0 ..< 4 {
                // 8 tiles inside (sd = -8) the scene is whole; 16 out nothing is left.
                #expect(MosaicRim.level(signedDistance: -8, column: column, row: row) == 1)
                #expect(MosaicRim.level(signedDistance: -20, column: column, row: row) == 1)
                #expect(MosaicRim.level(signedDistance: 16, column: column, row: row) == 0)
                #expect(MosaicRim.level(signedDistance: 20, column: column, row: row) == 0)
                // The ramp straddles the edge: at the edge itself it is partway.
                let atEdge = MosaicRim.level(signedDistance: 0, column: column, row: row)
                #expect(atEdge > 0.5 && atEdge < 1)
                // Whole 24ths, never in between.
                for sd in stride(from: -8.0, through: 16, by: 0.5) {
                    let level = MosaicRim.level(signedDistance: sd, column: column, row: row)
                    #expect(abs(level * 24 - (level * 24).rounded()) < 1e-9)
                }
            }
        }
        // Falling as it goes out, and the same every time.
        var last = 1.0
        for sd in stride(from: -8.0, through: 16, by: 0.5) {
            let level = MosaicRim.level(signedDistance: sd, column: 5, row: 9)
            #expect(level <= last)
            last = level
        }
        #expect(MosaicRim.level(signedDistance: 6, column: 5, row: 9) == MosaicRim.level(
            signedDistance: 6,
            column: 5,
            row: 9
        ))
        var thresholds: Set<Double> = []
        for row in 0 ..< 4 {
            for column in 0 ..< 4 {
                thresholds.insert(MosaicRim.threshold(column: column, row: row))
            }
        }
        #expect(thresholds.count == 16 && (thresholds.min() ?? -1) > 0 && (thresholds.max() ?? 2) < 1)
        #expect(MosaicRim.smootherstep(0) == 0 && MosaicRim.smootherstep(1) == 1)
        #expect(abs(MosaicRim.smootherstep(0.5) - 0.5) < 1e-9)
    }

    @Test func rimTilesReadTheSceneMirroredAcrossTheEdgeNeverClamped() {
        #expect(MosaicRim.mirror(-1, count: 50) == 0)
        #expect(MosaicRim.mirror(-2, count: 50) == 1)
        #expect(MosaicRim.mirror(-12, count: 50) == 11)
        #expect(MosaicRim.mirror(50, count: 50) == 49)
        #expect(MosaicRim.mirror(51, count: 50) == 48)
        #expect(Set([-1, -2, -3].map { MosaicRim.mirror($0, count: 50) }).count == 3)
        #expect((0 ..< 6).contains(MosaicRim.mirror(-9, count: 6)))
        let engine = engine()
        let core = engine.core
        let mirror = engine.mirrored(column: core.left - 3, row: core.top + 5, core: core)
        #expect(mirror.column == core.left + 2 && mirror.row == core.top + 5)
    }

    @Test func aRimTileClimbsFromThePagesColourToTheScenesInWholeSolidTiles() throws {
        let engine = engine()
        engine.ground = (1, 1, 1)
        engine.settle { _, _ in (1, 0, 0) }
        engine.step(to: 0.01)
        let core = engine.liveCore
        let row = core.top + 14
        // A flat red scene on a white page: green is 1 - level, so it can only be a whole eighth.
        var greens: [Double] = []
        var drawn = 0
        for distance in 1 ... 16 {
            guard let tile = engine.tile(column: core.left - distance, row: row, nowColumn: nil) else { continue }
            drawn += 1
            #expect(tile.scale >= 1)
            #expect(abs(tile.colour.green * 24 - (tile.colour.green * 24).rounded()) < 1e-6)
            greens.append(tile.colour.green)
        }
        #expect(drawn >= 8)
        // Window tiles are the scene itself; the rim's first tile is nearly that, the last nearly the page.
        let inside = try #require(engine.tile(column: core.left + 10, row: row, nowColumn: nil))
        #expect(inside.colour.green == 0)
        #expect((greens.first ?? 1) < 0.3)
        #expect((greens.last ?? 0) > 0.6)
        #expect(engine.tile(column: core.left - 17, row: row, nowColumn: nil) == nil)
        // The corner is cut: the window's corner tile is rim, so it is drawn at a level of its own.
        let corner = engine.tile(column: core.left, row: core.top, nowColumn: nil)
        #expect(corner == nil || (corner?.colour.green ?? 0) > 0)
    }

    @Test func anAnnouncementsRimSamplesTheBackgroundNeverTheWords() throws {
        let engine = engine()
        engine.settle { _, _ in (0.2, 0.2, 0.9) }
        engine.overlay = { _, _, _, _ in (0, 0, 0) }
        engine.rimSamplesLight = false
        engine.step(to: 0.01)
        let core = engine.liveCore
        let row = core.top + 14
        let inside = try #require(engine.tile(column: core.left + 10, row: row, nowColumn: nil))
        #expect(inside.colour.blue == 0)
        let rim = try #require(engine.tile(column: core.left - 1, row: row, nowColumn: nil))
        #expect(rim.colour.blue > 0.5)
        engine.rimSamplesLight = true
        let lit = try #require(engine.tile(column: core.left - 1, row: row, nowColumn: nil))
        #expect(lit.colour.blue < rim.colour.blue)
    }

    @Test func underReduceMotionTheRimIsStaticAndOnlyRetintsWhenTheMoodChanges() throws {
        let engine = engine()
        engine.reduceMotion = true
        engine.settle { _, _ in (0.6, 0.3, 0.2) }
        engine.step(to: 0.01)
        let core = engine.liveCore
        let row = core.top + 14
        let first = try #require(engine.tile(column: core.left - 2, row: row, nowColumn: nil))
        engine.step(to: 5)
        engine.step(to: 12)
        let later = try #require(engine.tile(column: core.left - 2, row: row, nowColumn: nil))
        #expect(first.colour.red == later.colour.red && first.colour.green == later.colour.green)
        #expect(engine.liveCore == core)
        // A new mood changes the tint, by a crossfade.
        engine.morph(.standard(.wave), origin: (50, 130)) { _, _ in (0.1, 0.9, 0.2) }
        engine.step(to: 12.3)
        let retinted = try #require(engine.tile(column: core.left - 2, row: row, nowColumn: nil))
        #expect(retinted.colour.green > later.colour.green)
    }

    /// At the largest text sizes a text block can sit wholly outside the grid: that is no shield, never a crash.
    @Test func aTextBlockOutsideTheGridShieldsNothingAndDoesNotCrash() {
        let engine = engine()
        let far = [CGRect(x: 0, y: 5000, width: 300, height: 80), CGRect(x: 9000, y: 100, width: 80, height: 80),
                   CGRect(x: -900, y: -900, width: 80, height: 80)]
        for rect in far {
            #expect(engine.grid.shield(for: [rect]).isEmpty)
        }
    }

    @Test func theTextShieldKeepsAFifthUnderWordsAndFeathersBackOverFiveTiles() throws {
        let engine = engine()
        engine.settle { _, _ in (0.2, 0.2, 0.9) }
        engine.step(to: 0.01)
        let core = engine.liveCore
        let column = core.left + 20, row = core.top + 12
        let plain = try #require(engine.tile(column: column, row: row, nowColumn: nil))
        let rect = engine.grid.rect(column: column, row: row)
        engine.shield = engine.grid.shield(for: [rect])
        let index = engine.grid.index(column: column, row: row)
        #expect(abs((engine.shield[index] ?? 1) - 0.22) < 1e-9)
        let under = try #require(engine.tile(column: column, row: row, nowColumn: nil))
        #expect(under.colour.red > plain.colour.red + 0.4)
        #expect(MosaicScreenGrid.shieldCap == 0.22 && MosaicScreenGrid.shieldFeather == 5)
        // One tile of pad at the full cap, then it rises smoothly back to the whole mosaic over 5 tiles, never in a
        // step.
        var kept: [Double] = []
        for offset in 0 ... 7 {
            kept.append(engine.shield[engine.grid.index(column: column + 1 + offset, row: row)] ?? 1)
        }
        #expect(abs(kept[0] - 0.22) < 1e-9)
        for pair in zip(kept, kept.dropFirst()) {
            #expect(pair.0 <= pair.1 + 1e-9)
        }
        #expect(kept[4] < 1 && kept[5] == 1)
        let steps = zip(kept, kept.dropFirst()).map { $1 - $0 }
        #expect((steps.max() ?? 1) < 0.5)
    }

    @Test func theRegionHoldsTheLargestCorePlusTheRimAndABreath() {
        let region = grid.region
        let core = grid.core(columns: 88, rows: 40)
        #expect(region.left <= max(core.left - 16, 0) && region.right >= core.right + 6)
        #expect(region.top <= core.top - 16 && region.bottom >= core.bottom + 16)
        // About six thousand tiles of the screen's twenty-two thousand.
        #expect(region.width * region.height < 9000)
        #expect(grid.count > 20000)
    }

    @Test func eachMoodsChangeoverIsTheSheets() {
        #expect(MosaicMood.day.changeover == .flip && MosaicMood.golden.changeover == .flip)
        #expect(MosaicMood.rest.changeover == .flip && MosaicMood.night.changeover == .flip)
        #expect(MosaicMood.morning.changeover == .standard(.fall) && MosaicMood.rain.changeover == .standard(.fall))
        #expect(MosaicMood.running.changeover == .standard(.wave) && MosaicMood.done.changeover == .standard(.wave))
        #expect(MosaicMood.back.changeover == .standard(.gather))
    }

    @Test func aFlipTurnsATileAboutItsMiddleOverThreeHundredMillisecondsAndSweepsLikeTheBoard() throws {
        let engine = engine()
        let old: MosaicTriple = (1, 0, 0), new: MosaicTriple = (0, 0, 1)
        engine.settle { _, _ in old }
        engine.morph(.flip, origin: (engine.grid.centreColumn, 130)) { _, _ in new }
        let column = engine.core.left + 10, row = engine.core.top + 10
        let regionIndex = try #require(engine.regionIndex(column: column, row: row))
        let absolute = engine.grid.index(column: column, row: row)
        // Delay = (column + 28) x 14 ms + row x 3 ms + hash x 80 ms, from the core's left.
        let delay = Double(column - engine.targetCore.left + 28) * 0.014 + Double(row - engine.grid.coreTop) * 0.003
            + MosaicColour.unit(absolute, salt: 121) * 0.08
        let doubled = MosaicColour.unit(absolute, salt: 123) < 0.3
        let length = doubled ? 0.6 : 0.3
        engine.step(to: delay - 0.01)
        #expect(engine.sceneColour(regionIndex, absolute: absolute).colour.red == 1)
        #expect(engine.sceneColour(regionIndex, absolute: absolute).scaleY == 1)
        // At the quarter point of a single flip it is edge-on-ish and squashed, never below 0.08.
        engine.step(to: delay + length * 0.5 / (doubled ? 2 : 1))
        let mid = engine.sceneColour(regionIndex, absolute: absolute)
        #expect(mid.scaleY >= 0.08 && mid.scaleY < 0.2)
        engine.step(to: delay + length + 0.01)
        let done = engine.sceneColour(regionIndex, absolute: absolute)
        #expect(done.colour.blue == 1 && done.scaleY == 1)
        // The sweep: a tile further right waits longer than one further left in the same row.
        let farRight = engine.core.left + 40
        let earlier = Double(column - engine.targetCore.left + 28) * 0.014
        let later = Double(farRight - engine.targetCore.left + 28) * 0.014
        #expect(later > earlier)
    }

    @Test func aboutThirtyPercentFlipTwiceAndShowAnInBetweenColour() {
        var twice = 0
        let total = 5000
        for index in 0 ..< total where MosaicColour.unit(index, salt: 123) < 0.3 {
            twice += 1
        }
        let share = Double(twice) / Double(total)
        #expect(abs(share - 0.3) < 0.04)
    }

    @Test func reduceMotionMakesEveryChangeoverOneCrossfadeAndNothingLeans() throws {
        let engine = engine()
        engine.reduceMotion = true
        engine.settle { _, _ in (1, 0, 0) }
        engine.morph(.flip, origin: (50, 130)) { _, _ in (0, 0, 1) }
        let column = engine.core.left + 10, row = engine.core.top + 10
        let regionIndex = try #require(engine.regionIndex(column: column, row: row))
        let absolute = engine.grid.index(column: column, row: row)
        engine.step(to: 0.075)
        let half = engine.sceneColour(regionIndex, absolute: absolute)
        #expect(half.scaleY == 1 && half.colour.red > 0.3 && half.colour.red < 0.7)
        engine.step(to: 0.2)
        #expect(engine.sceneColour(regionIndex, absolute: absolute).colour.blue == 1)
        engine.touch(at: CGPoint(x: 200, y: 500))
        #expect(engine.pops.isEmpty)
    }

    @Test func aTouchAnywhereRipplesAndLeansWithinTheSheetsRadii() {
        let engine = engine()
        let finger = CGPoint(x: 60, y: 700)
        #expect(MosaicScreenEngine.rippleDelay(center: CGPoint(x: 60 + 100, y: 700), from: finger) != nil)
        #expect(MosaicScreenEngine.rippleDelay(center: CGPoint(x: 60 + 141, y: 700), from: finger) == nil)
        #expect(abs((MosaicScreenEngine.rippleDelay(center: CGPoint(x: 160, y: 700), from: finger) ?? 0) - 100 *
                0.0026) < 1e-9)
        let lean = MosaicScreenEngine.leanTarget(center: CGPoint(x: 70, y: 700), from: finger)
        #expect(lean.x > 0 && lean.x <= 5)
        #expect(MosaicScreenEngine.leanTarget(center: CGPoint(x: 60 + 37, y: 700), from: finger) == .zero)
        // A touch starts a ripple wherever it lands (the pops that reach mosaic tiles are drawn).
        #expect(engine.touch(at: finger))
        #expect(!engine.pops.isEmpty)
    }

    @Test func theCoreEasesToItsMoodsWindowAndBreathes() {
        let engine = engine()
        engine.setWindow(columns: 36, rows: 22)
        engine.step(to: 0.05)
        #expect(engine.visibleColumns > 44)
        var time = 0.05
        for _ in 0 ..< 120 {
            time += 1.0 / 60
            engine.step(to: time)
        }
        #expect(abs(engine.visibleColumns - 36) <= 5)
        #expect(engine.core.width == engine.visibleColumns)
    }

    @Test func aFrameOfTheScreenMosaicCostsLittle() {
        let engine = engine()
        engine.settle { column, row in (Double(column % 7) / 7, Double(row % 5) / 5, 0.4) }
        let region = engine.region
        let started = ContinuousClock.now
        let frames = 20
        var drawn = 0
        for frame in 0 ..< frames {
            engine.step(to: Double(frame) / 60)
            for column in max(region.left, 0) ... min(region.right, engine.grid.columns - 1) {
                for row in max(region.top, 0) ... min(region.bottom, engine.grid.rows - 1)
                    where engine.tile(column: column, row: row, nowColumn: 60) != nil
                {
                    drawn += 1
                }
            }
        }
        let elapsed = started.duration(to: ContinuousClock.now)
        let milliseconds = Double(elapsed.components.seconds) * 1000 + Double(elapsed.components.attoseconds) / 1e15
        #expect(drawn / frames < 11500)
        #expect(milliseconds / Double(frames) < 24, "a frame took \(milliseconds / Double(frames)) ms")
    }
}
