import SwiftUI
@testable import Tessera
import TesseraCore
import Testing

@MainActor
struct RoutineRunTests {
    private let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// Tidy 5, Stretch 6 (Hips, Shoulders, Neck, two minutes each), Read 15, Journal 5, Lights 1.
    private func run() -> RoutineModeRun {
        func beat(_ step: Int, _ title: String, _ seconds: Int, move: Bool = false, breath: String? = nil)
            -> RoutineModeRun.Beat
        {
            RoutineModeRun.Beat(step: step, title: title, cue: move ? "Slow" : nil, breath: breath, seconds: seconds,
                                isMove: move)
        }
        var run = RoutineModeRun(
            beats: [beat(0, "Tidy", 300), beat(1, "Hips", 120, move: true, breath: "in/out"),
                    beat(1, "Shoulders", 120, move: true), beat(1, "Neck", 120, move: true), beat(2, "Read", 900),
                    beat(3, "Journal", 300), beat(4, "Lights", 60)],
            steps: [.init(id: 0, title: "Tidy", minutes: 5, beats: [0]),
                    .init(id: 1, title: "Stretch", minutes: 6, beats: [1, 2, 3], breath: true),
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
        #expect(screen.line == "Stretch, 1 of 3" && screen.stepMinutes == "6 min" && screen.move == "Hips")
        #expect(screen.then == "shoulders")
        #expect(screen.cue == "Slow" && screen.breath == "breathe in" && screen.secondsLeft == 120)
        #expect(screen.moves.map(\.title) == ["Hips", "Shoulders", "Neck"] && screen.moves[0].state == .current)
        #expect(screen.rail.map(\.label) == ["Tidy", "Stretch", "Read", "Journal", "Lights"])
        #expect(screen.rail[0].color == RoutineScreen.tended && screen.rail[1].current)
        let start = RoutineScreen(self.run(), name: "Evening", totalMinutes: 32, now: t0)
        #expect(start.topRight == "about 32 min to bed" && start.verb == "Next" && start.pauseWord == "Pause")
    }

    @Test func noShownLineEndsWithAFullStop() {
        let screen = RoutineScreen(run(), name: "Evening", totalMinutes: 32, now: t0)
        for line in [screen.title, screen.topRight, screen.line, screen.move, screen.cue ?? "", screen.summary] {
            #expect(!line.hasSuffix("."))
        }
    }

    @Test func theInkStaysTheSameThroughTheDusk() {
        #expect(RoutineDusk.ink(0) == RoutineScreen.ink && RoutineDusk.ink(1) == RoutineScreen.ink)
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

struct RoutineReadingTests {
    /// Sheet 341: pages from the minutes, at about 0.7 a minute, and the word before the number never breaks from it.
    @Test func theReadStepNamesAPageAndItsReceiptTheMinutesRead() {
        #expect(RoutineReading.isReading("Read") && !RoutineReading.isReading("Reading list"))
        #expect(RoutineReading.page(after: 20, from: 212) == 226)
        #expect(RoutineReading.label(last: 212, minutes: 20) == "to about page\u{00A0}226")
        #expect(RoutineReading.receipt(title: "Read", last: 212, spent: 600) == "Read, tended, about page\u{00A0}219")
        #expect(!RoutineReading.receipt(title: "Read", last: 212, spent: 0).hasSuffix("."))
    }
}

@MainActor
struct RoutineBreathSlotTests {
    private let t0 = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// Sheet 347: the guide shows only on a step that has the flag, and every other step still says so ("guided" is
    /// false)
    /// so the page keeps the slot empty and the time never moves.
    @Test func onlyAFlaggedStepShowsTheBreathGuide() {
        func beat(_ step: Int, _ title: String, breath: String?) -> RoutineModeRun.Beat {
            RoutineModeRun.Beat(step: step, title: title, cue: nil, breath: breath, seconds: 60, isMove: false)
        }
        var run = RoutineModeRun(
            beats: [beat(0, "Tidy", breath: "in"), beat(1, "Stretch", breath: "in")],
            steps: [.init(id: 0, title: "Tidy", minutes: 1, beats: [0]),
                    .init(id: 1, title: "Stretch", minutes: 1, beats: [1], breath: true)]
        )
        run.start(at: t0)
        // Tidy has a stray breath word on its beat but the step is not flagged: no guide, slot empty.
        let tidy = RoutineScreen(run, name: "Evening", totalMinutes: 2, now: t0)
        #expect(tidy.breath == nil && !tidy.guided)
        run.next(now: t0.addingTimeInterval(1))
        let stretch = RoutineScreen(run, name: "Evening", totalMinutes: 2, now: t0.addingTimeInterval(1))
        #expect(stretch.guided && stretch.breath == "breathe in")
    }
}

struct RoutineFinishTests {
    /// Sheet 335: "5 of 5" never splits; the cue counts days in a row and says nothing of what was missed.
    @Test func theClosingScreenNeverSplitsItsCountAndOnlyCountsUp() {
        #expect(RoutineFinish.count(5, of: 5) == "5\u{00A0}of\u{00A0}5")
        #expect(!RoutineFinish.count(5, of: 5).contains(" "))
        #expect(RoutineFinish.cue(streak: 6) == "Six days in a row now. Sleep well")
        #expect(RoutineFinish.cue(streak: 1) == "Sleep well" && RoutineFinish.cue(streak: nil) == "Sleep well")
        #expect(RoutineFinish.cue(streak: 25) == "25 days in a row now. Sleep well")
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 800_000_000))
        let days = Set((0 ..< 3).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) })
            .union([calendar.date(byAdding: .day, value: -5, to: today) ?? today])
        #expect(RoutineFinish.streak(days: days, today: today, calendar: calendar) == 3)
        #expect(RoutineFinish.streak(days: [], today: today, calendar: calendar) == 0)
    }
}
