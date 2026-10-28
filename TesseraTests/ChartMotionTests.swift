import Foundation
@testable import Tessera
import Testing

/// The pure timings of the room's motion: the replay (372), the drink (385) and the glow handover (364).
struct ChartMotionTests {
    // MARK: 372, the replay

    private func doc(_ ids: String...) -> ChartDoc {
        ChartDoc(name: "Chart room", parts: ids.map { ChartPart(id: $0, kind: .title, place: "title") })
    }

    @Test func aReplaySkipsTheSentencesThatChangedNothing() {
        let docs = [doc("a"), doc("a"), doc("a", "b"), doc("a", "b"), doc("a", "b", "c")]
        #expect(ReplayPlan.changed(docs) == [0, 2, 4], "the repeat and the refusal are not steps")
        #expect(ReplayPlan.changed([]).isEmpty)
    }

    @Test func aReplayOfAFewSentencesRunsAtFullSpeed() {
        let beats = ReplayPlan.timeline(count: 4)
        #expect(beats.count == 4)
        #expect(beats[0].start == ReplayPlan.frameIn, "the frame sketches in first")
        #expect(abs(beats[1].start - beats[0].start - 0.32) < 1e-9, "240 ms of line and 80 ms to the next")
        #expect(beats[0].dry == 0.24)
        #expect(ReplayPlan.end(count: 4) < ReplayPlan.total)
    }

    @Test func aReplayOfManyIsFittedInsideAboutTwoPointTwoSeconds() {
        let beats = ReplayPlan.timeline(count: 12)
        #expect(beats.count == 12 && beats.map(\.index) == Array(0 ..< 12))
        #expect(ReplayPlan.end(count: 12) <= ReplayPlan.total + 1e-9)
        #expect(ReplayPlan.end(count: 12) > ReplayPlan.total - 0.4, "it fills the time, it is not rushed past it")
        #expect(zip(beats, beats.dropFirst()).allSatisfy { $0.start < $1.start }, "in the order he said them")
        #expect(beats[0].dry < 0.24, "sped up only to fit")
    }

    @Test func underReduceMotionTheRoomIsThereWhole() {
        #expect(ReplayPlan.timeline(count: 6, reduceMotion: true).isEmpty)
        #expect(ReplayPlan.end(count: 6, reduceMotion: true) == 0)
        #expect(ReplayPlan.timeline(count: 0).isEmpty)
    }

    // MARK: 385, the drink

    @Test func theWaterlineClimbsFastThenSlowAndASinkIsEven() {
        #expect(DrinkRun.progress(at: 0, up: true, reduceMotion: false) == 0)
        #expect(abs(DrinkRun.progress(at: DrinkRun.seconds, up: true, reduceMotion: false) - 1) < 1e-6)
        let early = DrinkRun.progress(at: 0.15, up: true, reduceMotion: false)
        let late = DrinkRun.progress(at: DrinkRun.seconds, up: true, reduceMotion: false)
            - DrinkRun.progress(at: DrinkRun.seconds - 0.15, up: true, reduceMotion: false)
        #expect(early > late * 2, "fast at first, slower near the top")
        var last = -1.0
        for step in 0 ... 20 {
            let value = DrinkRun.progress(at: DrinkRun.seconds * Double(step) / 20, up: true, reduceMotion: false)
            #expect(value >= last)
            last = value
        }
        // Undo: from the top down, and the middle of an even sink is about the middle.
        #expect(abs(DrinkRun.progress(at: 0, up: false, reduceMotion: false) - 1) < 1e-6)
        #expect(abs(DrinkRun.progress(at: DrinkRun.seconds / 2, up: false, reduceMotion: false) - 0.5) < 0.02)
        #expect(DrinkRun.progress(at: DrinkRun.seconds, up: false, reduceMotion: false) < 1e-6)
    }

    @Test func underReduceMotionTheColourIsInPlace() {
        #expect(DrinkRun.progress(at: 0.1, up: true, reduceMotion: true) == 1)
        #expect(DrinkRun.progress(at: 0.1, up: false, reduceMotion: true) == 0)
        #expect(DrinkRun.slide(progress: 1, textHeight: 64) == 128, "it slides up by two text heights")
        #expect(DrinkRun.band == 0.25)
    }

    // MARK: 364, the glow follows the ranking

    @Test func theGlowChangesOwnerOnlyAfterTheMoveHasSettled() {
        #expect(GlowFollow.owner(current: "Orchid", leader: "Monstera", elapsed: 0, reduceMotion: false) == "Orchid")
        #expect(GlowFollow.owner(current: "Orchid", leader: "Monstera", elapsed: GlowFollow.settle - 0.01,
                                 reduceMotion: false) == "Orchid", "it never travels with the old leader")
        #expect(GlowFollow.owner(current: "Orchid", leader: "Monstera", elapsed: GlowFollow.settle,
                                 reduceMotion: false) == "Monstera")
        #expect(abs(GlowFollow.settle - 0.3744) < 1e-6, "the last 28% of the 520 ms move")
        #expect(GlowFollow.owner(current: "Orchid", leader: "Monstera", elapsed: 0, reduceMotion: true) == "Monstera")
        #expect(GlowFollow.owner(current: "Monstera", leader: nil, elapsed: 1, reduceMotion: false) == nil,
                "all watered: nothing glows")
        // Undo reverses the order: the orchid takes the glow back after the same settle.
        #expect(GlowFollow
            .owner(current: "Monstera", leader: "Orchid", elapsed: 0.1, reduceMotion: false) == "Monstera")
        #expect(GlowFollow.owner(current: "Monstera", leader: "Orchid", elapsed: 0.4, reduceMotion: false) == "Orchid")
    }
}
