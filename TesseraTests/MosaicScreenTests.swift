import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Home is the mosaic (sheet 202): the screen's own pixels, the field's intensity, the dither, the shield, the flip.
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

    @Test func theCoreIsCentredAtFiftySixPercentWithItsTopOnTheOldBlocksTop() {
        let core = grid.core(columns: 50, rows: 28)
        #expect(core.width == 50 && core.height == 28)
        #expect(core.top == 120)
        let centre = Double(core.left) + 25
        #expect(abs(centre - 0.56 * Double(grid.columns)) <= 1)
    }

    @Test func intensityRisesFromPointSixTwoToOneOverSevenTilesInsideTheCore() {
        let core = grid.core(columns: 50, rows: 28)
        let row = core.top + 14
        #expect(abs(grid.intensity(column: core.left, row: row, core: core) - 0.62) < 1e-9)
        #expect(abs(grid.intensity(column: core.left + 7, row: row, core: core) - 1.0) < 1e-9)
        #expect(grid.intensity(column: core.left + 3, row: row, core: core) > 0.62)
        #expect(grid.intensity(column: core.left + 3, row: row, core: core) < 1.0)
        // The middle of the core is full.
        #expect(grid.intensity(column: core.left + 25, row: row, core: core) == 1)
    }

    @Test func intensityFallsAwayOutsideAndIsGoneAtTwentyEightTiles() {
        let core = grid.core(columns: 50, rows: 28)
        let row = core.top + 14
        // d = 1 tile out: 0.62 x (27/28)^1.35.
        let near = grid.intensity(column: core.left - 1, row: row, core: core)
        #expect(abs(near - 0.62 * pow(27.0 / 28.0, 1.35)) < 1e-9)
        #expect(grid.intensity(column: core.left - 14, row: row, core: core)
            < grid.intensity(column: core.left - 7, row: row, core: core))
        #expect(grid.intensity(column: core.left - 28, row: row, core: core) == 0)
        #expect(grid.intensity(column: core.left - 40, row: row, core: core) == 0)
        // Distance is Euclidean: a diagonal tile is further than an axis one at the same offset.
        let diagonal = grid.intensity(column: core.left - 10, row: core.top - 10, core: core)
        let axis = grid.intensity(column: core.left - 10, row: row, core: core)
        #expect(diagonal < axis)
        // Continuous at the edge.
        #expect(abs(near - grid.intensity(column: core.left, row: row, core: core)) < 0.05)
    }

    @Test func outsideTilesAreDitheredByHashNeverFaded() {
        #expect(MosaicScreenGrid.shows(intensity: 0.1, hash: 0.5, insideCore: true))
        #expect(MosaicScreenGrid.shows(intensity: 0.5, hash: 0.9, insideCore: false))
        #expect(!MosaicScreenGrid.shows(intensity: 0.5, hash: 0.96, insideCore: false))
        #expect(!MosaicScreenGrid.shows(intensity: 0.05, hash: 0.5, insideCore: false))
        // At the core's edge intensity 0.62 x 1.9 is over 1: every tile shows; far out about a third do.
        #expect(MosaicScreenGrid.shows(intensity: 0.62, hash: 0.999, insideCore: false))
        var shown = 0
        for index in 0 ..< 2000 where MosaicScreenGrid.shows(
            intensity: 0.2,
            hash: MosaicColour.unit(index, salt: 111),
            insideCore: false
        ) {
            shown += 1
        }
        #expect(shown > 600 && shown < 900)
    }

    @Test func scaleIsPointFiveFivePlusPointFourFiveI() {
        #expect(abs(MosaicScreenGrid.scale(intensity: 1) - 1) < 1e-9)
        #expect(abs(MosaicScreenGrid.scale(intensity: 0.62) - (0.55 + 0.45 * 0.62)) < 1e-9)
        #expect(abs(MosaicScreenGrid.scale(intensity: 0) - 0.55) < 1e-9)
    }

    @Test func screenPixelsAreAShadeOffTheGroundDarkerInLightLookerInDark() {
        for index in 0 ..< 500 {
            let light = MosaicScreenGrid.screenDelta(index: index, dark: false)
            let dark = MosaicScreenGrid.screenDelta(index: index, dark: true)
            #expect(light >= (-4 - 1.5) / 255 - 1e-9 && light <= (-4 + 1.5) / 255 + 1e-9)
            #expect(dark >= (5 - 1.5) / 255 - 1e-9 && dark <= (5 + 1.5) / 255 + 1e-9)
            #expect(light == MosaicScreenGrid.screenDelta(index: index, dark: false))
        }
        let screen = engine().screenPixel(index: 10)
        #expect(screen.red < 0.98)
    }

    @Test func theTextShieldCapsTheFieldToAQuarterUnderWordsAndPadsOneTile() {
        let engine = engine()
        let core = engine.core
        let column = core.left + 10, row = core.top + 10
        let before = engine.intensity(column: column, row: row)
        let rect = engine.grid.rect(column: column, row: row)
        engine.shield = engine.grid.shield(for: [rect])
        #expect(abs(engine.intensity(column: column, row: row) - before * 0.22) < 1e-9)
        // One tile of pad on every side, none beyond.
        #expect(engine.intensity(column: column + 1, row: row) < engine.grid.intensity(
            column: column + 1,
            row: row,
            core: core
        ))
        #expect(engine.intensity(column: column + 2, row: row) == engine.grid.intensity(
            column: column + 2,
            row: row,
            core: core
        ))
    }

    @Test func theRegionHoldsTheLargestCorePlusTheReachAndABreath() {
        let region = grid.region
        let core = grid.core(columns: 62, rows: 40)
        #expect(region.left <= core.left - 28 && region.right >= core.right + 28)
        #expect(region.top <= core.top - 28 && region.bottom >= core.bottom + 28)
        // About eleven thousand tiles, not the whole screen's twenty-two thousand.
        #expect(region.width * region.height < 13000)
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
        // Down far from the field still starts a ripple (pops anywhere on Home).
        #expect(engine.touch(at: finger))
        #expect(!engine.pops.isEmpty)
        engine.step(to: 0.3)
        #expect(!engine.outsidePops().isEmpty)
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
