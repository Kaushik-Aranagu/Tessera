import CoreGraphics
@testable import Tessera
import Testing

/// Sheet 230: the shared wheel's feel is pinned here (rows, flicks, spring-back, the scrolling number, the blur).
struct WheelLogicTests {
    private let range = 0 ... 6

    @Test func theFocusedRowSitsAtZeroAndTheOthersStandClear() {
        let style = WheelStyle.plan
        #expect(style.offset(at: 0) == 0)
        #expect(style.offset(at: 1) == CGFloat(46))
        #expect(style.offset(at: -1) == CGFloat(-46))
        #expect(style.offset(at: 2) == CGFloat(84))
    }

    @Test func sizesFollowTheSheet() {
        #expect(WheelStyle.plan.size(at: 0) == 30)
        #expect(WheelStyle.plan.size(at: 1) == 20)
        #expect(WheelStyle.plan.size(at: 2) == 17)
        #expect(WheelStyle.plan.size(at: 3) == 15)
        #expect(WheelStyle.plan.size(at: 9) == 15)
        #expect(WheelStyle.session.size(at: 0) == 22)
        #expect(WheelStyle.session.size(at: 1) == 16)
        #expect(WheelStyle.session.size(at: 2) == 14)
        #expect(WheelStyle.session.pitch == 34)
        #expect(WheelStyle.session.visibleRows == 5)
    }

    @Test func accessibilitySizesShowThreeRows() {
        #expect(WheelStyle.plan.rows(accessibility: false) == 5)
        #expect(WheelStyle.plan.rows(accessibility: true) == 3)
    }

    @Test func aWindowBuildsOnlyWhatShows() {
        let window = WheelMath.window(position: 50, visibleRows: 5, in: 0 ... 399)
        #expect(window.count <= 9)
        #expect(window.contains(50))
    }

    @Test func aHoldScrollTracksTheFinger() {
        #expect(WheelMath.position(start: 2, translation: -38, pitch: 38, in: range) == 3)
        #expect(WheelMath.position(start: 2, translation: 19, pitch: 38, in: range) == 1.5)
    }

    @Test func theEndsGiveALittle() {
        let past = WheelMath.position(start: 0, translation: 400, pitch: 38, in: range)
        #expect(past < 0 && past >= -0.5)
    }

    @Test func aFlickMovesExactlyOneRow() {
        let up = WheelMath.release(position: 2.0 + 30.0 / 38, translation: -30, velocity: -900, pitch: 38, in: range)
        #expect(up == 3)
        let hard = WheelMath.release(position: 2.0 + 30.0 / 38, translation: -30, velocity: -9000, pitch: 38, in: range)
        #expect(hard == 3)
        let down = WheelMath.release(position: 2.0 - 30.0 / 38, translation: 30, velocity: 2000, pitch: 38, in: range)
        #expect(down == 1)
    }

    @Test func aSlowDragSnapsToTheNearestRow() {
        #expect(WheelMath.release(position: 2.4, translation: -15, velocity: -100, pitch: 38, in: range) == 2)
        #expect(WheelMath.release(position: 2.6, translation: -23, velocity: -100, pitch: 38, in: range) == 3)
    }

    @Test func aTwitchIsNotAFlick() {
        #expect(WheelMath.release(position: 2.2, translation: -8, velocity: -3000, pitch: 38, in: range) == 2)
    }

    @Test func aReleaseStaysInsideTheRange() {
        #expect(WheelMath.release(position: 6, translation: -30, velocity: -2000, pitch: 38, in: range) == 6)
        #expect(WheelMath.release(position: 0, translation: 30, velocity: 2000, pitch: 38, in: range) == 0)
    }

    @Test func theWheelComesHomeSixSecondsAfterTheLastTouch() {
        var home = WheelHome()
        #expect(!home.shouldReturn(at: 100, fingerDown: false, paused: false, away: true))
        home.touched(at: 100)
        #expect(!home.shouldReturn(at: 105.9, fingerDown: false, paused: false, away: true))
        #expect(home.shouldReturn(at: 106, fingerDown: false, paused: false, away: true))
        home.touched(at: 105)
        #expect(!home.shouldReturn(at: 106, fingerDown: false, paused: false, away: true))
    }

    @Test func aFingerAPageOrVoiceOverHoldsItAway() {
        var home = WheelHome()
        home.touched(at: 0)
        #expect(!home.shouldReturn(at: 60, fingerDown: true, paused: false, away: true))
        #expect(!home.shouldReturn(at: 60, fingerDown: false, paused: true, away: true))
        #expect(!home.shouldReturn(at: 60, fingerDown: false, paused: false, away: false))
    }

    @Test func sixteenPointsIsOneStep() {
        let range = 0.0 ... 600
        #expect(NumberScroll.value(start: 185, translation: -16, step: 5, in: range) == 190)
        #expect(NumberScroll.value(start: 185, translation: -15, step: 5, in: range) == 185)
        #expect(NumberScroll.value(start: 185, translation: 48, step: 5, in: range) == 170)
    }

    @Test func weightStepsByFiveLbOrTwoAndAHalfKg() {
        #expect(NumberScroll.weightStep(poundsUnit: true) == 5)
        #expect(NumberScroll.weightStep(poundsUnit: false) == 2.5)
    }

    @Test func aNumberStaysInItsRange() {
        let range = 0.0 ... 15
        #expect(NumberScroll.value(start: 14, translation: -160, step: 1, in: range) == 15)
        #expect(NumberScroll.value(start: 1, translation: 160, step: 1, in: range) == 0)
        #expect(NumberScroll.stepped(0, by: -1, step: 1, in: range) == 0)
    }

    @Test func theDialListsEveryStep() {
        #expect(NumberScroll.values(in: 0 ... 10, step: 2.5) == [0, 2.5, 5, 7.5, 10])
    }

    @Test func blurIsSixtyFiveHundredthsThenOne() {
        #expect(WheelDepth.radius(away: 0) == 0)
        #expect(WheelDepth.radius(away: 1) == 0.65)
        #expect(WheelDepth.radius(away: -1) == 0.65)
        #expect(WheelDepth.radius(away: 2) == 1)
        #expect(WheelDepth.radius(away: -7) == 1)
    }

    @Test func noBlurWhenAnythingAsksForLess() {
        func blur(on: Bool = true, motion: Bool = false, transparency: Bool = false, power: Bool = false) -> Double {
            Double(WheelDepth.blur(away: 2, enabled: on, reduceMotion: motion, reduceTransparency: transparency,
                                   lowPower: power))
        }
        #expect(blur() == 1)
        #expect(blur(on: false) == 0)
        #expect(blur(motion: true) == 0)
        #expect(blur(transparency: true) == 0)
        #expect(blur(power: true) == 0)
    }
}
