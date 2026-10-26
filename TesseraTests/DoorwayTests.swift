import CoreGraphics
import Foundation
@testable import Tessera
import Testing

/// Sheets 206 and 211: the pixel doorway's wave.
struct DoorwayTests {
    private let size = CGSize(width: 402, height: 874)
    private let origin = CGPoint(x: 220, y: 330)

    @Test func theWaveSpreadsAtThreeQuartersOfAMillisecondPerPointWithAtMostThirtyPointsOfJitter() {
        let near = DoorwayWave.delay(column: 55, row: 82, origin: origin, reach: 700, reverse: false)
        let far = DoorwayWave.delay(column: 0, row: 218, origin: origin, reach: 700, reverse: false)
        #expect(near < far)
        // Two tiles on the same ring differ only by their jitter: at most 30 pt, 22.5 ms.
        let one = DoorwayWave.delay(column: 80, row: 82, origin: origin, reach: 700, reverse: false)
        let two = DoorwayWave.delay(column: 81, row: 82, origin: origin, reach: 700, reverse: false)
        #expect(abs(one - two) < 4 * 0.00075 + 0.0226)
        #expect((0 ..< 200).allSatisfy { DoorwayWave.jitter(column: $0, row: 3) < 1 })
    }

    @Test func backRunsTheSameWaveInReverseFromTheFarCornerIn() {
        let reach = DoorwayWave.reach(size: size, origin: origin)
        let nearForward = DoorwayWave.delay(column: 55, row: 82, origin: origin, reach: reach, reverse: false)
        let nearReverse = DoorwayWave.delay(column: 55, row: 82, origin: origin, reach: reach, reverse: true)
        #expect(nearForward < nearReverse)
        let farReverse = DoorwayWave.delay(column: 0, row: 218, origin: origin, reach: reach, reverse: true)
        #expect(farReverse < nearReverse)
    }

    @Test func aTileTurnsAccentFlipsInOneHundredSeventyMillisecondsAndLandsAsGround() {
        let delay = 0.2, opened = 1.0
        #expect(DoorwayWave.tile(delay: delay, time: 0.1, openedAt: opened) == .clear)
        guard case let .flipping(start, towardStart) = DoorwayWave.tile(delay: delay, time: 0.2, openedAt: opened)
        else {
            Issue.record("should be flipping")
            return
        }
        #expect(abs(start - 1) < 1e-9 && towardStart == 0)
        guard case let .flipping(edge, _) = DoorwayWave.tile(delay: delay, time: 0.2 + 0.085, openedAt: opened) else {
            Issue.record("should be flipping edge-on")
            return
        }
        #expect(edge < 0.01)
        guard case let .flipping(_, mixed) = DoorwayWave.tile(delay: delay, time: 0.2 + 0.1, openedAt: opened) else {
            Issue.record("should be in its second half")
            return
        }
        #expect(mixed >= 0.55)
        #expect(DoorwayWave.tile(delay: delay, time: 0.2 + 0.171, openedAt: opened) == .ground)
    }

    @Test func onceTheRoomIsOpenTheWaveTakesTheTilesAwayInTheSameOrder() {
        let delay = 0.2, opened = 1.0
        #expect(DoorwayWave.tile(delay: delay, time: opened + 0.1, openedAt: opened) == .ground)
        guard case let .leaving(scale) = DoorwayWave.tile(delay: delay, time: opened + delay + 0.085, openedAt: opened)
        else {
            Issue.record("should be leaving")
            return
        }
        #expect(abs(scale - 0.5) < 1e-6)
        #expect(DoorwayWave.tile(delay: delay, time: opened + delay + 0.2, openedAt: opened) == .clear)
    }

    @Test func theRoomOpensWhenTheLastTileHasLandedAndTheWholeRunHasALength() {
        let reach = DoorwayWave.reach(size: size, origin: origin)
        let cover = DoorwayWave.coverSeconds(reach: reach)
        #expect(cover > Double(reach) * 0.00075)
        #expect(DoorwayWave.totalSeconds(reach: reach) > cover + DoorwayWave.settleSeconds)
        #expect(DoorwayWave.step == 4 && DoorwayWave.flipSeconds == 0.17 && DoorwayWave.secondHalfMix == 0.55)
    }

    @MainActor @Test func reduceMotionNavigatesAtOnceWithNoDoorway() {
        let doorway = Doorway()
        var navigated = 0
        doorway.play(from: origin, accent: .red, reduceMotion: true) { navigated += 1 }
        #expect(navigated == 1 && !doorway.isRunning)
        doorway.play(from: origin, accent: .red, reduceMotion: false) { navigated += 1 }
        #expect(navigated == 1 && doorway.isRunning, "the room waits for the wave")
        doorway.advance(size: size, now: Date().addingTimeInterval(5))
        #expect(navigated == 2 && !doorway.isRunning)
    }
}
