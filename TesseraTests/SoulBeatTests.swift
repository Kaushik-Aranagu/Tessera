import Foundation
@testable import Tessera
import Testing

/// Her beat (tess-motion.md §6) and the day she wears (tess-picks.md idea 4).
@MainActor
struct SoulBeatTests {
    private final class Clock {
        var now: Date

        init(_ now: Date) {
            self.now = now
        }
    }

    private func at(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }

    private func store() -> UserDefaults {
        UserDefaults(suiteName: "SoulBeatTests-\(UUID().uuidString)") ?? .standard
    }

    @Test func fiveDonesWearFourStepsAndAnUndoTakesOneBack() async throws {
        let clock = Clock(at(12, 0))
        let soul = SoulRouter(clock: { clock.now }, wakeStore: store())
        for _ in 0 ..< 5 {
            soul.handle(.taskDone)
        }
        // The wear lands with the beat, 520 ms after the strike.
        try await Task.sleep(for: .seconds(0.7))
        #expect(soul.wearDones == 5)
        #expect(abs(soul.wear(at: .now) - 0.40) < 0.001)
        let one = SoulRouter(clock: { clock.now }, wakeStore: store())
        one.handle(.taskDone)
        try await Task.sleep(for: .seconds(0.7))
        one.handle(.taskUndone)
        #expect(one.wear(at: .now) == 0)
    }

    @Test func atFourSheStartsPlainOverAMinute() {
        let defaults = store()
        let clock = Clock(at(3, 30))
        // Yesterday (03:30 still belongs to it): three things done.
        _ = SoulRouter(clock: { clock.now }, wakeStore: defaults)
        defaults.set(3, forKey: SoulRouter.wearDonesKey)
        clock.now = at(4, 1)
        let morning = SoulRouter(clock: { clock.now }, wakeStore: defaults)
        #expect(morning.wearDones == 0)
        // Never a visible step: yesterday's 0.30 dries over the first minute.
        #expect(abs(morning.wear(at: .now) - 0.30) < 0.01)
        #expect(morning.wear(at: .now.addingTimeInterval(61)) == 0)
    }

    @Test func aDoneWhileSheListensBeatsWhenSheStops() async throws {
        let soul = SoulRouter(clock: { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)! },
                              wakeStore: store())
        soul.handle(.tessOpened)
        soul.handle(.taskDone)
        try await Task.sleep(for: .seconds(0.7))
        #expect(soul.beat == nil && soul.wearDones == 1)
        soul.handle(.closed)
        try await Task.sleep(for: .seconds(0.05))
        #expect(soul.beat != nil)
    }

    @Test func theGatherIsInAndOutInHalfASecond() {
        #expect(SoulBeat.gather(-0.1) == 0)
        #expect(SoulBeat.gather(0.18) > 0.95)
        #expect(SoulBeat.gather(0.6) < 0.01)
        let frame = SoulFrame.sample(.idle, time: 3, elapsed: 0)
        let beating = SoulBeat.beating(frame, gather: 1, wear: 0.1)
        #expect(abs(beating.look.saturation - (frame.look.saturation + 0.35)) < 0.001)
    }
}
