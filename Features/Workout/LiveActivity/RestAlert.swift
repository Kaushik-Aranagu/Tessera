import Foundation
import UserNotifications

/// The rest-end alert is one local notification (spec: docs/design/motion/tess-rest-end-alert-and-closing-face.md,
/// section 1; Product G217): scheduled at `restEndsAt`, moved by +15, cancelled by Skip, a logged set or End workout.
/// The Live Activity carries no alert. Wording is fixed and never names the exercise: title "Timer", body "Rest is up",
/// so nothing private can reach a locked screen.
enum RestAlertPlan {
    static let title = "Timer"
    static let body = "Rest is up"

    /// When the notification should fire on the real clock, or nil when nothing should be pending: the switch is
    /// off, there is no rest, or it has already ended. `restEndsAt` and `appNow` are app time (which `-demoTime` may
    /// shift); the notification fires in real time. Rounded to the second so repeated syncs are one request.
    static func fireAt(restEndsAt: Date?, appNow: Date, realNow: Date, enabled: Bool) -> Date? {
        guard enabled, let end = restEndsAt, end > appNow else { return nil }
        let real = end.addingTimeInterval(realNow.timeIntervalSince(appNow))
        return Date(timeIntervalSinceReferenceDate: real.timeIntervalSinceReferenceDate.rounded())
    }
}

@MainActor
protocol RestAlertScheduler {
    func requestPermissionIfNeeded() async
    func schedule(at date: Date) async
    func cancel() async
}

/// Keeps at most one rest notification pending, in order.
@MainActor
final class RestAlerts {
    static let shared = RestAlerts(scheduler: SystemRestAlertScheduler())

    private let scheduler: RestAlertScheduler
    private var scheduledAt: Date?
    private var queue: Task<Void, Never>?

    init(scheduler: RestAlertScheduler) {
        self.scheduler = scheduler
    }

    /// Makes the pending notification match `fireAt` (nil cancels). Idempotent.
    func sync(fireAt: Date?) {
        guard fireAt != scheduledAt else { return }
        scheduledAt = fireAt
        let previous = queue
        let scheduler = scheduler
        queue = Task { @MainActor in
            await previous?.value
            if let fireAt {
                await scheduler.requestPermissionIfNeeded()
                await scheduler.schedule(at: fireAt)
            } else {
                await scheduler.cancel()
            }
        }
    }

    /// For tests: waits for the queued work.
    func settled() async {
        await queue?.value
    }
}

@MainActor
final class SystemRestAlertScheduler: RestAlertScheduler {
    static let identifier = "tessera.rest-end"
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestPermissionIfNeeded() async {
        // The system asks once; later calls return the answer without asking again.
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func schedule(at date: Date) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        let content = UNMutableNotificationContent()
        content.title = RestAlertPlan.title
        content.body = RestAlertPlan.body
        content.sound = .default
        content.interruptionLevel = .active
        content.threadIdentifier = "tessera.workout"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
    }

    func cancel() async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}
