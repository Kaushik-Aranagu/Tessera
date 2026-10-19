import ActivityKit
import Foundation

/// Drives the rest-timer Live Activity from the live `WorkoutSession`. Idempotent: call `update(for:)` whenever the
/// session might have changed and it starts, updates, flips to "ready" or ends the activity as needed.
@MainActor
final class RestActivityController {
    static let shared = RestActivityController()

    typealias State = RestActivityAttributes.ContentState

    private var activity: Activity<RestActivityAttributes>?
    private var workoutID: UUID?
    private var lastState: State?
    /// Serialises the async ActivityKit calls so they land in order.
    private var queue: Task<Void, Never>?
    /// Flips the activity to "ready" when the rest runs out while the app is alive.
    private var readyTimer: Task<Void, Never>?
    /// The rest end that has already played its alert, so it never repeats.
    private var alertedRestEnd: Date?
    /// The one scheduled end of the closing face (about a minute after the last set).
    private var closingEnd: Task<Void, Never>?
    static let closingLife: Duration = .seconds(60)

    private init() {}

    func update(for session: WorkoutSession?) {
        update(for: session, restRanOut: false)
    }

    private func update(for session: WorkoutSession?, restRanOut: Bool) {
        guard let session else {
            FinishNudges.shared.sync(workoutID: nil, workoutTitle: "", lastSetAt: nil, enabled: false)
            end()
            return
        }
        // The forgot-Finish nudge follows the last set (a no-op unless its switch is On).
        FinishNudges.shared.sync(workoutID: session.workout.id, workoutTitle: session.shownTitle,
                                 lastSetAt: session.lastTouchedAt, enabled: Choice.finishNudgeIsOn())
        guard let planned = Self.plannedSet(of: session) else {
            showClosingFace(for: session)
            return
        }
        // Anything but the closing face (an undone last set, a new rest) cancels its scheduled end.
        closingEnd?.cancel()
        closingEnd = nil
        if workoutID != nil, workoutID != session.workout.id {
            end()
        }
        let realNow = Date.now
        let state = Self.contentState(planned: planned, restEndsAt: session.restEndsAt,
                                      restTotal: session.restTotal, appNow: AppClock.adjust(realNow), realNow: realNow)
        scheduleReadyFlip(for: state, session: session)
        // The rest-end alert is one local notification when the switch is On; Off keeps the activity's own alert.
        RestAlerts.shared.sync(fireAt: RestAlertPlan.fireAt(
            restEndsAt: session.restEndsAt,
            appNow: AppClock.adjust(realNow),
            realNow: realNow,
            enabled: Choice.restTimerIsOn()
        ))
        guard state != lastState else { return }

        if let current = activity, current.activityState != .active, current.activityState != .stale {
            // Dismissed from the Lock Screen or ended by the system: start afresh at the next rest.
            activity = nil
        }
        if activity == nil {
            activity = Activity<RestActivityAttributes>.activities.first { $0.activityState == .active }
            if activity != nil {
                workoutID = session.workout.id
            }
        }
        if let activity {
            let alert = restRanOut ? restEndAlert(from: lastState, to: state) : nil
            lastState = state
            let id = activity.id, content = Self.content(state)
            enqueue { await Self.push(content, alert: alert, to: id) }
        } else if state.phase == .resting, ActivityAuthorizationInfo().areActivitiesEnabled {
            // The activity starts when the first rest begins.
            let attributes = Self.attributes(for: session)
            do {
                activity = try Activity.request(attributes: attributes, content: Self.content(state), pushType: nil)
                workoutID = session.workout.id
                lastState = state
            } catch {
                activity = nil
            }
        }
    }

    // MARK: Mapping

    /// The Live Activity's fixed attributes. The title is masked: the Lock Screen and Dynamic Island show it without
    /// unlocking, so a private routine reads "Private workout" there.
    static func attributes(for session: WorkoutSession) -> RestActivityAttributes {
        RestActivityAttributes(workoutTitle: session.shownTitle)
    }

    /// The set the Done button logs: the dialled set, or the next exercise's opening set once this one is done
    /// (Done pages on first, like the key does in the app). Nil when the workout has nothing left to log.
    struct PlannedSet: Equatable {
        var exercise: String
        var setNumber: Int
        var weight: Double
        var reps: Int
    }

    static func plannedSet(of session: WorkoutSession) -> PlannedSet? {
        switch session.phase() {
        case .workoutDone:
            return nil
        case .exerciseDone:
            guard let index = session.nextUnfinishedIndex else { return nil }
            let entry = session.entries[index]
            let last = session.setRows(of: entry).last
            return PlannedSet(exercise: session.exerciseClass(of: entry)?.name ?? entry.title,
                              setNumber: session.setRows(of: entry).count + 1,
                              weight: last?.weight ?? session.targetWeight(of: entry) ?? 20,
                              reps: Int(last?.reps ?? session.targetReps(of: entry)))
        case .set, .rest:
            return PlannedSet(exercise: session.currentExercise?.name ?? session.currentEntry?.title ?? "",
                              setNumber: session.currentSetNumber, weight: session.weight, reps: Int(session.reps))
        }
    }

    /// Pure session → content mapping. `restEndsAt` is in app time (which `-demoTime` may shift); the activity
    /// counts down in real time, so it is moved onto the real clock (rounded to the second so repeated calls map to
    /// an identical state). Once ready, the end is pinned to `.distantPast` for the same reason.
    static func contentState(planned: PlannedSet, restEndsAt: Date?, restTotal: TimeInterval, appNow: Date,
                             realNow: Date) -> State
    {
        let shift = realNow.timeIntervalSince(appNow)
        let isResting = restEndsAt.map { $0 > appNow } ?? false
        let endsAt = (restEndsAt ?? appNow).addingTimeInterval(shift).timeIntervalSinceReferenceDate.rounded()
        return State(exercise: planned.exercise, setNumber: planned.setNumber, weight: planned.weight,
                     reps: planned.reps,
                     restEndsAt: isResting ? Date(timeIntervalSinceReferenceDate: endsAt) : .distantPast,
                     restTotal: restTotal, phase: isResting ? .resting : .ready,
                     lookDay: ThemeStore.shared.pair.day.name, lookNight: ThemeStore.shared.pair.night.name)
    }

    /// While resting the content goes stale when the rest ends, so the Lock Screen flips to "ready" on its own even
    /// if the app is suspended.
    /// How long "Go" stays up with nothing logged before the Lock Screen calls the session set aside.
    static let readyLife: TimeInterval = 10 * 60

    private static func content(_ state: State) -> ActivityContent<State> {
        // Resting goes stale when the rest ends (the face flips to Go); ready goes stale ten minutes on (the face
        // reads "set aside", late-night.md #12).
        let stale: Date? = switch state.phase {
        case .resting: state.restEndsAt
        case .ready: Date.now.addingTimeInterval(readyLife)
        case .closing: nil
        }
        return ActivityContent(state: state, staleDate: stale, relevanceScore: state.phase == .resting ? 100 : 50)
    }

    // MARK: Plumbing

    private func scheduleReadyFlip(for state: State, session: WorkoutSession) {
        readyTimer?.cancel()
        readyTimer = nil
        guard state.phase == .resting, let end = session.restEndsAt else { return }
        let delay = end.timeIntervalSince(AppClock.now)
        readyTimer = Task { [weak session] in
            try? await Task.sleep(for: .seconds(max(delay, 0) + 0.05))
            guard !Task.isCancelled, let session else { return }
            self.update(for: session, restRanOut: true)
        }
    }

    /// One alert, at the moment rest runs out (not on Skip), never repeated for the same rest.
    private func restEndAlert(from old: State?, to new: State) -> AlertConfiguration? {
        // On: the local notification rings instead, and the activity carries no alert.
        guard !Choice.restTimerIsOn() else { return nil }
        guard let old, old.phase == .resting, new.phase == .ready, alertedRestEnd != old.restEndsAt else { return nil }
        alertedRestEnd = old.restEndsAt
        return AlertConfiguration(title: "Set \(new.setNumber) is up", body: "\(new.exercise), \(new.plannedSet)",
                                  sound: .default)
    }

    /// The last set logged: the activity does not end at once. It shows one still face, "<title>, ready to finish"
    /// (masked for a private workout), then ends after about a minute. With no activity there is nothing to close.
    private func showClosingFace(for session: WorkoutSession) {
        readyTimer?.cancel()
        readyTimer = nil
        RestAlerts.shared.sync(fireAt: nil)
        if activity == nil {
            activity = Activity<RestActivityAttributes>.activities.first { $0.activityState == .active }
        }
        guard let activity, var state = lastState else {
            end()
            return
        }
        guard state.phase != .closing else { return }
        state.phase = .closing
        state.restEndsAt = .distantPast
        state.closingLine = Self.closingLine(title: session.shownTitle)
        lastState = state
        let id = activity.id, content = Self.content(state)
        enqueue { await Self.push(content, alert: nil, to: id) }
        closingEnd?.cancel()
        closingEnd = Task { @MainActor in
            try? await Task.sleep(for: Self.closingLife)
            guard !Task.isCancelled else { return }
            self.end()
        }
    }

    /// "Push A, ready to finish"; a private workout reads "Private workout, ready to finish".
    static func closingLine(title: String) -> String {
        "\(title), ready to finish"
    }

    private func end() {
        readyTimer?.cancel()
        readyTimer = nil
        closingEnd?.cancel()
        closingEnd = nil
        RestAlerts.shared.sync(fireAt: nil)
        let hadActivities = !Activity<RestActivityAttributes>.activities.isEmpty
        activity = nil
        workoutID = nil
        lastState = nil
        guard hadActivities else { return }
        enqueue { await Self.endAll() }
    }

    /// `Activity` isn't Sendable: the ActivityKit calls run off the main actor on activities looked up there.
    private nonisolated static func push(_ content: ActivityContent<State>, alert: AlertConfiguration?,
                                         to id: String) async
    {
        guard let activity = Activity<RestActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.update(content, alertConfiguration: alert)
    }

    private nonisolated static func endAll() async {
        for activity in Activity<RestActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func enqueue(_ work: @escaping @Sendable () async -> Void) {
        let previous = queue
        queue = Task {
            await previous?.value
            await work()
        }
    }
}
