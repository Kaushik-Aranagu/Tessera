import Foundation
@testable import Tessera
import Testing

/// Batch 2: the forgot-Finish nudge and the easy-swap switch.
@MainActor
struct FinishNudgeTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return calendar
    }

    private func at(_ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: hour, minute: minute)) ?? .now
    }

    @Test func itFiresFortyFiveMinutesAfterTheLastSetAndOnlyWhenOn() {
        let set = at(18, 0)
        #expect(FinishNudgePlan.fireAt(lastSetAt: set, enabled: true, calendar: calendar) == at(18, 45))
        #expect(FinishNudgePlan.fireAt(lastSetAt: set, enabled: false, calendar: calendar) == nil)
    }

    @Test func itNeverRingsBetweenElevenAndSevenAndIsNotPostponed() {
        #expect(FinishNudgePlan.fireAt(lastSetAt: at(22, 30), enabled: true, calendar: calendar) == nil)
        #expect(FinishNudgePlan.fireAt(lastSetAt: at(3, 0), enabled: true, calendar: calendar) == nil)
        #expect(FinishNudgePlan.fireAt(lastSetAt: at(6, 20), enabled: true, calendar: calendar) == at(7, 5))
        #expect(FinishNudgePlan.fireAt(lastSetAt: at(22, 14), enabled: true, calendar: calendar) == at(22, 59))
    }

    @Test func aPrivateWorkoutReadsMasked() {
        #expect(FinishNudgePlan.title(workoutTitle: "Push A") == "Push A, ready to finish?")
        #expect(FinishNudgePlan.title(workoutTitle: "Private workout") == "Private workout, ready to finish?")
    }

    @Test func oncePerWorkoutAndCancelledWhenTheWorkoutEnds() async {
        let scheduler = RecordingNudges()
        let nudges = FinishNudges(scheduler: scheduler, memory: memory())
        let workout = UUID()
        nudges.sync(workoutID: workout, workoutTitle: "Push A", lastSetAt: at(18, 0), enabled: true, calendar: calendar)
        nudges.sync(workoutID: workout, workoutTitle: "Push A", lastSetAt: at(18, 0), enabled: true, calendar: calendar)
        nudges.sync(workoutID: nil, workoutTitle: "", lastSetAt: nil, enabled: false)
        await nudges.settled()
        #expect(scheduler.log == ["schedule Push A, ready to finish?", "cancel"], "\(scheduler.log)")

        scheduler.delivered = true
        nudges.sync(workoutID: workout, workoutTitle: "Push A", lastSetAt: at(19, 0), enabled: true, calendar: calendar)
        await nudges.settled()
        #expect(scheduler.log.count == 2, "a nudge that already went out is never scheduled again")
    }

    @Test func dismissedThenAnotherSetSchedulesNothing() async {
        let scheduler = RecordingNudges()
        let defaults = memory()
        let workout = UUID()
        let nudges = FinishNudges(scheduler: scheduler, memory: defaults)
        nudges.sync(workoutID: workout, workoutTitle: "Push A", lastSetAt: at(18, 0), enabled: true,
                    calendar: calendar, now: at(18, 5))
        await nudges.settled()
        #expect(scheduler.log == ["schedule Push A, ready to finish?"])
        // 18:45 passes, he dismisses the nudge, and logs another set at 19:00: nothing is scheduled again,
        // even from a fresh instance (a relaunch).
        let relaunched = FinishNudges(scheduler: scheduler, memory: defaults)
        relaunched.sync(workoutID: workout, workoutTitle: "Push A", lastSetAt: at(19, 0), enabled: true,
                        calendar: calendar, now: at(19, 0))
        await relaunched.settled()
        #expect(scheduler.log.filter { $0.hasPrefix("schedule") }.count == 1, "\(scheduler.log)")
        #expect(defaults.isRetired("tessera.finish-nudge.\(workout.uuidString)"))
    }

    @Test func anUnknownStoredValueReadsTheDefault() throws {
        let suite = try #require(UserDefaults(suiteName: "FinishNudgeUnknown"))
        suite.removePersistentDomain(forName: "FinishNudgeUnknown")
        suite.set("Maybe", forKey: "review.finishNudge")
        suite.set("Sideways", forKey: "review.swapExercise")
        suite.set("Banana", forKey: "review.restTimer")
        #expect(!Choice.finishNudgeIsOn(defaults: suite) && !Choice.swapIsOneTap(defaults: suite))
        #expect(Choice.restTimerIsOn(defaults: suite))
        suite.removePersistentDomain(forName: "FinishNudgeUnknown")
    }

    private func memory() -> NudgeMemory {
        let name = "FinishNudgeTests.\(UUID().uuidString)"
        return NudgeMemory(defaults: UserDefaults(suiteName: name) ?? .standard)
    }

    @Test func theSwitchesDefaultToTodaysBehaviour() throws {
        let suite = try #require(UserDefaults(suiteName: "FinishNudgeTests"))
        suite.removePersistentDomain(forName: "FinishNudgeTests")
        #expect(!Choice.swapIsOneTap(defaults: suite) && !Choice.finishNudgeIsOn(defaults: suite))
        suite.set("One tap", forKey: "review.swapExercise")
        suite.set("On", forKey: "review.finishNudge")
        #expect(Choice.swapIsOneTap(defaults: suite) && Choice.finishNudgeIsOn(defaults: suite))
        suite.removePersistentDomain(forName: "FinishNudgeTests")
    }
}

@MainActor
private final class RecordingNudges: FinishNudgeScheduler {
    var log: [String] = []
    var delivered = false

    func schedule(id _: String, title: String, at _: Date) async {
        log.append("schedule \(title)")
    }

    func cancel(id _: String) async {
        log.append("cancel")
    }

    func wasDelivered(id _: String) async -> Bool {
        delivered
    }
}
