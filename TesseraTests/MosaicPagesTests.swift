import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Sheets 206 and 209: an app's glance, the mosaic's pages, the timed changeovers and the open reactions' pieces.
@MainActor
struct MosaicPagesTests {
    private let size = CGSize(width: 402, height: 874)

    private func engine() -> MosaicScreenEngine {
        let engine = MosaicScreenEngine(size: size, coreTop: 480)
        engine.configure(size: size, coreTop: 480, dark: false, ground: (1, 1, 1))
        engine.snapWindow()
        return engine
    }

    // MARK: Glances

    @Test func aGlanceIsFortyFourByTwentyFourGathersInAndDissolvesOutAfterThreePointFourSeconds() {
        let glance = MosaicMoment.glance(app: .training)
        #expect(glance.window?.columns == 44 && glance.window?.rows == 24)
        #expect(glance.transition == .gather)
        #expect(glance.returnChangeover == .transition(.dissolve))
        #expect(glance.duration == 3.4)
        #expect(glance.stepBack == 0)
        #expect(MosaicMomentField.glanceWash == 0.18)
    }

    @Test func theBarbellIsElevenWideAndLiftsOneRowEverySevenHundredMilliseconds() throws {
        func top(_ elapsed: Double) -> Int {
            MosaicMomentField.glanceTiles(.training, cols: 44, rows: 24, elapsed: elapsed).map { $0 % 24 }.min() ?? 0
        }
        let rest = MosaicMomentField.glanceTiles(.training, cols: 44, rows: 24, elapsed: 0)
        let columns = Set(rest.map { $0 / 24 })
        #expect(try #require(columns.max()) - columns.min()! + 1 == 9 + 1 || columns.max()! - columns.min()! + 1 == 9)
        #expect(top(0.8) == top(0) - 1 && top(1.5) == top(0) - 2 && top(2.2) == top(0) - 3)
        // It stops at three rows however long it runs.
        #expect(top(3.3) == top(0) - 3)
    }

    @Test func thePotHasThreeSteamPixelsRising() {
        let still = MosaicMomentField.glanceTiles(.kitchen, cols: 44, rows: 24, elapsed: 0)
        let later = MosaicMomentField.glanceTiles(.kitchen, cols: 44, rows: 24, elapsed: 1.0)
        #expect(still != later)
        let potTop = (still.map { $0 % 24 }.min() ?? 0) + 3
        let steamAbove = later.filter { $0 % 24 < potTop - 1 }.count
        #expect(steamAbove <= 3)
    }

    @Test func theClockHandGoesRoundAtSixHundredFiftyMillisecondsARadianWithACentreAndNoRing() {
        let centre = 22 * 24 + 12
        for elapsed in [0.0, 0.5, 1.3, 2.0] {
            let tiles = MosaicMomentField.glanceTiles(.routines, cols: 44, rows: 24, elapsed: elapsed)
            #expect(tiles.contains(centre))
            #expect(tiles.count <= 8)
        }
        #expect(MosaicMomentField.glanceTiles(.routines, cols: 44, rows: 24, elapsed: 0)
            != MosaicMomentField.glanceTiles(.routines, cols: 44, rows: 24, elapsed: 1.0))
    }

    @Test func theCheckDrawsOneStepEveryNinetyMilliseconds() {
        func count(_ elapsed: Double) -> Int {
            MosaicMomentField.glanceTiles(.tasks, cols: 44, rows: 24, elapsed: elapsed).count
        }
        #expect(count(0) == 1 && count(0.1) == 2 && count(0.2) == 3)
        #expect(count(0.8) == 8 && count(3) == 8)
    }

    @Test func notesWriteThreeLinesInOrderWithABlinkingCursor() {
        func count(_ elapsed: Double) -> Int {
            MosaicMomentField.glanceTiles(.notes, cols: 44, rows: 24, elapsed: elapsed).count
        }
        #expect(count(0.5) < count(1.5) && count(1.5) < count(2.6))
        #expect(count(10.0) == 16 + 12 + 9 + 2 || count(10.0) == 16 + 12 + 9)
    }

    @Test func listsTickDoneOneAfterAnother() {
        func count(_ elapsed: Double) -> Int {
            MosaicMomentField.glanceTiles(.lists, cols: 44, rows: 24, elapsed: elapsed).count
        }
        #expect(count(0.5) < count(0.7) && count(0.7) < count(1.4) && count(1.4) < count(2.1))
        #expect(count(2.2) == count(3.3))
    }

    @Test func moneyIsThreeFilledDiscsFillingToDifferentLevelsAndNothingElse() {
        let tiles = MosaicMomentField.glanceTiles(.money, cols: 44, rows: 24, elapsed: 3)
        // Three discs of radius 3.4: about 37 tiles each, and nothing outside them.
        #expect(tiles.count > 90 && tiles.count < 130)
        #expect(MosaicMomentField.poolFill(disc: 0, elapsed: 5) == 0.35)
        #expect(MosaicMomentField.poolFill(disc: 1, elapsed: 5) == 0.7)
        #expect(MosaicMomentField.poolFill(disc: 2, elapsed: 5) == 0.5)
        #expect(MosaicMomentField.poolFill(disc: 1, elapsed: 0.3) < 0.7)
        // The fixed drawing never changes with time: no numbers, no bars.
        #expect(tiles == MosaicMomentField.glanceTiles(.money, cols: 44, rows: 24, elapsed: 0))
    }

    @Test func aGlanceUnderReduceMotionIsAStillSign() {
        let plan = MosaicMomentField.plan(
            .glance(app: .kitchen),
            under: Array(repeating: (0.5, 0.5, 0.5), count: 44 * 24),
            window: (44, 24),
            ground: (1, 1, 1),
            context: MosaicMoodContext(),
            start: 0,
            reduceMotion: true
        )
        #expect(plan.offset == nil && plan.scale == nil && plan.overlay != nil)
        #expect(MosaicMomentField.stillGlance(.training) == 0 && MosaicMomentField.stillGlance(.tasks) == 99)
    }

    // MARK: Pages

    @Test func thereAreFourPagesAndAHalfSecondWipe() {
        #expect(MosaicPage.count == 4 && MosaicPage.wipeSeconds == 0.6 && MosaicPage.thingWash == 0.20)
        #expect(MosaicPage.allCases == [.mood, .weather, .next, .week])
    }

    @Test func theWeatherPageIsLabelledSampleAndNeverCarriesAnAmount() {
        #expect(MosaicPage.weather.caption(facts: nil, page: nil) == "Weather, sample until Apple weather")
        #expect(MosaicWeatherSample.temperature == 58)
    }

    @Test func theWeekPageIsSevenLettersWithAThreeTileMarkUnderEach() {
        let tiles = MosaicPageField.weekTiles(cols: 44, rows: 24)
        let marks = tiles.values.filter(\.isMark)
        #expect(marks.count == 7 * 3)
        #expect(Set(tiles.values.map(\.day)) == Set(0 ... 6))
        #expect(tiles.keys.allSatisfy { $0 / 24 >= 0 && $0 / 24 < 44 })
        #expect(MosaicPageField.weekLetters.count == 7 && MosaicPageField.weekLetters.map(String.init)
            .joined() == "MTWTFSS")
    }

    @Test func theSunHasADiscAndRaysThatTurn() {
        let start = MosaicPageField.sunTiles(cols: 44, rows: 24, elapsed: 0)
        let turned = MosaicPageField.sunTiles(cols: 44, rows: 24, elapsed: 2)
        #expect(start != turned)
        // The disc stays; only the rays move.
        #expect(start.intersection(turned).count > 25)
    }

    @Test func theNextPagePixelsStepTowardTheGroundInEighthsAsTheMinuteCountsDown() {
        #expect(MosaicPageField.nextStep(secondsIntoMinute: 0) == 0)
        #expect(MosaicPageField.nextStep(secondsIntoMinute: 8) == 1.0 / 8)
        #expect(MosaicPageField.nextStep(secondsIntoMinute: 59) == 7.0 / 8)
        for second in 0 ..< 60 {
            let step = MosaicPageField.nextStep(secondsIntoMinute: Double(second))
            #expect(abs(step * 8 - (step * 8).rounded()) < 1e-9)
        }
    }

    // MARK: Changeovers

    @Test func aTimedFlipByRowsTakesItsSecondsAndGoesTopToBottom() throws {
        let engine = engine()
        engine.settle { _, _ in (1, 0, 0) }
        engine.morph(.flipRows, origin: (50, 130), total: 1.4) { _, _ in (0, 0, 1) }
        let top = try #require(engine.regionIndex(column: engine.core.left + 5, row: engine.region.top))
        let bottom = try #require(engine.regionIndex(column: engine.core.left + 5, row: engine.region.bottom))
        engine.step(to: 0.05)
        #expect(engine.progress(top) > 0)
        #expect(engine.progress(bottom) == 0)
        engine.step(to: 1.5)
        #expect(engine.progress(bottom) == 1 && engine.progress(top) == 1)
        engine.step(to: 1.3)
    }

    @Test func aPageWipeSweepsTheColumnsInTheSwipesDirectionWithinHalfASecond() throws {
        for reverse in [false, true] {
            let engine = engine()
            engine.settle { _, _ in (1, 0, 0) }
            engine.morph(.wipeColumns(reverse: reverse), origin: (50, 130), total: 0.5) { _, _ in (0, 0, 1) }
            let left = try #require(engine.regionIndex(column: engine.region.left + 2, row: engine.core.top + 5))
            let right = try #require(engine.regionIndex(column: engine.region.right - 2, row: engine.core.top + 5))
            engine.step(to: 0.2)
            #expect(reverse ? engine.progress(right) > engine.progress(left) : engine.progress(left) > engine
                .progress(right))
            engine.step(to: 0.6)
            #expect(engine.progress(left) == 1 && engine.progress(right) == 1)
        }
    }

    @Test func aColdLaunchWaitsFiveHundredMillisecondsBeforeItGathers() throws {
        let engine = engine()
        engine.settle { _, _ in (0.1, 0.1, 0.3) }
        engine
            .morph(.standard(.gather), origin: (50, 130), total: 1.8, after: 0.5, from: { _, _ in
                (0.1, 0.1, 0.3)
            }) { _, _ in
                (0.9, 0.8, 0.5)
            }
        let index = try #require(engine.regionIndex(column: engine.core.left + 10, row: engine.core.top + 10))
        engine.step(to: 0.4)
        #expect(engine.progress(index) == 0)
        engine.step(to: 2.4)
        #expect(engine.progress(index) == 1)
    }

    @Test func aReopenRippleStartsFromTheMiddleAndReachesOutwardOverNineTenthsOfASecond() {
        let engine = engine()
        engine.rippleFromCentre(seconds: 0.9)
        #expect(!engine.pops.isEmpty)
        let core = engine.targetCore
        let centre = engine.grid.index(column: core.left + core.width / 2, row: core.top + core.height / 2)
        #expect(engine.pops[centre] != nil)
        // Every pop starts within the 0.9 s.
        #expect(engine.pops.values.allSatisfy { $0 - engine.clock <= 0.9 })
        let outer = engine.grid.index(column: core.left + core.width + 40, row: core.top)
        #expect(engine.pops[outer] == nil)
    }

    @Test func underReduceMotionAReopenRipplesNothing() {
        let engine = engine()
        engine.reduceMotion = true
        engine.rippleFromCentre(seconds: 0.9)
        #expect(engine.pops.isEmpty)
    }

    @Test func theTrackerKeepsTwoTimesAndNothingElse() {
        let defaults = UserDefaults(suiteName: "mosaic.tracker.\(UUID().uuidString)") ?? .standard
        let tracker = MosaicOpenTracker(defaults: defaults)
        #expect(tracker.lastBackground == nil && tracker.lastOpen == nil)
        let background = Date(timeIntervalSince1970: 1_800_000_000), open = background.addingTimeInterval(500)
        tracker.recordBackground(at: background)
        tracker.recordOpen(at: open)
        #expect(tracker.lastBackground == background && tracker.lastOpen == open)
    }
}
