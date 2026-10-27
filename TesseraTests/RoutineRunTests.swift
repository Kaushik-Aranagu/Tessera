import SwiftUI
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct RoutineRunTests {
    private let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// Tidy 5, Stretch 6 (Hips, Shoulders, Neck, two minutes each), Read 15, Journal 5, Lights 1.
    private func run() -> RoutineRun {
        func beat(_ step: Int, _ title: String, _ seconds: Int, move: Bool = false, breath: String? = nil)
            -> RoutineRun.Beat
        {
            RoutineRun.Beat(step: step, title: title, cue: move ? "Slow" : nil, breath: breath, seconds: seconds,
                            isMove: move)
        }
        var run = RoutineRun(
            beats: [beat(0, "Tidy", 300), beat(1, "Hips", 120, move: true, breath: "in/out"),
                    beat(1, "Shoulders", 120, move: true), beat(1, "Neck", 120, move: true), beat(2, "Read", 900),
                    beat(3, "Journal", 300), beat(4, "Lights", 60)],
            steps: [.init(id: 0, title: "Tidy", minutes: 5, beats: [0]),
                    .init(id: 1, title: "Stretch", minutes: 6, beats: [1, 2, 3]),
                    .init(id: 2, title: "Read", minutes: 15, beats: [4]),
                    .init(id: 3, title: "Journal", minutes: 5, beats: [5]),
                    .init(id: 4, title: "Lights", minutes: 1, beats: [6])]
        )
        run.start(at: t0)
        return run
    }

    @Test func opensOnTidyAndAMoveEndsByItself() {
        var run = run()
        #expect(run.beat?.title == "Tidy" && run.secondsLeft(at: t0) == 300)
        run.tick(now: t0.addingTimeInterval(299))
        #expect(run.beat?.title == "Tidy")
        run.tick(now: t0.addingTimeInterval(301))
        #expect(run.beat?.title == "Hips" && run.tended == [0])
        #expect(run.moveCount?.at == 1 && run.moveCount?.of == 3)
        // The next move began at the old one's end, not at the tick.
        #expect(run.secondsLeft(at: t0.addingTimeInterval(301)) == 119)
    }

    @Test func nextMovesOnEarlyAndTendingAStepNeedsAllItsMoves() {
        var run = run()
        run.next(now: t0.addingTimeInterval(10))
        #expect(run.beat?.title == "Hips" && run.tended == [0])
        run.next(now: t0.addingTimeInterval(20))
        run.next(now: t0.addingTimeInterval(30))
        #expect(run.beat?.title == "Neck" && !run.tended.contains(1))
        run.next(now: t0.addingTimeInterval(40))
        #expect(run.beat?.title == "Read" && run.tended == [0, 1])
        #expect(run.dusk == 2.0 / 5.0)
    }

    @Test func pausingHoldsTheTimeLeft() {
        var run = run()
        run.pause(now: t0.addingTimeInterval(100))
        #expect(run.isPaused && run.secondsLeft(at: t0.addingTimeInterval(5000)) == 200)
        run.tick(now: t0.addingTimeInterval(5000))
        #expect(run.beat?.title == "Tidy")
        run.resume(now: t0.addingTimeInterval(5000))
        #expect(run.secondsLeft(at: t0.addingTimeInterval(5050)) == 150)
    }

    @Test func notTonightLeavesAStepForTomorrowAndKeepsTheStreak() {
        var run = run()
        run.next(now: t0.addingTimeInterval(5))
        run.notTonight(now: t0.addingTimeInterval(6))
        #expect(run.skipped == [1] && run.beat?.title == "Read")
        // A skipped step does not darken the dusk and does not count as tended; the evening is still kept.
        #expect(run.dusk == 1.0 / 5.0 && run.kept)
        for second in stride(from: 10, through: 100, by: 10) {
            run.next(now: t0.addingTimeInterval(TimeInterval(second)))
        }
        #expect(run.finished && run.tended == [0, 2, 3, 4] && run.dusk == 4.0 / 5.0)
    }

    @Test func aLongSleepLandsOnTheRightMove() {
        var run = run()
        run.tick(now: t0.addingTimeInterval(300 + 120 + 30))
        #expect(run.beat?.title == "Shoulders" && run.secondsLeft(at: t0.addingTimeInterval(450)) == 90)
        run.tick(now: t0.addingTimeInterval(3 * 3600))
        #expect(run.finished && run.tended.count == 5 && run.dusk == 1)
    }

    @Test func theBreathAlternatesInAndOutForAMoveThatAsksForBoth() {
        var run = run()
        run.next(now: t0)
        #expect(run.breath(at: t0.addingTimeInterval(2)) == "in")
        #expect(run.breath(at: t0.addingTimeInterval(5)) == "out")
        #expect(run.breath(at: t0.addingTimeInterval(11)) == "in")
        #expect(self.run().breath(at: t0) == nil)
    }

    @Test func theScreenReadsLikeSheet329() {
        var run = run()
        run.next(now: t0.addingTimeInterval(1))
        let screen = RoutineScreen(run, name: "Evening", totalMinutes: 32, now: t0.addingTimeInterval(1))
        #expect(screen.title == "Evening" && screen.topRight == "1 of 5 tended")
        #expect(screen.line == "Stretch, 2 of 5" && screen.stepMinutes == "6 min" && screen.move == "Hips")
        #expect(screen.cue == "Slow" && screen.breath == "breathe in" && screen.secondsLeft == 120)
        #expect(screen.moves.map(\.title) == ["Hips", "Shoulders", "Neck"] && screen.moves[0].state == .current)
        #expect(screen.rail.map(\.label) == ["Tidy", "Stretch", "Read", "Journal", "Lights"])
        #expect(screen.rail[0].color == RoutineScreen.tendedGreen && screen.rail[1].current)
        let start = RoutineScreen(self.run(), name: "Evening", totalMinutes: 32, now: t0)
        #expect(start.topRight == "about 32 min to bed" && start.verb == "Next" && start.pauseWord == "Pause")
    }

    @Test func noShownLineEndsWithAFullStop() {
        let screen = RoutineScreen(run(), name: "Evening", totalMinutes: 32, now: t0)
        for line in [screen.title, screen.topRight, screen.line, screen.move, screen.cue ?? "", screen.summary] {
            #expect(!line.hasSuffix("."))
        }
    }

    @Test func theDuskTurnsItsInkHalfway() {
        #expect(RoutineDusk.night(0) == 0 && RoutineDusk.night(1) == 1 && RoutineDusk.night(0.35) == 0)
    }
}

@MainActor
struct RoutineDimTests {
    private let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func run() -> RoutineModeRun {
        func beat(_ step: Int, _ title: String, _ seconds: Int) -> RoutineModeRun.Beat {
            RoutineModeRun.Beat(step: step, title: title, cue: nil, breath: nil, seconds: seconds, isMove: false)
        }
        var run = RoutineModeRun(beats: [beat(0, "Journal", 300), beat(1, "Lights", 60)],
                                 steps: [.init(id: 0, title: "Journal", minutes: 5, beats: [0]),
                                         .init(id: 1, title: "Lights", minutes: 1, beats: [1])])
        run.start(at: t0)
        return run
    }

    /// Sheet 335: full brightness until the last step; there it dims to 62% as the countdown runs, and the closing
    /// screen stays dim.
    @Test func theLastStepDimsToSixtyTwoPercent() {
        var run = run()
        #expect(RoutineScreen(run, name: "Evening", totalMinutes: 6, now: t0).brightness == 1)
        run.next(now: t0.addingTimeInterval(10))
        let start = RoutineScreen(run, name: "Evening", totalMinutes: 6, now: t0.addingTimeInterval(10))
        #expect(start.brightness == 1 && start.move == "Lights")
        let half = RoutineScreen(run, name: "Evening", totalMinutes: 6, now: t0.addingTimeInterval(40))
        #expect(abs(half.brightness - 0.81) < 0.001)
        let end = RoutineScreen(run, name: "Evening", totalMinutes: 6, now: t0.addingTimeInterval(70))
        #expect(abs(end.brightness - 0.62) < 0.001)
        run.tick(now: t0.addingTimeInterval(200))
        #expect(run.finished && RoutineScreen(run, name: "Evening", totalMinutes: 6, now: t0.addingTimeInterval(200))
            .brightness == RoutineScreen.dimmest)
    }
}
