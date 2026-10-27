import CoreGraphics
@testable import Tessera
import Testing

/// Sheet 296, things in flight.
@MainActor
struct FlightMoveTests {
    /// The Log wall (keystone) to the widget: a word flies down the screen past the caption.
    private let frames: [Place: CGRect] = [
        .keystone: CGRect(x: 24, y: 196, width: 354, height: 182),
        .caption: CGRect(x: 24, y: 378, width: 354, height: 34),
        .widget: CGRect(x: 24, y: 412, width: 354, height: 200),
        .glyph: CGRect(x: 298, y: 444, width: 80, height: 80),
        .dial: CGRect(x: 218, y: 640, width: 160, height: 120),
        .title: CGRect(x: 24, y: 50, width: 260, height: 48),
    ]

    private var route: FlightRoute {
        FlightRoute(path: [CGPoint(x: 100, y: 300), CGPoint(x: 100, y: 500)], size: CGSize(width: 60, height: 24),
                    source: .keystone, landing: .widget)
    }

    @Test func aCrossedPlaceStepsBackToTwentyEightPercentInTheFirstFourPercent() {
        #expect(FlightMove.placeOpacity(at: 0) == 1)
        #expect(abs(FlightMove.placeOpacity(at: 0.04) - 0.28) < 0.0001)
        #expect(abs(FlightMove.placeOpacity(at: 0.5) - 0.28) < 0.0001)
        #expect(FlightMove.placeOpacity(at: 0.02) < 1 && FlightMove.placeOpacity(at: 0.02) > 0.28)
    }

    @Test func itReturnsOverTheLastTwentyPercent() {
        #expect(abs(FlightMove.placeOpacity(at: 0.8) - 0.28) < 0.0001)
        #expect(FlightMove.placeOpacity(at: 0.9) > 0.28 && FlightMove.placeOpacity(at: 0.9) < 1)
        #expect(FlightMove.placeOpacity(at: 1) == 1)
    }

    @Test func theCaptionIsCrossedButTheLandingAndTheSourceAreNot() {
        let crossed = FlightMove.crossed(route, frames: frames)
        #expect(crossed.contains(.caption))
        #expect(!crossed.contains(.widget), "the landing place does not step back")
        #expect(!crossed.contains(.keystone), "the source is being left")
    }

    @Test func aPlaceWithinFortyEightPointsOfThePathIsCrossedAndOneBeyondIsNot() {
        // The glyph's left edge is at 298; the path is at x = 100 with a 30 pt half-width: 298 - 78 = 220 away.
        let near = FlightRoute(
            path: [CGPoint(x: 230, y: 300), CGPoint(x: 230, y: 500)],
            size: CGSize(width: 60, height: 24),
            source: .keystone,
            landing: .widget
        )
        #expect(FlightMove.crossed(near, frames: frames).contains(.glyph), "within the margin")
        #expect(!FlightMove.crossed(route, frames: frames).contains(.glyph), "far enough away")
        #expect(!FlightMove.crossed(route, frames: frames).contains(.title))
    }

    @Test func noTwoPlacesCrossWhileBothAreAboveFortyPercent() {
        for step in 0 ... 100 {
            let t = Double(step) / 100
            #expect(FlightMove.collisions(route, frames: frames, at: t).isEmpty, "t = \(t)")
        }
    }

    @Test func aWordIsOpaqueThroughoutAndAPaperCopyFadesOnlyAfterItClearsItsSource() {
        let source = frames[.keystone] ?? .zero
        #expect(FlightMove.copyOpacity(route, source: source, at: 0.5) == 1)
        var ticket = route
        ticket.hasOwnGround = true
        let clear = FlightMove.clearTime(ticket, source: source)
        #expect(clear > 0 && clear < 1)
        #expect(FlightMove.copyOpacity(ticket, source: source, at: clear * 0.5) == 1, "opaque while leaving")
        #expect(FlightMove.copyOpacity(ticket, source: source, at: clear) == 1)
        let later = FlightMove.copyOpacity(ticket, source: source, at: (clear + 1) / 2)
        #expect(later < 1 && later > 0)
        #expect(FlightMove.copyOpacity(ticket, source: source, at: 1) == 0)
    }

    @Test func theCopyFollowsItsPathByLength() {
        let start = FlightMove.centre(route, at: 0)
        let mid = FlightMove.centre(route, at: 0.5)
        let end = FlightMove.centre(route, at: 1)
        #expect(start == CGPoint(x: 100, y: 300))
        #expect(mid == CGPoint(x: 100, y: 400))
        #expect(end == CGPoint(x: 100, y: 500))
    }

    @Test func theFlightEndsWithinOneSecond() {
        #expect(FlightMove.duration <= 1)
    }

    @Test func reduceMotionFliesNothingAndHandsStraightOver() {
        let runner = FlightRunner()
        var landed = false
        runner.fly(route, frames: frames, reduceMotion: true) { landed = true }
        #expect(landed)
        #expect(runner.route == nil)
        #expect(runner.crossed.isEmpty)
    }

    @Test func anUnseenFlightDrawsNothing() {
        let runner = FlightRunner()
        var landed = false
        runner.fly(route, frames: frames, reduceMotion: false, isShown: false) { landed = true }
        #expect(landed)
        #expect(runner.route == nil)
    }
}
