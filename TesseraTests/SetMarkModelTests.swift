import Foundation
import SwiftUI
@testable import Tessera
import Testing

/// Design sheet 108 section 1: the mark's shapes, thickness, words and timing.
struct SetMarkModelTests {
    private func spec(reps: Int, target: Int = 8, weight: Double = 80, heaviest: Double = 100, best: Bool = false,
                      isPrivate: Bool = false) -> SetMarkSpec
    {
        SetMarkSpec(id: UUID(), number: 3, reps: reps, target: target, weight: weight, heaviest: heaviest,
                    isBest: best, isPrivate: isPrivate)
    }

    @Test func theShapeTellsOnTargetShortMoreAndBest() {
        #expect(spec(reps: 8).shape == .closed)
        #expect(spec(reps: 6).shape == .open(gap: 0.25))
        #expect(spec(reps: 10).shape == .overlap(extra: 0.25))
        #expect(spec(reps: 16).shape == .overlap(extra: 1))
        #expect(spec(reps: 30).shape == .overlap(extra: 1), "the overlap is capped")
        #expect(spec(reps: 6, best: true).shape == .flare, "a best flares whatever the reps")
        #expect(spec(reps: 8, target: 0).shape == .closed, "no target, nothing to fall short of")
    }

    @Test func aHeavierSetDrawsAThickerStroke() {
        #expect(spec(reps: 8, weight: 100, heaviest: 100).thickness == 10)
        #expect(spec(reps: 8, weight: 50, heaviest: 100).thickness == 7.5)
        #expect(spec(reps: 8, weight: 0, heaviest: 100).thickness == 5)
        #expect(spec(reps: 8, weight: 120, heaviest: 100).thickness == 10, "capped at the heaviest")
        #expect(spec(reps: 8, weight: 80, heaviest: 0).thickness == 5)
    }

    @Test func aTapShowsTheExactLineInTheAppsUnitAndPrivateShowsNone() {
        let line = spec(reps: 9, weight: 85).detailLine { "\(Int($0)) kg" }
        #expect(line == "Set 3: 85 kg x 9")
        #expect(spec(reps: 9, weight: 85, isPrivate: true).detailLine { "\(Int($0)) kg" } == nil)
    }

    @Test func voiceOverReadsTheSetAndPrivateReadsOnlyItsNumber() {
        let one = spec(reps: 1, weight: 82.5)
        #expect(one.spoken { "\($0) kilograms" } == "Set 3, 1 rep, 82.5 kilograms")
        #expect(spec(reps: 8, weight: 82.5).spoken { "\($0) kilograms" } == "Set 3, 8 reps, 82.5 kilograms")
        #expect(spec(reps: 8, isPrivate: true).spoken { _ in "x" } == "Set 3")
    }

    @Test func repsRunThreeTenthsWithTheLastTwoSlower() {
        let durations = SetMarkClock.repDurations(reps: 8)
        #expect(durations.count == 8)
        #expect(durations.prefix(6).allSatisfy { $0 == 0.30 })
        #expect(Array(durations.suffix(2)) == [0.52, 0.74])
        #expect(SetMarkClock.repDurations(reps: 0).isEmpty)
        #expect(SetMarkClock.repDurations(reps: 1) == [0.74], "a single rep is the slowest")
        #expect(abs(SetMarkClock.closes(reps: 8) - (6 * 0.30 + 0.52 + 0.74 + SetMarkClock.draw)) < 1e-9)
    }

    @Test func theRepClockFindsTheRepUnderWayAndWhereTheTremblesAre() throws {
        let first = try #require(SetMarkClock.rep(at: 0.15, reps: 8))
        #expect(first.index == 0 && abs(first.phase - 0.5) < 1e-9)
        let seventh = try #require(SetMarkClock.rep(at: 6 * 0.30 + 0.1, reps: 8))
        #expect(seventh.index == 6)
        #expect(SetMarkClock.rep(at: 99, reps: 8) == nil)
        #expect(!SetMarkClock.trembles(index: 5, reps: 8))
        #expect(SetMarkClock.trembles(index: 6, reps: 8) && SetMarkClock.trembles(index: 7, reps: 8))
    }

    @MainActor private func pixels(_ spec: SetMarkSpec) -> Data? {
        let renderer = ImageRenderer(content: SetMarkCircle(spec: spec, side: 60).environment(\.colorScheme, .light))
        renderer.scale = 2
        return renderer.uiImage?.pngData()
    }

    @MainActor @Test func aPrivateSetIsOneIdenticalRingWhateverItsReps() {
        let six = pixels(spec(reps: 6, weight: 40, isPrivate: true))
        #expect(six != nil)
        for other in [spec(reps: 8, weight: 100, isPrivate: true), spec(reps: 12, weight: 60, isPrivate: true),
                      spec(reps: 8, best: true, isPrivate: true)]
        {
            #expect(pixels(other) == six, "a private ring shows nothing of the set")
        }
        #expect(pixels(spec(reps: 6, weight: 40)) != six, "an ordinary set still differs")
    }

    @Test func aPrivateSetShapeIsAlwaysClosedAtFixedWidth() {
        #expect(spec(reps: 3, best: true, isPrivate: true).shape == .closed)
        #expect(spec(reps: 3, weight: 10, heaviest: 100, isPrivate: true).thickness == 6)
    }

    @Test func aSecondSetSettlesTheFirstPlayThatWasRunning() {
        var queue = SetMarkQueue()
        let first = spec(reps: 8), second = spec(reps: 8)
        let none = queue.start(first, at: .now)
        #expect(none == nil)
        let interrupted = queue.start(second, at: .now)
        #expect(interrupted == first, "the running play lands first")
        #expect(queue.settled.contains(first.id) && queue.current?.spec.id == second.id)
        let again = queue.finish(first.id)
        #expect(!again, "the interrupted play cannot finish again")
        let done = queue.finish(second.id)
        #expect(done && queue.current == nil && queue.settled.contains(second.id))
    }

    @Test func anUndoneSetIsForgottenAndCancelsItsPlay() {
        var queue = SetMarkQueue()
        let one = spec(reps: 8)
        queue.start(one, at: .now)
        let cancelled = queue.forget(keeping: [])
        #expect(cancelled)
        #expect(queue.current == nil && queue.settled.isEmpty)
    }

    @Test func theFlareSeedIsTheSameEveryTime() {
        let id = UUID()
        #expect(BrushCircleArt.stableSeed(id) == BrushCircleArt.stableSeed(id))
        #expect(BrushCircleArt.stableSeed(id) != BrushCircleArt.stableSeed(UUID()))
    }
}
