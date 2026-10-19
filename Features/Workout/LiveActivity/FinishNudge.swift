import Foundation
import UserNotifications

/// The forgot-Finish nudge (switch "Forgot Finish nudge", Off by default; Product, batch 2): if a workout is still
/// running 45 minutes after its last set, one quiet local notification, once per workout: "<title>, ready to finish?"
/// (a private workout reads "Private workout, ready to finish?"). Never between 11 PM and 7 AM (it is skipped, not
/// postponed), never twice, and no count of misses. A tap opens the app on the workout.
enum FinishNudgePlan {
    static let delay: TimeInterval = 45 * 60

    /// When the nudge fires, or nil: the switch is off, or the moment falls in quiet hours (23:00 to 07:00).
    static func fireAt(lastSetAt: Date, enabled: Bool, calendar: Calendar = .current) -> Date? {
        guard enabled else { return nil }
        let fire = lastSetAt.addingTimeInterval(delay)
        let hour = calendar.component(.hour, from: fire)
        guard hour >= 7, hour < 23 else { return nil }
        return fire
    }

    static func title(workoutTitle: String) -> String {
        "\(workoutTitle), ready to finish?"
    }
}

@MainActor
protocol FinishNudgeScheduler {
    func schedule(id: String, title: String, at date: Date) async
    func cancel(id: String) async
    func wasDelivered(id: String) async -> Bool
}

/// Keeps at most one nudge pending for the running workout, and none once it has gone out.
@MainActor
final class FinishNudges {
    static let shared = FinishNudges(scheduler: SystemFinishNudgeScheduler())

    private let scheduler: FinishNudgeScheduler
    private var queue: Task<Void, Never>?
    private var last: (id: String, title: String, at: Date)?

    init(scheduler: FinishNudgeScheduler) {
        self.scheduler = scheduler
    }

    /// Makes the pending nudge match the session (nil cancels). Idempotent for the same last set.
    func sync(workoutID: UUID?, workoutTitle: String, lastSetAt: Date?, enabled: Bool, calendar: Calendar = .current) {
        let id = workoutID.map { "tessera.finish-nudge.\($0.uuidString)" }
        guard let id, let lastSetAt, let fire = FinishNudgePlan.fireAt(lastSetAt: lastSetAt, enabled: enabled,
                                                                       calendar: calendar)
        else {
            cancelPending()
            return
        }
        let title = FinishNudgePlan.title(workoutTitle: workoutTitle)
        let rounded = Date(timeIntervalSinceReferenceDate: fire.timeIntervalSinceReferenceDate.rounded())
        guard last?.id != id || last?.at != rounded || last?.title != title else { return }
        last = (id, title, rounded)
        enqueue { [scheduler] in
            // Once per workout: if it already went out, it is never scheduled again.
            if await scheduler.wasDelivered(id: id) {
                return
            }
            await scheduler.schedule(id: id, title: title, at: rounded)
        }
    }

    private func cancelPending() {
        guard let id = last?.id else { return }
        last = nil
        enqueue { [scheduler] in await scheduler.cancel(id: id) }
    }

    private func enqueue(_ work: @escaping @MainActor () async -> Void) {
        let previous = queue
        queue = Task { @MainActor in
            await previous?.value
            await work()
        }
    }

    func settled() async {
        await queue?.value
    }
}

@MainActor
final class SystemFinishNudgeScheduler: FinishNudgeScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func schedule(id: String, title: String, at date: Date) async {
        _ = try? await center.requestAuthorization(options: [.alert])
        let content = UNMutableNotificationContent()
        content.title = title
        content.interruptionLevel = .passive
        content.threadIdentifier = "tessera.workout"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancel(id: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func wasDelivered(id: String) async -> Bool {
        await center.deliveredNotifications().contains { $0.request.identifier == id }
    }
}
