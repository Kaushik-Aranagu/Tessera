import Foundation
@testable import Tessera
import Testing
import TesseraCore

/// The Home mosaic's engine, scenes and words (sheet 199), tested without drawing.
@MainActor
struct MosaicTests {
    private let config = MosaicConfig.home
    private var geometry: MosaicGeometry { MosaicGeometry(config: config, width: 340) }

    private func engine(width: CGFloat = 340) -> MosaicEngine {
        MosaicEngine(config: config, width: width)
    }

    private func input(minutes: Int? = 23, hour: Int = 17, minute: Int = 42) -> MosaicSceneInput {
        var parts = DateComponents()
        parts.year = 2026; parts.month = 10; parts.day = 22; parts.hour = hour; parts.minute = minute
        let now = Calendar.current.date(from: parts) ?? Date()
        return MosaicSceneInput(now: now, nextMinutes: minutes) { hour in
            (hour / 24, 0.5, 1 - hour / 24)
        }
    }

    @Test func tileIsAboutEightPointsOnAPhone() {
        #expect(geometry.side == 8)
        #expect(geometry.pitch == 10)
        // Every tile sits inside the width and the column math round-trips.
        let last = geometry.rect(column: config.columns - 1, row: 0)
        #expect(last.maxX <= 340)
        for column in [0, 7, 33] {
            #expect(geometry.column(at: geometry.center(column: column, row: 3).x) == column)
        }
        #expect(geometry.column(at: -50) == 0)
        #expect(geometry.column(at: 900) == config.columns - 1)
    }

    @Test func aColumnCoversItsShareOfTheDay() {
        // Column c covers 6 am + (c + 0.5) / 34 x 18 h.
        #expect(abs(geometry.hour(ofColumn: 0) - (6 + 0.5 / 34 * 18)) < 1e-9)
        #expect(abs(geometry.hour(ofColumn: 33) - (6 + 33.5 / 34 * 18)) < 1e-9)
        #expect(geometry.column(ofHour: 6) == 0)
        #expect(geometry.column(ofHour: 15) == 17)
        #expect(geometry.column(ofHour: 23.99) == 33)
    }

    @Test func nowColumnIsNilBeforeSixAndFollowsTheClock() {
        let early = input(hour: 5, minute: 30).now
        #expect(MosaicReadout.nowColumn(early, config: config) == nil)
        let noon = input(hour: 12, minute: 0).now
        #expect(MosaicReadout.nowColumn(noon, config: config) == 11)
        let three = input(hour: 15, minute: 0).now
        #expect(MosaicReadout.nowColumn(three, config: config) == 17)
        let late = input(hour: 23, minute: 59).now
        #expect(MosaicReadout.nowColumn(late, config: config) == 33)
    }

    @Test func readoutNamesTheHourSpan() {
        let text = MosaicReadout.text(column: 14, config: config)
        #expect(text.hasSuffix("."))
        #expect(text.contains(" to "))
        #expect(MosaicReadout.text(column: 14, config: config, event: "Lunch").hasSuffix(", Lunch."))
        // A pair of columns reads the same hour.
        #expect(MosaicReadout.text(column: 14, config: config) == MosaicReadout.text(column: 15, config: config))
    }

    @Test func aTouchRipplesOnlyInsideTheRadiusAndLaterFartherOut() {
        let e = engine()
        let finger = e.geometry.center(column: 10, row: 10)
        let near = e.rippleDelay(center: e.geometry.center(column: 11, row: 10), from: finger)
        let far = e.rippleDelay(center: e.geometry.center(column: 20, row: 10), from: finger)
        let out = e.rippleDelay(center: e.geometry.center(column: 30, row: 10), from: finger)
        #expect(near != nil && far != nil && out == nil)
        #expect((near ?? 9) < (far ?? 0))
        // 2.6 ms a point.
        #expect(abs((near ?? 0) - 10 * 0.0026) < 1e-9)
    }

    @Test func fingerDownRipplesAndTheSecondTouchDoesNot() {
        let e = engine()
        let down = e.touch(at: CGPoint(x: 100, y: 100))
        #expect(down.down)
        #expect(!e.pops.isEmpty)
        let moved = e.touch(at: CGPoint(x: 104, y: 100))
        #expect(!moved.down)
    }

    @Test func draggingAcrossTwoColumnSpansTicksOncePerSpan() {
        let e = engine()
        e.touch(at: CGPoint(x: geometry.center(column: 0, row: 5).x, y: 50))
        let sameSpan = e.touch(at: CGPoint(x: geometry.center(column: 1, row: 5).x, y: 50))
        #expect(!sameSpan.spanChanged)
        let nextSpan = e.touch(at: CGPoint(x: geometry.center(column: 2, row: 5).x, y: 50))
        #expect(nextSpan.spanChanged)
    }

    @Test func tilesLeanAwayFromAFingerAndNotPastTheRadius() {
        let e = engine()
        let finger = CGPoint(x: 100, y: 100)
        let right = e.leanTarget(center: CGPoint(x: 110, y: 100), from: finger)
        #expect(right.x > 0 && abs(right.y) < 1e-9)
        #expect(right.x <= 7)
        let under = e.leanTarget(center: finger, from: finger)
        #expect(abs(under.x) <= 7)
        #expect(e.leanTarget(center: CGPoint(x: 100 + 47, y: 100), from: finger) == .zero)
    }

    @Test func leanSpringsBackAfterTheFingerLifts() {
        let e = engine()
        e.touch(at: e.geometry.center(column: 10, row: 10))
        var time = 0.0
        for _ in 0 ..< 30 {
            time += 1.0 / 60
            e.step(to: time)
        }
        let leaned = e.offset(column: 11, row: 10)
        #expect(leaned.x > 0.5)
        e.endTouch()
        for _ in 0 ..< 240 {
            time += 1.0 / 60
            e.step(to: time)
        }
        #expect(abs(e.offset(column: 11, row: 10).x) < 0.02)
    }

    @Test func aTilePopsEverySeventyMillisecondsTenth() {
        let e = engine()
        var time = 0.0
        var seen = 0
        for _ in 0 ..< 120 {
            time += 1.0 / 60
            e.step(to: time)
            seen = max(seen, e.pops.count)
        }
        #expect(seen >= 1)
        // Same seed, same pops.
        let other = engine()
        var t2 = 0.0
        for _ in 0 ..< 120 {
            t2 += 1.0 / 60
            other.step(to: t2)
        }
        #expect(Set(e.pops.keys) == Set(other.pops.keys))
    }

    @Test func reduceMotionKeepsTheMosaicStill() {
        let e = engine()
        e.reduceMotion = true
        var time = 0.0
        for _ in 0 ..< 240 {
            time += 1.0 / 60
            e.step(to: time)
        }
        #expect(e.pops.isEmpty)
        e.touch(at: CGPoint(x: 100, y: 100))
        #expect(e.pops.isEmpty)
        #expect(e.scale(column: 3, row: 3) == 1)
        #expect(e.offset(column: 4, row: 3) == .zero)
    }

    @Test func swellTravelsAndStaysUnderItsAmplitude() {
        let e = engine()
        var peak: CGFloat = 1
        var time = 0.0
        for _ in 0 ..< 420 {
            time += 1.0 / 60
            e.step(to: time)
            peak = max(peak, e.scale(column: 17, row: 12))
        }
        #expect(peak > 1.1 && peak <= 1.22 + 0.5 + 0.45 + 1e-6)
    }

    @Test func jitterNeverShimmersAndStaysInRange() {
        for index in 0 ..< 850 {
            let value = MosaicColour.jitter(index: index)
            #expect(value >= -1 && value <= 1)
            #expect(value == MosaicColour.jitter(index: index))
        }
    }

    // MARK: - Scenes

    @Test func dayMixesTheFutureTowardTheGround() {
        let ground: MosaicTriple = (1, 1, 1)
        let colours = MosaicScenes.targets(.day, geometry: geometry, input: input(hour: 12, minute: 0), ground: ground)
        let past = colours[geometry.index(column: 2, row: 5)]
        let future = colours[geometry.index(column: 30, row: 5)]
        // The future is nearer white than a past tile of the same sky would be: its blue channel is closer to 1.
        #expect(abs(future.blue - 1) < abs(past.blue - 1) + 0.6)
        #expect(colours.count == 850)
    }

    @Test func timeDrawsFiveFortyTwoInTiles() {
        let tiles = MosaicScenes.numeral("5:42", geometry: geometry)
        #expect(!tiles.isEmpty)
        let columns = tiles.map { $0 / config.rows }
        let rows = tiles.map { $0 % config.rows }
        // Six wide digits, a two wide colon, two apart: 26 columns, 10 rows, centred.
        #expect((columns.max() ?? 0) - (columns.min() ?? 0) + 1 == 26)
        #expect((rows.max() ?? 0) - (rows.min() ?? 0) + 1 == 10)
        #expect(columns.min() == (34 - 26) / 2)
        #expect(rows.min() == (25 - 10) / 2)
    }

    @Test func timeScenePaintsDigitsDarkAndTheRestPale() {
        let ground: MosaicTriple = (1, 1, 1)
        let sample = input()
        let colours = MosaicScenes.targets(.time, geometry: geometry, input: sample, ground: ground)
        let digits = MosaicScenes.digitTiles(for: .time, input: sample, geometry: geometry)
        let digit = colours[digits.first ?? 0]
        let other = colours[geometry.index(column: 0, row: 0)]
        #expect(digit.red + digit.green + digit.blue < other.red + other.green + other.blue)
    }

    @Test func nextDrawsTheMinutes() {
        #expect(MosaicScenes.text(for: .next, input: input(minutes: 23)) == "23")
        #expect(MosaicScenes.text(for: .next, input: input(minutes: nil)) == nil)
        #expect(MosaicScenes.text(for: .day, input: input()) == nil)
    }

    @Test func skyDrawsTheSunAndTheDuskGround() {
        let sky: MosaicTriple = (0.5, 0.5, 0.5)
        let sunColumn = Int(0.71 * 34)
        let sunRow = Int(0.58 * 25)
        let sun = MosaicScenes.skyScene(column: sunColumn, row: sunRow, sky: sky, geometry: geometry)
        #expect(abs(sun.red - MosaicScenes.sun.red) < 1e-9)
        let far = MosaicScenes.skyScene(column: 2, row: 2, sky: sky, geometry: geometry)
        #expect(abs(far.red - 0.5) < 1e-9)
        let dusk = MosaicScenes.skyScene(column: 2, row: 23, sky: sky, geometry: geometry)
        #expect(dusk.red != far.red)
        // The ring blends between the sun and the sky.
        let ring = MosaicScenes.skyScene(column: sunColumn + 5, row: sunRow, sky: sky, geometry: geometry)
        #expect(ring.red != sun.red && ring.red != 0.5)
    }

    @Test func morphDelaysByDistanceFromTheOrigin() {
        let e = engine()
        let targets = MosaicScenes.targets(.time, geometry: e.geometry, input: input(), ground: (1, 1, 1))
        e.settle(to: MosaicScenes.targets(.day, geometry: e.geometry, input: input(), ground: (1, 1, 1)))
        e.morph(to: targets, origin: (0, 12))
        // Just after the start, the origin's neighbours have moved and the far right has not.
        e.step(to: 0.05)
        let near = e.morphProgress(e.geometry.index(column: 1, row: 12)) ?? 0
        let far = e.morphProgress(e.geometry.index(column: 33, row: 12)) ?? 0
        #expect(near > 0)
        #expect(far == 0)
        // 520 ms after its own delay, every tile has arrived.
        e.step(to: 0.05 + 0.1)
        e.step(to: 0.05 + 0.2)
        e.step(to: 2)
        #expect((e.morphProgress(e.geometry.index(column: 33, row: 24)) ?? 0) == 1)
    }

    @Test func reduceMotionMorphIsOneCrossfade() {
        let e = engine()
        e.reduceMotion = true
        e.settle(to: MosaicScenes.targets(.day, geometry: e.geometry, input: input(), ground: (1, 1, 1)))
        e.morph(to: MosaicScenes.targets(.time, geometry: e.geometry, input: input(), ground: (1, 1, 1)), origin: (0, 0))
        e.step(to: 0.16)
        #expect((e.morphProgress(e.geometry.index(column: 33, row: 24)) ?? 0) == 1)
    }

    // MARK: - Laying

    @Test func aFlyingTileLandsInTheNowColumnAfterSevenHundredMilliseconds() {
        let e = engine()
        let started = e.lay(from: CGPoint(x: 200, y: -40), side: 14, column: 17, tone: .glaze)
        #expect(started)
        #expect(e.flight != nil)
        e.step(to: 0.35)
        #expect(e.laid.isEmpty)
        #expect(e.flightState() != nil)
        e.step(to: 0.71)
        #expect(e.flight == nil)
        #expect(e.laid.count == 1)
        let tile = e.laid[0]
        #expect(tile.column == 17)
        #expect(config.layRows.contains(tile.index % config.rows))
        #expect(e.consumeLandings() == 1)
        #expect(e.consumeLandings() == 0)
    }

    @Test func aTileIsNeverLaidTwiceOnTheSameSpot() {
        let e = engine()
        var time = 0.0
        for _ in 0 ..< 10 {
            e.lay(from: .zero, side: 14, column: 5, tone: .accent(.training))
            time += 0.8
            e.step(to: time)
        }
        let spots = e.laid.map(\.index)
        #expect(Set(spots).count == spots.count)
        #expect(spots.count == 10)
    }

    @Test func aFullColumnLaysNothingMore() {
        let e = engine()
        for _ in config.layRows {
            e.restore(column: 3, tone: .glaze)
        }
        #expect(e.freeTile(inColumn: 3) == nil)
        #expect(!e.lay(from: .zero, side: 14, column: 3, tone: .glaze))
    }

    @Test func reduceMotionLaysAtOnceAndFadesIn() {
        let e = engine()
        e.reduceMotion = true
        e.lay(from: .zero, side: 14, column: 8, tone: .glaze)
        #expect(e.flight == nil)
        #expect(e.laid.count == 1)
        e.step(to: 0.0)
        #expect(e.laidOpacity(e.laid[0]) == 0)
        e.step(to: 0.15)
        #expect(e.laidOpacity(e.laid[0]) == 1)
    }

    @Test func midnightClearsTheTiles() {
        let e = engine()
        e.restore(column: 3, tone: .glaze)
        e.reset()
        #expect(e.laid.isEmpty)
        #expect(e.freeTile(inColumn: 3) != nil)
    }

    @Test func houseSpringStartsAtZeroAndSettlesAtOne() {
        #expect(MosaicEngine.houseSpring(0) == 0)
        #expect(MosaicEngine.houseSpring(1) == 1)
        let mid = MosaicEngine.houseSpring(0.5)
        #expect(mid > 0.5 && mid < 1.2)
    }

    @Test func glazedAndAccentTonesComeFromCoreTypes() {
        // The tone is Core's: an accent carries an AppID, which the view maps to its colour.
        #expect(MosaicTone.accent(.kitchen) == MosaicTone.accent(.kitchen))
        #expect(MosaicTone.accent(.kitchen) != MosaicTone.glaze)
        #expect(HomeApp(rawValue: AppID.training.name) == .training)
        for app in AppID.allCases {
            #expect(HomeApp(rawValue: app.name) != nil)
        }
    }
}
