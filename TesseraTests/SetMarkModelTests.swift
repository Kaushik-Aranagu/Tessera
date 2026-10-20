import Foundation
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
        #expect(line == "Set 3: 85 kg \u{00D7} 9")
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
}
