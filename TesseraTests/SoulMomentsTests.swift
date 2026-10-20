import Foundation
@testable import Tessera
import Testing

/// The small mouth and the picks that move her (docs/design/motion/tess-picks.md 18a to 18f). Pure values first, then
/// the router's events.
@MainActor
struct SoulMomentsTests {
    private func router(hour: Int = 12) -> SoulRouter {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return SoulRouter(clock: { date }, wakeStore: UserDefaults(suiteName: "SoulMomentsTests") ?? .standard)
    }

    // MARK: The mouth (18c)

    @Test func everyModeMapsToItsRow() {
        func face(_ moment: SoulExpression.Moment) -> SoulExpression {
            SoulExpression.resolve(moment)
        }
        #expect(face(.init()) == SoulExpression(curve: 0.2, tilt: 0, open: 0))
        #expect(face(.init(mode: .listening)) == SoulExpression(curve: 0, tilt: 0, open: 0.75))
        #expect(face(.init(mode: .thinking)) == SoulExpression(curve: 0.2, tilt: 0.4, open: 0))
        #expect(face(.init(isAskWaiting: true)) == SoulExpression(curve: 0.3, tilt: 0.4, open: 0))
        #expect(face(.init(isSmiling: true)) == SoulExpression(curve: 1, tilt: 0, open: 0))
        #expect(face(.init(isFailed: true)).curve == -0.35)
        #expect(face(.init(isAsleep: true)) == SoulExpression(curve: 0, tilt: 0, open: 0, width: 4.4))
        #expect(face(.init(mode: .listening, isLive: true)) == .rest)
    }

    @Test func noEventButAFailureTurnsACornerDown() {
        let soul = router()
        func lowest() -> CGFloat {
            soul.expression.curve
        }
        var seen: [CGFloat] = []
        for event: SoulEvent in [.tessOpened, .closed, .sent, .draft(isEmpty: false), .taskUndone, .committed,
                                 .heardNothing, .dryCancelled, .askWaiting, .askAnswered, .lineShown, .taskDone,
                                 .doneElsewhere, .backgrounded]
        {
            soul.handle(event)
            seen.append(lowest())
        }
        #expect(seen.allSatisfy { $0 >= 0 })
        soul.handle(.claudeFailed)
        #expect(soul.expression.curve == -0.35)
    }

    @Test func herLineSmilesThenRelaxesSlowly() async throws {
        let soul = router()
        soul.handle(.lineShown)
        #expect(soul.expression.curve == 1)
        #expect(soul.expressionDuration == SoulExpression.transition)
        try await Task.sleep(for: .seconds(1.6))
        #expect(soul.expression.curve == 0.2)
        #expect(soul.expressionDuration == SoulExpression.relax)
    }

    @Test func theMouthSitsUnderTheEyesAndDropsWithTheCurve() {
        let frame = SoulFrame.sample(.idle, time: 0, elapsed: 0, still: true)
        let eyes = SoulEyes.centre(of: frame)
        let mouth = SoulExpression.centre(of: frame)
        #expect(mouth.y > eyes.y)
        #expect(abs((mouth.y - eyes.y) - (3 + SoulExpression.drop) * frame.look.scale) < 0.001)
        #expect(mouth.x == eyes.x)
    }

    // MARK: Gaze

    @Test func aHeldRowPullsTheEyesAndTheDropBlinks() {
        let soul = router()
        soul.placeDock(CGPoint(x: 350, y: 779))
        soul.handle(.rowLifted(y: 400))
        guard case let .look(x, y) = soul.gaze else {
            Issue.record("not looking at the row")
            return
        }
        #expect(x == -1)
        #expect(abs(y - -0.63) < 0.01)
        soul.handle(.rowDropped)
        #expect(soul.gaze == .ahead)
        #expect(soul.overlays.blink != nil)
    }

    @Test func aHeldRowIsRefusedWhileSheWorks() {
        let soul = router()
        soul.handle(.askClaude)
        soul.handle(.rowLifted(y: 400))
        #expect(soul.gaze == .ahead)
    }

    @Test func theRestClockMovesTheEyesAndNothingElse() {
        let soul = SoulRouter(page: .live)
        let before = (soul.mode, soul.isPinned, soul.isAskWaiting, soul.expression)
        soul.handle(.restEnding(at: .zero))
        #expect(soul.gaze == .look(x: -1, y: -1))
        #expect(before == (soul.mode, soul.isPinned, soul.isAskWaiting, soul.expression))
        soul.handle(.restEnded)
        #expect(soul.gaze == .ahead)
        #expect(soul.overlays.blink != nil)
    }

    @Test func sideTurnedLeavesBusyStatesAlone() {
        let soul = router()
        soul.handle(.sideTurned(toward: 1))
        #expect(soul.gaze == .look(x: 0.4, y: 0))
        let busy = router()
        busy.handle(.tessOpened)
        busy.handle(.sideTurned(toward: 1))
        #expect(busy.mode == .listening && busy.gaze == .atHim)
        let asking = router()
        asking.handle(.askClaude)
        asking.handle(.sideTurned(toward: 1))
        #expect(asking.mode == .working)
    }

    // MARK: Sleep (idea 5)

    @Test func atTwentyThreeThirtyOpeningTheAppOpensTheRightEyeFirst() {
        let soul = router(hour: 23)
        soul.handle(.appeared)
        #expect(soul.isAsleep && soul.mode == .resting && soul.sleepLook == .asleep)
        #expect(soul.expression.width == 4.4)
        soul.handle(.foregrounded(underLive: false))
        guard case .opening = soul.sleepLook else {
            Issue.record("eyes did not start opening")
            return
        }
        #expect(!soul.isAsleep && soul.mode == .idle)
        let lids = SoulSleep.lids(opening: 1.0)
        #expect(lids.right == 1 && lids.left == SoulSleep.shut)
        #expect(SoulSleep.lids(opening: 0.1).right == SoulSleep.shut)
        #expect(SoulSleep.lids(opening: SoulSleep.opening).left == 1)
        #expect(SoulSleep.glance(opening: 1) == .look(x: -0.4, y: -0.3))
        #expect(SoulSleep.glance(opening: 2.7) == .ahead)
    }

    @Test func sheSleepsAgainWhenLeftAloneAndIsAsleepAtSixFiftyNine() {
        let soul = router(hour: 23)
        soul.handle(.foregrounded(underLive: false))
        soul.fallAsleep()
        #expect(soul.isAsleep && soul.mode == .resting)
        guard case .drifting = soul.sleepLook else {
            Issue.record("not drifting")
            return
        }
        #expect(SoulSleep.lids(drifting: 3).left == SoulSleep.shut)
        #expect(SoulSleep.lids(drifting: 0).left == 1)
        #expect(router(hour: 6).isAsleep)
        #expect(!router(hour: 7).isAsleep)
        #expect(router(hour: 7).sleepLook == nil)
    }

    @Test func reduceMotionAndLowPowerCrossfadeTheEyeOpens() {
        let quiet = SoulSleep.lids(opening: SoulSleep.rightStart + 0.2, quiet: true)
        #expect(quiet.right == 1)
        #expect(SoulSleep.lids(opening: SoulSleep.rightStart + 0.2).right < 1)
    }

    // MARK: Nudge (idea 7)

    @Test func oneNudgePerItemAndOnlyOnScreen() async throws {
        let soul = router()
        soul.placeDock(CGPoint(x: 350, y: 779))
        soul.handle(.upcoming(id: "a", row: nil))
        #expect(soul.nudge == nil)
        soul.handle(.upcoming(id: "a", row: CGPoint(x: 100, y: 400)))
        let first = try #require(soul.nudge)
        #expect(first.direction.dx < 0 && first.direction.dy < 0)
        #expect(abs(hypot(first.direction.dx, first.direction.dy) - 1) < 0.001)
        #expect(soul.gaze != .ahead)
        try await Task.sleep(for: .milliseconds(30))
        soul.handle(.upcoming(id: "a", row: CGPoint(x: 100, y: 400)))
        #expect(soul.nudge?.start == first.start)
    }

    @Test func noNudgeInQuietHoursOrOnTheLivePage() {
        let night = router(hour: 2)
        night.placeDock(CGPoint(x: 350, y: 779))
        night.handle(.upcoming(id: "a", row: CGPoint(x: 100, y: 400)))
        #expect(night.nudge == nil)
        let live = SoulRouter(page: .live)
        live.placeDock(CGPoint(x: 350, y: 779))
        live.handle(.upcoming(id: "a", row: CGPoint(x: 100, y: 400)))
        #expect(live.nudge == nil)
    }

    @Test func theLeanGoesOutHoldsAndComesBack() {
        let move = SoulMove.lean
        #expect(move.amount(at: 0) == 0)
        #expect(abs(move.amount(at: 0.4) - 1) < 0.001)
        #expect(move.amount(at: 1.2) == 1)
        #expect(move.amount(at: 1.7) == 1)
        #expect(move.amount(at: 1.9) < 1 && move.amount(at: 1.9) > 0)
        #expect(move.amount(at: 2.2) == 0)
        #expect(SoulMove.lean.distance == 4 && SoulMove.peek.distance == 5)
        #expect(SoulMove.peek.duration == 0.35 + 1.6 + 0.5)
    }

    // MARK: Typing (idea 8)

    @Test func fourWordsInThreeHundredMillisecondsGiveAtMostTwoPulses() {
        let soul = router()
        soul.handle(.tessOpened)
        let start = Date.now
        for offset in [0.0, 0.1, 0.2, 0.3] {
            soul.typed(at: start.addingTimeInterval(offset))
        }
        #expect(soul.pulseCount <= 2 && soul.pulseCount >= 1)
    }

    @Test func aWordEndsOnASpaceOrPunctuationAfterALetter() {
        #expect(SoulRouter.endsWord(from: "hello", to: "hello "))
        #expect(SoulRouter.endsWord(from: "hello", to: "hello,"))
        #expect(!SoulRouter.endsWord(from: "hello ", to: "hello  "))
        #expect(!SoulRouter.endsWord(from: "hell", to: "hello"))
        #expect(!SoulRouter.endsWord(from: "", to: " "))
        #expect(!SoulRouter.endsWord(from: "ab", to: "a b"))
    }

    @Test func noPulseUnlessSheListens() {
        let soul = router()
        soul.handle(.wordTyped)
        #expect(soul.pulseCount == 0)
        #expect(abs(SoulPulse.amount(at: SoulPulse.rise) - 1) < 0.001)
        #expect(SoulPulse.amount(at: 0.4) == 0)
        #expect(SoulPulse.swell == 0.06)
    }

    // MARK: Peek (idea 9)

    @Test func twoScrollsToTheEndInOneVisitGiveOnePeek() async throws {
        let soul = router()
        soul.handle(.reachedEnd(page: "groceries"))
        let first = try #require(soul.peek)
        try await Task.sleep(for: .milliseconds(30))
        soul.handle(.reachedEnd(page: "groceries"))
        #expect(soul.peek == first)
        soul.handle(.pageLeft(page: "groceries"))
        try await Task.sleep(for: .milliseconds(30))
        soul.handle(.reachedEnd(page: "groceries"))
        #expect(soul.peek != first)
        #expect(soul.gaze == .look(x: 0.5, y: -1))
    }

    @Test func noPeekWhileWorkingOrAskingOrLive() {
        let working = router()
        working.handle(.askClaude)
        working.handle(.reachedEnd(page: "a"))
        #expect(working.peek == nil)
        let asking = router()
        asking.handle(.askWaiting)
        asking.handle(.reachedEnd(page: "a"))
        #expect(asking.peek == nil)
        let live = SoulRouter(page: .live)
        live.handle(.reachedEnd(page: "a"))
        #expect(live.peek == nil)
    }

    // MARK: Readers and the dock lights (idea 1)

    private let words = [CGRect(x: 0, y: 100, width: 100, height: 20), CGRect(x: 0, y: 200, width: 80, height: 20),
                         CGRect(x: 0, y: 300, width: 60, height: 20)]

    @Test func theFirstThreeDwellsAreOnTheTouchedWordsInOrder() {
        let dwellMid = SoulReaders.hop + SoulReaders.dwell / 2
        for step in 0 ..< 3 {
            let time = Double(step) * SoulReaders.step + dwellMid
            let point = SoulReaders.position(words: words, reader: 0, time: time)
            #expect(point != nil)
            #expect(abs((point?.y ?? 0) - words[step].midY) < 0.001)
            #expect(abs((point?.x ?? 0) - words[step].midX) < 0.001)
            #expect(SoulReaders.dwellingWord(reader: 0, time: time, count: 3) == step)
        }
    }

    @Test func readersNeverRepeatAWordAndStartOverAfterTheLast() {
        for reader in 0 ..< 3 {
            var previous = -1
            for step in 0 ..< 12 {
                let word = SoulReaders.word(step: step, reader: reader, count: 3)
                #expect(word != previous)
                previous = word
            }
        }
        #expect(SoulReaders.word(step: 3, reader: 0, count: 3) == 0)
    }

    @Test func aHopArcsUpAndFewerThanTwoWordsMeansNoReaders() {
        let local = SoulReaders.hop / 2
        let point = SoulReaders.position(words: words, reader: 0, time: SoulReaders.step + local)
        let phase = CGFloat(SoulCurves.ramp(local, from: 0, over: SoulReaders.hop, SoulCurves.house))
        let straight = words[0].midY + (words[1].midY - words[0].midY) * phase
        #expect(abs((point?.y ?? 0) - (straight - 10 * sin(.pi * phase))) < 0.001)
        #expect(SoulReaders.position(words: [words[0]], reader: 0, time: 1) == nil)
        #expect(SoulReaders.position(words: [], reader: 0, time: 1) == nil)
    }

    @Test func twoWorkingStatesWithTheSameWordsDriftDifferently() {
        let first = (0 ..< 12).map { SoulNoise.offset(light: $0, time: 3.3, seed: 1111) }
        let second = (0 ..< 12).map { SoulNoise.offset(light: $0, time: 3.3, seed: 2222) }
        #expect(first != second)
        let every = stride(from: 0.0, to: 40, by: 0.5).flatMap { time in
            (0 ..< 12).map { SoulNoise.offset(light: $0, time: time, seed: 7) }
        }
        #expect(every.allSatisfy { abs($0.x) <= 1.0001 && abs($0.y) <= 1.0001 })
        #expect(SoulNoise.offset(light: 3, time: 0, seed: 9) == SoulNoise.offset(light: 3, time: 0, seed: 9))
    }

    @Test func lowPowerKeepsNoReadersAndFreezesTheDrift() {
        let frame = SoulFrame.sample(.working, time: 0, elapsed: 0, still: true)
        let normal = SoulWork.lights(frame, scale: 1, sinceSplit: 4, sinceGather: nil, readers: words, seed: 5)
        let low = SoulWork.lights(frame, scale: 1, sinceSplit: 4, sinceGather: nil, lowPower: true, readers: words,
                                  seed: 5)
        let later = SoulWork.lights(frame, scale: 1, sinceSplit: 9, sinceGather: nil, lowPower: true, readers: words,
                                    seed: 5)
        #expect(normal != low)
        #expect(low.prefix(6).map(\.alpha) == later.prefix(6).map(\.alpha))
    }

    // MARK: Tilt (idea 11)

    @Test func theTiltNumbersMatchTheSheet() {
        #expect(SoulTiltMath.mainsShift(CGSize(width: 1, height: 1)) == CGPoint(x: 2, y: 1.4))
        #expect(SoulTiltMath.eyesLook(CGSize(width: 1, height: -1)) == CGSize(width: 0.6, height: -0.4))
        #expect(SoulTiltMath.satelliteShare == 1.7)
        #expect(SoulTiltMath.hertz == 30 && SoulTiltMath.smoothing == 0.15)
        let low = SoulTiltMath.lowPassed(.zero, toward: CGSize(width: 1, height: 0))
        #expect(abs(low.width - 0.15) < 0.0001)
        #expect(SoulTiltMath.isFlat(gravityZ: -0.9999) && !SoulTiltMath.isFlat(gravityZ: -0.9))
        let upright = SoulTiltMath.vector(gravityX: 0, gravityY: -0.7)
        #expect(abs(upright.width) < 0.001 && abs(upright.height) < 0.001)
    }

    @Test func satellitesMoveSeventyPercentFurtherThanTheMains() {
        let frame = SoulFrame.sample(.idle, time: 0, elapsed: 0, still: true)
        let moved = SoulTiltMath.shifted(frame, vector: CGSize(width: 1, height: 0), hostScale: 1)
        #expect(abs((moved.dabs[0].x - frame.dabs[0].x) - 2) < 0.001)
        #expect(abs((moved.dabs[3].x - frame.dabs[3].x) - 3.4) < 0.001)
    }

    @Test func noMotionManagerUnderReduceMotionLowPowerOrInTheBackground() {
        #expect(!SoulTilt.shouldRun(reduceMotion: true, lowPower: false, inForeground: true))
        #expect(!SoulTilt.shouldRun(reduceMotion: false, lowPower: true, inForeground: true))
        #expect(!SoulTilt.shouldRun(reduceMotion: false, lowPower: false, inForeground: false))
        #expect(SoulTilt.shouldRun(reduceMotion: false, lowPower: false, inForeground: true))
        let tilt = SoulTilt()
        tilt.update(reduceMotion: true, lowPower: false, inForeground: true)
        #expect(!tilt.isRunning)
    }

    @Test func tiltIsRefusedWhenCarriedWorkingListeningOrLive() {
        let soul = router()
        #expect(!soul.refusesTilt)
        soul.handle(.tessOpened)
        #expect(soul.refusesTilt)
        #expect(SoulRouter(page: .live).refusesTilt)
        let working = router()
        working.handle(.askClaude)
        #expect(working.refusesTilt)
    }
}
