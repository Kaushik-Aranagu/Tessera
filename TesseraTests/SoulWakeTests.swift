import Foundation
@testable import Tessera
import Testing

/// She wakes with you (docs/design/motion/tess-picks.md idea 2).
@MainActor
struct SoulWakeTests {
    private final class Clock {
        var now: Date

        init(_ now: Date) {
            self.now = now
        }
    }

    private func at(_ hour: Int, _ minute: Int, dayOffset: Int = 0) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private func freshStore() -> UserDefaults {
        let name = "SoulWakeTests-\(UUID().uuidString)"
        let store = UserDefaults(suiteName: name) ?? .standard
        store.removePersistentDomain(forName: name)
        return store
    }

    @Test func twoForegroundsOnOneDayWakeHerOnce() {
        let store = freshStore()
        let clock = Clock(at(9, 0))
        let soul = SoulRouter(clock: { clock.now }, wakeStore: store)
        soul.handle(.foregrounded(underLive: false))
        #expect(soul.wake != nil)
        // A relaunch later the same day (a new router on the same store) doesn't wake her again.
        clock.now = at(18, 0)
        let again = SoulRouter(clock: { clock.now }, wakeStore: store)
        again.handle(.foregrounded(underLive: false))
        #expect(again.wake == nil)
    }

    @Test func theDayTurnsAtFour() {
        let store = freshStore()
        let clock = Clock(at(9, 0, dayOffset: -1))
        let soul = SoulRouter(clock: { clock.now }, wakeStore: store)
        soul.handle(.foregrounded(underLive: false))
        // 03:59 still belongs to yesterday, which already woke.
        clock.now = at(3, 59)
        let night = SoulRouter(clock: { clock.now }, wakeStore: store)
        night.handle(.foregrounded(underLive: false))
        #expect(night.wake == nil)
        clock.now = at(4, 1)
        let morning = SoulRouter(clock: { clock.now }, wakeStore: store)
        morning.handle(.foregrounded(underLive: false))
        #expect(morning.wake != nil)
    }

    @Test func hisMomentWinsAndTheDayStillCounts() {
        let store = freshStore()
        let clock = Clock(at(9, 0))
        let live = SoulRouter(clock: { clock.now }, wakeStore: store)
        live.handle(.foregrounded(underLive: true))
        #expect(live.wake == nil)
        let later = SoulRouter(clock: { clock.now }, wakeStore: store)
        later.handle(.foregrounded(underLive: false))
        #expect(later.wake == nil)
    }

    @Test func eyesShutThenOpenThenOneBlink() {
        #expect(SoulWake.lid(at: 0.5) == 0.25)
        #expect(SoulWake.lid(at: 1.2) > 0.25 && SoulWake.lid(at: 1.2) < 1)
        #expect(SoulWake.lid(at: 2) == 1)
        #expect(SoulWake.lid(at: 3.48) < 0.5)
        #expect(SoulWake.lid(at: 3.7) == 1)
        // Reduce Motion: a 200 ms crossfade, no extra blink.
        #expect(SoulWake.lid(at: 1.25, quiet: true) == 1)
        #expect(SoulWake.lid(at: 3.48, quiet: true) == 1)
    }

    @Test func oneStretchOutAndBack() {
        #expect(SoulWake.stretch(at: 1.4) == 0)
        #expect(abs(SoulWake.stretch(at: 2.1) - 1) < 0.001)
        #expect(SoulWake.stretch(at: 3.1) < 0.01)
        let frame = SoulFrame.sample(.idle, time: 3, elapsed: 0)
        let wide = SoulWake.stretched(frame, amount: 1)
        #expect(abs(wide.dabs[0].x - frame.dabs[0].x * 1.22) < 0.001)
        // About 20% shorter at the peak: (2 − 0.98 × 1.22) / 1.02.
        #expect(abs(wide.dabs[0].y - frame.dabs[0].y * (2 - 0.98 * 1.22) / 1.02) < 0.001)
    }
}
