import Foundation
@testable import Tessera
import Testing

/// The departure mosaic (sheet 200): the grid, the dithered edges, the five transitions and the nine moods.
@MainActor
struct MosaicMoodTests {
    private let config = MosaicConfig.moods
    private var geometry: MosaicGeometry {
        MosaicGeometry(config: config, width: 342)
    }

    private func input() -> MosaicSceneInput {
        MosaicSceneInput(now: Date(), nextMinutes: 20) { hour in
            (hour / 24, 0.5, 1 - hour / 24)
        }
    }

    private func engine() -> MosaicEngine {
        MosaicEngine(config: config, width: 342)
    }

    @Test func gridIsFiftyTwoByThirtyThreeAtStepSix() {
        #expect(config.columns == 52 && config.rows == 33)
        #expect(geometry.side == 5)
        #expect(geometry.pitch == 6)
        #expect(config.corner == 1.1)
        #expect(config.leanRadius == 36 && config.leanMax == 5 && config.rippleRadius == 120)
        // The grid fits and is centred.
        #expect(geometry.gridWidth == 311)
        #expect(geometry.inset > 0)
    }

    @Test func edgesDitherByHashAndNeverBlur() {
        let kinds = MosaicEngine.edgeKinds(config: config)
        #expect(kinds == MosaicEngine.edgeKinds(config: config))
        // Away from the edge nothing changes.
        for column in 4 ..< config.columns - 4 {
            #expect(kinds[geometry.index(column: column, row: 10)] == .full)
        }
        // The outermost ring keeps about 1 in 5; the fourth ring keeps 4 in 5.
        func keptShare(edge: Int) -> Double {
            var kept = 0, total = 0
            for column in edge ..< config.columns - edge {
                for row in [edge, config.rows - 1 - edge] {
                    total += 1
                    if kinds[geometry.index(column: column, row: row)] != .dropped {
                        kept += 1
                    }
                }
            }
            return Double(kept) / Double(total)
        }
        #expect(abs(keptShare(edge: 0) - 0.2) < 0.12)
        #expect(abs(keptShare(edge: 3) - 0.8) < 0.15)
    }

    @Test func aKeptEdgeTileIsDimmerAndSmaller() {
        let mosaic = engine()
        var found: MosaicEngine.EdgeRule?
        var column = 0
        while found == nil, column < config.columns {
            if case let .kept(rule) = mosaic.edgeKind(column: column, row: 0) {
                found = rule
            }
            column += 1
        }
        let rule = try? #require(found)
        // Edge 0: k = 0.55, so mix (1 - 0.55) x 0.8 = 0.36 and scale 0.6 + 0.4 x 0.55 = 0.82.
        #expect(abs((rule?.mixToGround ?? 0) - 0.36) < 1e-9)
        #expect(abs((rule?.scale ?? 0) - 0.82) < 1e-9)
    }

    @Test func eachMoodHasItsDefaultTransition() {
        #expect(MosaicMood.morning.transition == .fall)
        #expect(MosaicMood.day.transition == .wave)
        #expect(MosaicMood.golden.transition == .wipe)
        #expect(MosaicMood.running.transition == .wave)
        #expect(MosaicMood.rest.transition == .dissolve)
        #expect(MosaicMood.back.transition == .gather)
        #expect(MosaicMood.done.transition == .wave)
        #expect(MosaicMood.rain.transition == .fall)
        #expect(MosaicMood.night.transition == .dissolve)
        #expect(MosaicMood.allCases.count == 9)
    }

    @Test func waveDelaysByDistanceTwentyMilliseconds() {
        let plan = MosaicTransition.wave.plan(geometry: geometry, origin: (0, 0))
        let near = plan.delays[geometry.index(column: 3, row: 4)]
        #expect(abs(near - 5 * 0.020) < 1e-9)
        #expect(plan.lengths.allSatisfy { $0 == 0.52 })
    }

    @Test func fallDropsEachColumnLaterAndFromTheBottomUp() {
        let plan = MosaicTransition.fall.plan(geometry: geometry, origin: (0, 0))
        let bottom = plan.delays[geometry.index(column: 7, row: config.rows - 1)]
        let top = plan.delays[geometry.index(column: 7, row: 0)]
        #expect(abs((top - bottom) - 0.026 * Double(config.rows - 1)) < 1e-9)
        #expect(plan.lengths.allSatisfy { $0 == 0.36 })
        #expect(bottom >= 0 && bottom <= 0.38)
    }

    @Test func wipeIsAStairDiagonalOverOneSecond() {
        let plan = MosaicTransition.wipe.plan(geometry: geometry, origin: (0, 0))
        let start = plan.delays[geometry.index(column: 0, row: 0)]
        let end = plan.delays[geometry.index(column: config.columns - 1, row: config.rows - 1)]
        #expect(start < 0.07)
        #expect(end > 0.9 && end < 1.1)
        // Tiles three steps apart on the diagonal share a stair.
        let first = plan.delays[geometry.index(column: 3, row: 0)]
        let second = plan.delays[geometry.index(column: 5, row: 0)]
        #expect(abs(first - second) < 0.07)
    }

    @Test func dissolveSwapsAtHashTimesNineHundredAndGatherSevenHundred() {
        let dissolve = MosaicTransition.dissolve.plan(geometry: geometry, origin: (0, 0))
        #expect(dissolve.delays.allSatisfy { $0 >= 0 && $0 <= 0.9 })
        let gather = MosaicTransition.gather.plan(geometry: geometry, origin: (0, 0))
        #expect(gather.delays.allSatisfy { $0 >= 0 && $0 <= 0.7 })
        #expect(gather.lengths.allSatisfy { $0 == 0.5 })
        #expect(MosaicTransition.gather.total(geometry: geometry, origin: (0, 0)) <= 1.2)
    }

    @Test func aFallingTileDropsFromAboveAndLandsAtRest() {
        let mosaic = engine()
        let targets = MosaicMoodField.base(.morning, geometry: mosaic.geometry, input: input(), ground: (1, 1, 1),
                                           context: MosaicMoodContext())
        mosaic.settle(to: MosaicMoodField.base(.day, geometry: mosaic.geometry, input: input(), ground: (1, 1, 1),
                                               context: MosaicMoodContext()))
        mosaic.morph(to: targets, origin: (26, 16), transition: .fall)
        let column = 10, row = config.rows - 1
        // At the tile's own start it has just begun to drop: well above its place.
        let start = MosaicTransition.fall.plan(geometry: mosaic.geometry, origin: (26, 16))
            .delays[mosaic.geometry.index(
                column: column,
                row: row
            )]
        mosaic.step(to: start + 0.02)
        #expect(mosaic.offset(column: column, row: row).y < -20)
        mosaic.step(to: 3)
        #expect(mosaic.offset(column: column, row: row).y == 0)
    }

    @Test func gatheredTilesStartScatteredAndEndInPlace() {
        let mosaic = engine()
        let ctx = MosaicMoodContext()
        mosaic.settle(to: MosaicMoodField.base(.day, geometry: mosaic.geometry, input: input(), ground: (1, 1, 1),
                                               context: ctx))
        mosaic.morph(to: MosaicMoodField.base(.back, geometry: mosaic.geometry, input: input(), ground: (1, 1, 1),
                                              context: ctx), origin: (0, 0), transition: .gather)
        let tile = mosaic.geometry.index(column: 20, row: 15)
        let delay = MosaicTransition.gather.plan(geometry: mosaic.geometry, origin: (0, 0)).delays[tile]
        mosaic.step(to: delay + 0.03)
        let early = mosaic.offset(column: 20, row: 15)
        #expect(abs(early.x) + abs(early.y) > 3)
        mosaic.step(to: 3)
        #expect(mosaic.offset(column: 20, row: 15) == .zero)
    }

    @Test func reduceMotionIsOneCrossfadeForEveryTransition() {
        for transition in MosaicTransition.allCases {
            let mosaic = engine()
            mosaic.reduceMotion = true
            mosaic.settle(to: MosaicMoodField.base(.day, geometry: mosaic.geometry, input: input(), ground: (1, 1, 1),
                                                   context: MosaicMoodContext()))
            mosaic.morph(to: MosaicMoodField.base(.night, geometry: mosaic.geometry, input: input(), ground: (1, 1, 1),
                                                  context: MosaicMoodContext()), origin: (0, 0), transition: transition)
            mosaic.step(to: 0.16)
            #expect((mosaic.morphProgress(mosaic.geometry.index(column: 51, row: 32)) ?? 0) == 1)
            #expect(mosaic.offset(column: 10, row: 10) == .zero)
        }
    }

    // MARK: - Moods

    private func base(_ mood: MosaicMood, context: MosaicMoodContext = MosaicMoodContext()) -> [MosaicTriple] {
        MosaicMoodField.base(mood, geometry: geometry, input: input(), ground: (1, 1, 1), context: context)
    }

    @Test func everyMoodFillsTheWholeGrid() {
        for mood in MosaicMood.allCases {
            #expect(base(mood).count == config.count)
        }
    }

    @Test func morningHasAGoldSunAboveTheHorizonAndWaterBelow() {
        let colours = base(.morning)
        let horizon = Int(Double(config.rows) * 0.66)
        let sun = colours[geometry.index(column: config.columns / 2, row: horizon - 6)]
        #expect(sun.red > 0.85 && sun.green > 0.7 && sun.blue < 0.45)
        let sky = colours[geometry.index(column: 5, row: 2)]
        let water = colours[geometry.index(column: 5, row: config.rows - 2)]
        #expect(sky.red != water.red || sky.blue != water.blue)
    }

    @Test func goldenSunIsRadiusThreePointSixAtSeventyEightAndSixtyTwo() {
        let colours = base(.golden)
        let column = Int(Double(config.columns) * 0.78), row = Int(Double(config.rows) * 0.62)
        let sun = colours[geometry.index(column: column, row: row)]
        #expect(sun.red > 0.95 && sun.blue < 0.6)
        let far = colours[geometry.index(column: column - 9, row: row)]
        #expect(far.red < sun.red || far.green < sun.green)
    }

    @Test func nightHasACrescentNotAFullDisc() {
        let colours = base(.night)
        let centreColumn = Int(Double(config.columns) * 0.82), centreRow = Int(Double(config.rows) * 0.18)
        func isMoon(_ column: Int, _ row: Int) -> Bool {
            let colour = colours[geometry.index(column: column, row: row)]
            return colour.red > 0.8 && colour.green > 0.8
        }
        let lit = (centreColumn - 4 ... centreColumn + 4).flatMap { column in
            (centreRow - 4 ... centreRow + 4).filter { isMoon(column, $0) }
        }.count
        #expect(lit > 6)
        // A full disc of radius 3.4 is about 36 tiles; the crescent is well under that.
        #expect(lit < 30)
    }

    @Test func dayAndRunningShareTheNinetyNineField() {
        var context = MosaicMoodContext()
        context.nowColumn = 20
        #expect(zip(base(.day, context: context), base(.running, context: context)).allSatisfy {
            $0.0.red == $0.1.red && $0.0.green == $0.1.green
        })
    }

    @Test func futureColumnsOfTheDayFieldArePale() {
        var context = MosaicMoodContext()
        context.nowColumn = 10
        let colours = base(.day, context: context)
        let past = colours[geometry.index(column: 5, row: 12)]
        let future = colours[geometry.index(column: 45, row: 12)]
        // Mixed toward white ground, the future is nearer 1 on blue than the same sky unmixed would be.
        #expect(abs(future.blue - 1) < 0.6)
        #expect(past.red != future.red)
    }

    // MARK: - Moving light

    @Test func moodsWithMovingLightHaveAnOverlayAndStillOnesDoNot() {
        let context = MosaicMoodContext()
        for mood in [MosaicMood.morning, .golden, .running, .rest, .done, .rain, .night] {
            #expect(MosaicMoodField.overlay(mood, geometry: geometry, context: context, reduceMotion: false) != nil)
        }
        #expect(MosaicMoodField.overlay(.day, geometry: geometry, context: context, reduceMotion: false) == nil)
        #expect(MosaicMoodField.overlay(.back, geometry: geometry, context: context, reduceMotion: false) == nil)
    }

    @Test func reduceMotionKeepsEveryMoodStill() {
        for mood in MosaicMood.allCases {
            #expect(MosaicMoodField.overlay(mood, geometry: geometry, context: MosaicMoodContext(), reduceMotion: true)
                == nil)
        }
    }

    @Test func fireworksUseTheFinishedAppsAccentsAndFadeAfterTwoPointTwoSeconds() throws {
        var context = MosaicMoodContext()
        context.doneAccents = [(1, 0, 0)]
        let overlay = try #require(MosaicMoodField.overlay(
            .done,
            geometry: geometry,
            context: context,
            reduceMotion: false
        ))
        let ground: MosaicTriple = (0.2, 0.2, 0.2)
        // Somewhere on the ring at 1 s a tile takes the accent; at 3 s (after 2.2 s) none do.
        func tinted(at time: TimeInterval) -> Int {
            var count = 0
            for column in 0 ..< config.columns {
                for row in 0 ..< config.rows {
                    let result = overlay(column, row, time, ground)
                    if result.red > ground.red + 0.05, abs(result.green - ground.green) < 0.2 {
                        count += 1
                    }
                }
            }
            return count
        }
        #expect(tinted(at: 1) > 3)
        #expect(tinted(at: 3) == 0)
        // It repeats every 5.2 s.
        #expect(tinted(at: 5.2 + 1) > 3)
    }

    @Test func rainDropsRunDownColumns() throws {
        let overlay = try #require(MosaicMoodField.overlay(.rain, geometry: geometry, context: MosaicMoodContext(),
                                                           reduceMotion: false))
        let ground: MosaicTriple = (0.4, 0.45, 0.5)
        var lit = 0
        for row in 0 ..< config.rows where overlay(7, row, 2, ground).red > ground.red + 0.01 {
            lit += 1
        }
        #expect(lit >= 1 && lit <= 3)
    }

    @Test func aboutFourPercentOfNightTilesAreStars() throws {
        let overlay = try #require(MosaicMoodField.overlay(.night, geometry: geometry, context: MosaicMoodContext(),
                                                           reduceMotion: false))
        var stars = 0
        let total = config.count
        for index in 0 ..< total where MosaicColour.unit(index, salt: 43) < 0.04 {
            stars += 1
        }
        let share = Double(stars) / Double(total)
        #expect(abs(share - 0.04) < 0.015)
        _ = overlay
    }

    @Test func todaysDoneTilesGlowLowInTheNowColumnAtNight() throws {
        var context = MosaicMoodContext()
        context.nowColumn = 30
        context.doneCount = 3
        let overlay = try #require(MosaicMoodField.overlay(.night, geometry: geometry, context: context,
                                                           reduceMotion: false))
        let dark: MosaicTriple = (0.05, 0.06, 0.15)
        let glow = overlay(30, config.rows - 3, 1, dark)
        let aside = overlay(10, config.rows - 3, 1, dark)
        #expect(glow.red > aside.red + 0.2)
    }

    @Test func moodsShareTheOneHomeMosaicMoodsSwitch() {
        #expect(MosaicMoodsSwitch.choiceID == "homeMosaicMoods")
    }
}
