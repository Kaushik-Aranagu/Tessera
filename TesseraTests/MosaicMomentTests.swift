import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Mosaic moments (sheet 201): each moment's window, timing and key pixels, without drawing.
@MainActor
struct MosaicMomentTests {
    private let ground: MosaicTriple = (1, 1, 1)
    private func under(_ columns: Int, _ rows: Int) -> [MosaicTriple] {
        Array(repeating: MosaicTriple(0.4, 0.3, 0.2), count: columns * rows)
    }

    private func plan(
        _ moment: MosaicMoment,
        reduceMotion: Bool = false,
        context: MosaicMoodContext = MosaicMoodContext()
    )
        -> MosaicMomentPlan
    {
        let window = moment.window ?? (50, 28)
        return MosaicMomentField.plan(moment, under: under(window.columns, window.rows), window: window, ground: ground,
                                      context: context, start: 0, reduceMotion: reduceMotion)
    }

    @Test func eachMomentHasItsWindowTransitionAndDuration() {
        let table: [(MosaicMoment, (Int, Int)?, MosaicTransition, Double?)] = [
            (.snow, (50, 32), .fall, 9), (.fog, (56, 24), .dissolve, 8), (.wind, (62, 22), .wipe, 7),
            (.storm, (56, 34), .fall, 8), (.heat, (50, 26), .wave, 7), (.tess, (40, 24), .gather, 6.5),
            (.timer, (32, 32), .wave, 4.2), (.finished(tone: .glaze), nil, .wave, 3.2),
        ]
        for (moment, window, transition, duration) in table {
            #expect(moment.window?.columns == window?.0 && moment.window?.rows == window?.1)
            #expect(moment.transition == transition)
            if let duration {
                #expect(moment.duration == duration)
            }
        }
        let announce = MosaicMoment.announce(words: [MosaicAnnounceWord(text: "Push A", app: .training)])
        #expect(announce.window?.columns == 62 && announce.window?.rows == 22)
        #expect(announce.transition == .wipe)
    }

    @Test func momentsHandBackBackWithTheirOwnChangeover() {
        let announce = MosaicMoment.announce(words: [MosaicAnnounceWord(text: "Push A", app: nil)])
        #expect(announce.returnChangeover == .melt)
        #expect(MosaicMoment.snow.returnChangeover == .melt && MosaicMoment.storm.returnChangeover == .melt)
        #expect(MosaicMoment.fog.returnChangeover == .transition(.dissolve))
        #expect(MosaicMoment.heat.returnChangeover == .transition(.wave))
        #expect(MosaicMoment.tess.returnChangeover == .transition(.gather))
        #expect(MosaicMoment.timer.returnChangeover == .transition(.dissolve))
        #expect(MosaicMoment.finished(tone: .glaze).returnChangeover == .transition(.dissolve))
    }

    @Test func newEventsAreDistinctSoANewOneReplacesARunningOne() {
        #expect(MosaicMomentEvent(.snow) != MosaicMomentEvent(.snow))
        let first = MosaicMomentEvent(.snow)
        #expect(first == first)
    }

    @Test func snowHasItsOwnPaleFieldAndADriftThatBuilds() throws {
        let snow = plan(.snow)
        let base = try #require(snow.base)
        #expect(base.count == 50 * 32)
        let overlay = try #require(snow.overlay)
        let colour: MosaicTriple = (0.8, 0.85, 0.9)
        // After 4.6 s the drift is 3 rows high; after 9 s the 5-row cap.
        #expect(overlay(10, 31, 4.6, colour).red > 0.9)
        #expect(overlay(10, 28, 4.6, colour).red < 0.9 || overlay(10, 28, 4.6, colour).red >= 0.8)
        #expect(overlay(10, 27, 9, colour).red > 0.9)
        #expect(overlay(10, 26, 9, colour).red <= overlay(10, 27, 9, colour).red)
        // Flakes: over a few seconds some tiles above the drift go white.
        var flakes = 0
        for column in 0 ..< 50 {
            for row in 0 ..< 20 where overlay(column, row, 1.0, colour).red > 0.9 {
                flakes += 1
            }
        }
        #expect(flakes >= 10 && flakes <= 130)
    }

    @Test func fogLevelsAreQuarterSteps() {
        for column in 0 ..< 20 {
            for row in 0 ..< 10 {
                let level = MosaicMomentField.fogLevel(column: column, row: row, time: 1.3)
                #expect(abs(level / 0.25 - (level / 0.25).rounded()) < 1e-9)
                #expect(level >= 0.25 && level <= 1.0)
            }
        }
        let fog = plan(.fog)
        let shrink = fog.scale?(3, 4, 2) ?? 1
        #expect(shrink >= 0.85 && shrink <= 1)
    }

    @Test func windSwaysAndStreaksCrossAboutAThirdOfTheRows() throws {
        let wind = plan(.wind)
        let offset = try #require(wind.offset)
        var moved = false
        for time in stride(from: 0.0, to: 2, by: 0.1) where abs(offset(10, 5, time).x) > 0.5 {
            moved = true
        }
        #expect(moved)
        #expect(abs(offset(10, 5, 1).x) <= 1.8 + 1e-9)
        let streakRows = (0 ..< 22).filter { MosaicColour.unit($0, salt: 71) < 0.34 }.count
        #expect(streakRows >= 3 && streakRows <= 12)
    }

    @Test func aBoltStartsBetweenAQuarterAndThreeQuartersAndWalksAtMostAboutOneAndAHalf() {
        for cycle in 0 ..< 10 {
            let top = MosaicMomentField.boltColumn(cycle: cycle, row: 0, cols: 56)
            #expect(top >= Int(56 * 0.25) - 2 && top <= Int(56 * 0.75) + 2)
            var last = top
            for row in 1 ..< 30 {
                let column = MosaicMomentField.boltColumn(cycle: cycle, row: row, cols: 56)
                #expect(abs(column - last) <= 2)
                last = column
            }
        }
        #expect(MosaicMomentField.boltColumn(cycle: 2, row: 9, cols: 56)
            == MosaicMomentField.boltColumn(cycle: 2, row: 9, cols: 56))
    }

    @Test func stormFlashesAndShowsABoltOnlyForAMoment() throws {
        let overlay = try #require(plan(.storm).overlay)
        let dark: MosaicTriple = (0.1, 0.12, 0.15)
        // At 0.05 s into a cycle the whole field flashes; at 1 s it does not.
        #expect(overlay(5, 5, 0.05, dark).red > 0.4)
        #expect(overlay(5, 5, 1.0, dark).red < 0.4)
        // A bolt tile is near-white for 260 ms and gone by 0.4 s.
        let column = MosaicMomentField.boltColumn(cycle: 0, row: 3, cols: 56)
        #expect(overlay(column, 3, 0.2, dark).red > 0.9)
        #expect(overlay(column, 3, 0.4, dark).red < 0.9)
    }

    @Test func heatTintsWarmAndSwaysRows() throws {
        let heat = plan(.heat)
        let offset = try #require(heat.offset)
        var peak = 0.0
        for time in stride(from: 0.0, to: 2, by: 0.05) {
            peak = max(peak, abs(offset(3, 4, time).y))
        }
        #expect(peak > 0.5 && peak <= 0.9 + 1e-9)
        let overlay = try #require(heat.overlay)
        let cool: MosaicTriple = (0.2, 0.3, 0.9)
        let warmed = overlay(4, 4, 1, cool)
        #expect(warmed.red > cool.red && warmed.blue < cool.blue)
    }

    @Test func textBecomesTilesAndTheWordsKeepTheirApps() {
        let words = [MosaicAnnounceWord(text: "Push A", app: .training), MosaicAnnounceWord(text: "at 7", app: nil)]
        let raster = MosaicText.raster(words: words)
        #expect(raster.width > 20)
        var on = 0
        for column in 0 ..< raster.width {
            for row in 0 ..< MosaicText.rows where raster.on(column, row) {
                on += 1
            }
        }
        #expect(on > 30)
        #expect(raster.word(at: 0) == 0)
        #expect(raster.word(at: raster.width - 1) == 1)
        // The crawl takes the text's width plus the window at 15 tiles a second, and a breath.
        let seconds = MosaicText.crawlSeconds(words: words, columns: 62)
        #expect(abs(seconds - (Double(raster.width + 62) / 15 + 0.4)) < 1e-9)
    }

    @Test func anAnnouncementStepsTheMoodBackAndCrawlsRightToLeft() throws {
        let words = [MosaicAnnounceWord(text: "Push A", app: .training)]
        var context = MosaicMoodContext()
        context.accents[.training] = (1, 0, 0)
        context.ink = (0, 0, 0)
        let announce = plan(.announce(words: words), context: context)
        let base = try #require(announce.base)
        // 55% of the way to white: brighter than the field under it.
        #expect(base[0].red > 0.4 + 0.2)
        let overlay = try #require(announce.overlay)
        let background: MosaicTriple = (0.7, 0.7, 0.7)
        // At t = 0 the text is off the right edge; later it has crawled in and some tile takes the accent.
        var seenAtStart = false, seenLater = false
        for column in 0 ..< 62 {
            for row in 0 ..< 22 {
                if overlay(column, row, 0, background).red != background.red {
                    seenAtStart = true
                }
                if overlay(column, row, 2, background).red != background.red {
                    seenLater = true
                }
            }
        }
        #expect(!seenAtStart)
        #expect(seenLater)
    }

    @Test func tessHasTwoEyesAndOnlyEyes() {
        let open = MosaicMomentField.eyeTiles(cols: 40, rows: 24, time: 1.0)
        #expect(open.count == 20)
        let blink = MosaicMomentField.eyeTiles(cols: 40, rows: 24, time: 2.9 + 0.05)
        #expect(blink.count == 4)
        let columns = Set(open.map { $0 / 24 })
        #expect(columns.min() ?? 0 >= 40 * 4 / 10 - 3 && columns.max() ?? 0 <= 40 * 6 / 10 + 3)
        let rows = Set(open.map { $0 % 24 })
        #expect(rows.count == 5)
    }

    @Test func tessStepsTheMoodBackHalfwayAndGathers() throws {
        let tess = plan(.tess)
        #expect(tess.transition == .gather)
        let base = try #require(tess.base)
        #expect(abs(base[0].red - (0.4 + (1 - 0.4) * 0.5)) < 1e-9)
    }

    @Test func theTimerPulsesInSquaresAndHoldsItsCentre() {
        #expect(MosaicMomentField.timerStrength(column: 15, row: 15, cols: 32, rows: 32, time: 0) == 1)
        #expect(MosaicMomentField.timerStrength(column: 16, row: 16, cols: 32, rows: 32, time: 99) == 1)
        // A pulse 0.6 s old has a square ring: tiles at equal Chebyshev distance share strength, a diagonal and an axis
        // tile alike.
        let axis = MosaicMomentField.timerStrength(column: 15, row: 8, cols: 32, rows: 32, time: 0.6)
        let corner = MosaicMomentField.timerStrength(column: 8, row: 8, cols: 32, rows: 32, time: 0.6)
        #expect(axis > 0 && corner > 0 && abs(axis - corner) < 1e-9)
        // Long after the third pulse only the centre is left.
        #expect(MosaicMomentField.timerStrength(column: 15, row: 4, cols: 32, rows: 32, time: 4) == 0)
    }

    @Test func theSparkleGrowsOneRingPerNinetyMillisecondsToThree() {
        #expect(MosaicMomentField.sparkleRing(age: -0.1) == 0)
        #expect(MosaicMomentField.sparkleRing(age: 0.0) == 1)
        #expect(MosaicMomentField.sparkleRing(age: 0.1) == 2)
        #expect(MosaicMomentField.sparkleRing(age: 0.19) == 3)
        #expect(MosaicMomentField.sparkleRing(age: 5) == 3)
    }

    @Test func theSparkleRingsSurroundTheLandedTileAndFade() {
        let sparkle = MosaicMomentField.sparkleLight(landing: (20, 15), colour: (1, 0, 0), start: 0)
        let field: MosaicTriple = (0, 0, 0)
        // Before the tile lands (0.7 s) nothing; 0.1 s after, ring 1 and 2 light up but not ring 3 or the centre.
        #expect(sparkle(21, 15, 0.5, field).red == 0)
        #expect(sparkle(21, 15, 0.8, field).red > 0)
        #expect(sparkle(22, 17, 0.8, field).red > 0)
        #expect(sparkle(23, 15, 0.8, field).red == 0)
        #expect(sparkle(20, 15, 0.8, field).red == 0)
        // A square ring: an axis tile and a corner tile at the same Chebyshev distance light equally.
        #expect(abs(sparkle(21, 15, 0.8, field).red - sparkle(21, 16, 0.8, field).red) < 1e-9)
        // Three rings by 0.19 s, gone after a second.
        #expect(sparkle(23, 15, 0.9, field).red > 0)
        #expect(sparkle(21, 15, 1.9, field).red == 0)
    }

    @Test func aMeltDripsTheOldTileWhileTheMoodsTileGrowsUnderIt() {
        let engine = MosaicEngine(config: .moods, width: 248)
        engine.snapWindow()
        let before = [MosaicTriple](repeating: (1, 0, 0), count: engine.config.count)
        let after = [MosaicTriple](repeating: (0, 0, 1), count: engine.config.count)
        engine.settle(to: before)
        engine.morph(to: after, origin: (0, 0), melt: true)
        #expect(engine.melting)
        // Mid-melt a tile has its old colour dripping (below its place, shrunk) and the new one smaller than full.
        let delay = MosaicColour.unit(30, salt: 91) * 0.42 + 0.018 * 10
        engine.step(to: delay + 0.26)
        let ghost = engine.meltGhost(column: 30, row: 10)
        #expect(ghost != nil)
        #expect((ghost?.colour.red ?? 0) == 1)
        #expect((ghost?.offset.y ?? 0) > 0)
        #expect((ghost?.scale ?? 1) < 1 && (ghost?.scale ?? 0) >= 0.3)
        #expect(engine.scale(column: 30, row: 10) < 1.1)
        // A column that starts later has not begun; after it all ends, no ghost is left and the mood is showing.
        engine.step(to: 3)
        #expect(engine.meltGhost(column: 30, row: 10) == nil)
        #expect(engine.colour(column: 30, row: 10, nowColumn: nil).blue > 0.9)
    }

    @Test func aMeltStartsEachColumnAtHashTimesFourHundredTwentyPlusEighteenPerRow() {
        let engine = MosaicEngine(config: .moods, width: 248)
        engine.snapWindow()
        let colours = [MosaicTriple](repeating: (0, 0, 0), count: engine.config.count)
        engine.settle(to: colours)
        engine.morph(to: colours, origin: (0, 0), melt: true)
        engine.step(to: 0.005)
        // Nothing has started in a column whose hash start is later than 5 ms and row 20.
        #expect(engine.meltGhost(column: 5, row: 39) == nil)
    }

    /// The per-tile work of a frame (colour, scale, offset on every tile of the full 62 x 40 grid) for the heaviest
    /// moments, so a slow closure shows up here before it shows up on the phone.
    @Test func aFrameOfTheHeaviestMomentsCostsLittle() {
        let engine = MosaicEngine(config: .moods, width: 248)
        engine.snapWindow()
        let config = engine.config
        for moment in [MosaicMoment.storm, .wind, .snow, .fog, .heat] {
            let window = moment.window ?? (50, 28)
            let plan = MosaicMomentField.plan(moment, under: under(window.columns, window.rows), window: window,
                                              ground: ground, context: MosaicMoodContext(), start: 0,
                                              reduceMotion: false)
            let started = ContinuousClock.now
            let frames = 30
            for frame in 0 ..< frames {
                engine.step(to: Double(frame) / 60)
                var sum = 0.0
                for column in 0 ..< config.columns {
                    for row in 0 ..< config.rows {
                        // The moment's closures see window-local tiles (the controller clamps), so drive them with
                        // the window's own coordinates.
                        let local = (min(column, window.columns - 1), min(row, window.rows - 1))
                        sum += (plan.overlay?(local.0, local.1, Double(frame) / 60, (0.5, 0.5, 0.5)).red ?? 0)
                        sum += engine.colour(column: column, row: row, nowColumn: 20).red
                        sum += Double(engine.scale(column: column, row: row))
                        sum += Double(engine.offset(column: column, row: row).x)
                    }
                }
                #expect(sum.isFinite)
            }
            let elapsed = started.duration(to: ContinuousClock.now)
            let milliseconds = Double(elapsed.components.seconds) * 1000 + Double(elapsed.components.attoseconds) / 1e15
            // 60 fps leaves 16 ms a frame for everything; the tile work alone should stay near 12 ms, and fails only at
            // twice that.
            #expect(milliseconds / Double(frames) < 24, "\(moment) took \(milliseconds / Double(frames)) ms a frame")
        }
    }

    @Test func aFinishedMomentKeepsTheMoodField() {
        let finished = plan(.finished(tone: .glaze))
        #expect(finished.base == nil)
    }

    @Test func reduceMotionShowsAStillFrame() {
        for moment in [MosaicMoment.snow, .fog, .wind, .storm, .heat, .tess, .timer] {
            let still = plan(moment, reduceMotion: true)
            #expect(still.scale == nil && still.offset == nil)
        }
        // The timer's centre is held and Tess's eyes are open, with no motion.
        let timer = plan(.timer, reduceMotion: true)
        #expect(timer.overlay != nil)
        let tess = plan(.tess, reduceMotion: true)
        #expect(tess.overlay != nil)
        let wind = plan(.wind, reduceMotion: true)
        #expect(wind.overlay == nil && wind.offset == nil)
    }

    @Test func theEngineAppliesAMomentsSwayAndSwell() {
        let engine = MosaicEngine(config: .moods, width: 248)
        engine.scaleHook = { _, _, _ in 0.5 }
        engine.offsetHook = { _, _, _ in CGPoint(x: 1.5, y: -0.9) }
        engine.snapWindow()
        #expect(engine.offset(column: 30, row: 20).x == 1.5)
        #expect(engine.scale(column: 30, row: 20) < 0.8)
        engine.scaleHook = nil
        engine.offsetHook = nil
        #expect(engine.offset(column: 30, row: 20) == .zero)
    }

    @Test func aLayAtAChosenRowLandsThere() {
        let engine = MosaicEngine(config: .moods, width: 248)
        engine.reduceMotion = true
        let row = Int(Double(28) * 0.62)
        #expect(engine.lay(from: .zero, side: 10, column: 40, tone: .glaze, row: row))
        #expect(engine.laid.first?.index == 40 * 40 + row)
    }

    @Test func theMomentsSwitchIsOffAndNeedsMoods() {
        #expect(MosaicMomentsSwitch.choiceID == "homeMosaicMoments")
        #expect(ReviewChoices.all.first { $0.id == "homeMosaicMoments" }?.defaultValue == "Off")
    }
}
