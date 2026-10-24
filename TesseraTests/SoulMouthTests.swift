import Foundation
@testable import Tessera
import Testing

/// Her mouth (sheet 215 rev 19, F5): three meanings, drawn out from the middle, never a fade, never a frown.
struct SoulMouthTests {
    @Test func aSmileAndAnOhPassAndASlantStaysUntilSheIsAnswered() {
        #expect(SoulMouth.smile.seconds == 1.1 && SoulMouth.oh.seconds == 0.8 && SoulMouth.slant.seconds == nil)
        #expect(SoulMouth.smile.drawn(since: 0) == 0)
        #expect(SoulMouth.smile.drawn(since: 0.15) == 1)
        #expect(SoulMouth.smile.drawn(since: 1.1) == 0)
        #expect(SoulMouth.slant.drawn(since: 500) == 1)
    }

    @Test func itDrawsOutFromItsMiddleAndBackIn() {
        let early = SoulMouth.smile.drawn(since: 0.05), late = SoulMouth.smile.drawn(since: 1.0)
        #expect(early > 0 && early < 1 && late > 0 && late < 1)
    }

    @Test func theSlantIsAGentleTiltUpToTheRightNeverAFrown() {
        let path = SoulMouthShape(kind: .slant, drawn: 1).path(in: CGRect(x: 0, y: 0, width: 8, height: 4))
        let box = path.boundingRect
        #expect(box.width > 3 && box.height < 1.6)
        // Its right end sits higher than its left: a half-smile.
        let first = path.cgPath.currentPoint
        #expect(first.y < 2)
    }

    @Test func aSmileCurvesDownwardInTheMiddleLikeASmile() {
        let path = SoulMouthShape(kind: .smile, drawn: 1).path(in: CGRect(x: 0, y: 0, width: 8, height: 4))
        #expect(path.boundingRect.maxY > 2.0)
    }
}

/// At the phone's size (0.7 of the board): the eyes stay about 3 pt across and the mouth's line 1 pt on screen.
@MainActor
struct SoulSizeFloorsTests {
    private func eyes() -> SoulEyes {
        SoulEyes(frame: SoulFrame.sample(.idle, time: 4.2, elapsed: 0), time: 0, gaze: .ahead, color: .black)
    }

    @Test func theEyesStayAtLeastThreePointsAcrossOnTheScreen() {
        for unit in [CGFloat(0.5), 1, 1.4] {
            #expect(eyes().eyeSize(unit: unit).width * unit * 0.7 >= 3 - 1e-6)
        }
        #expect(eyes().eyeSize(unit: 1).width >= SoulEyes.size.width)
    }

    @Test func theMouthLineStaysAtLeastOnePointOnTheScreen() {
        for unit in [CGFloat(0.5), 1, 1.4] {
            #expect(eyes().mouthWidth(unit: unit) * unit * 0.7 >= 1 - 1e-6)
        }
    }
}
