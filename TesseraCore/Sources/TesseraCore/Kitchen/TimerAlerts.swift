import Foundation

/// One local notification for one running kitchen timer (G217): it rings when the app is in the background or the phone
/// is in Low Power, where a Live Activity or an in-app sound cannot. The Live Activity updates stay silent, so this is
/// the only alert (G222).
public struct TimerAlert: Equatable, Sendable {
    /// The timer object's id, also the notification request's identifier.
    public let id: UUID
    /// What the timer is for as it may be said: "Rice", or "Timer" when the label is private, empty or only a number.
    public let label: String
    public let fireAt: Date

    /// Always "Timer": the label never goes in the title (Design's copy verdict).
    public var title: String {
        "Timer"
    }

    /// "Rice is done." / "Timer is done."
    public var body: String {
        "\(label) is done."
    }

    public init(id: UUID, label: String, fireAt: Date) {
        self.id = id
        self.label = label
        self.fireAt = fireAt
    }
}

/// The system side of a timer alert: `SystemTimerAlertScheduler` in the app, a spy in tests.
@MainActor
public protocol TimerAlertScheduler {
    /// Asks for notification permission the first time a timer needs it (never at launch, never twice).
    func requestPermissionIfNeeded() async
    func schedule(_ alert: TimerAlert) async
    func cancel(ids: [UUID]) async
    /// The ids of the alerts already scheduled.
    func scheduledIDs() async -> Set<UUID>
}

/// Keeps the scheduled alerts equal to the running timers, whatever stopped one: Stop, Finish cooking, an UNDO of the
/// start, or a deleted cook. The app calls `reconcile` after every change; nothing else touches the scheduler.
@MainActor
public struct KitchenTimerAlerts {
    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// The alerts that should exist now: a running timer whose end is still ahead. A private timer label reads
    /// "Timer", never the words.
    public func wanted(at now: Date = .now) -> [TimerAlert] {
        CookLog(store: store, classes: classes).timers(at: now)
            .filter { $0.endsAt > now && !$0.object.isDeleted }
            .map { timer in
                let name = timer.label.trimmingCharacters(in: .whitespacesAndNewlines)
                let plain = name.isEmpty || name.allSatisfy { $0.isNumber || ".,: ".contains($0) }
                let hidden = plain || ObjectPrivacy.isPrivateWord(name, in: store)
                return TimerAlert(id: timer.id, label: hidden ? "Timer" : name.prefix(1).uppercased() + name.dropFirst(),
                                  fireAt: timer.endsAt)
            }
    }

    /// What to add and what to cancel to make `scheduled` match `wanted`.
    public static func plan(wanted: [TimerAlert], scheduled: Set<UUID>) -> (add: [TimerAlert], cancel: [UUID]) {
        let wantedIDs = Set(wanted.map(\.id))
        return (
            wanted.filter { !scheduled.contains($0.id) },
            scheduled.subtracting(wantedIDs).sorted { $0.uuidString < $1.uuidString }
        )
    }

    /// Brings the scheduler in line. Permission is asked only when there is something to schedule.
    public func reconcile(with scheduler: some TimerAlertScheduler, now: Date = .now) async {
        let wanted = wanted(at: now)
        let plan = await Self.plan(wanted: wanted, scheduled: scheduler.scheduledIDs())
        if !plan.cancel.isEmpty {
            await scheduler.cancel(ids: plan.cancel)
        }
        guard !plan.add.isEmpty else { return }
        await scheduler.requestPermissionIfNeeded()
        for alert in plan.add {
            await scheduler.schedule(alert)
        }
    }
}

#if canImport(UserNotifications)
    import UserNotifications

    /// The real scheduler: one `UNNotificationRequest` per timer, identified `kitchen-timer.<id>`. Never built in the
    /// package's tests (it needs an app bundle).
    @MainActor
    public final class SystemTimerAlertScheduler: TimerAlertScheduler {
        static let prefix = "kitchen-timer."
        private let center: UNUserNotificationCenter

        public init(center: UNUserNotificationCenter = .current()) {
            self.center = center
        }

        public func requestPermissionIfNeeded() async {
            // The system asks once; later calls return the answer without asking again.
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        public func schedule(_ alert: TimerAlert) async {
            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.body
            content.sound = .default
            // An active alert, grouped in the kitchen thread (cook-mode acceptance).
            content.interruptionLevel = .active
            content.threadIdentifier = "tessera.kitchen"
            let seconds = max(1, alert.fireAt.timeIntervalSinceNow)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: Self.prefix + alert.id.uuidString, content: content,
                                                        trigger: trigger))
        }

        public func cancel(ids: [UUID]) async {
            center.removePendingNotificationRequests(withIdentifiers: ids.map { Self.prefix + $0.uuidString })
        }

        public func scheduledIDs() async -> Set<UUID> {
            await Set(center.pendingNotificationRequests().compactMap { request in
                request.identifier.hasPrefix(Self.prefix)
                    ? UUID(uuidString: String(request.identifier.dropFirst(Self.prefix.count))) : nil
            })
        }
    }
#endif
