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
    /// Activities this controller has ended and the system may still list: never adopted again.
    private var endedIDs: Set<String> = []
    private var lastState: State?
    /// Serialises the async ActivityKit calls so they land in order.
    private var queue: Task<Void, Never>?
    /// Flips the activity to "ready" when the rest runs out while the app is alive.
    private var readyTimer: Task<Void, Never>?
    /// The one scheduled end of the closing face (about a minute after the last set).
    private var closingEnd: Task<Void, Never>?
    static let closingLife: TimeInterval = 60

    private init() {}

    func update(for session: WorkoutSession?) {
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
        // Anything but the closing face (an undone last set, a new rest) cancels its scheduled end. The closing
        // face's activity is already ended (iOS removes it on its own at 60 s), so an undo takes it away now and the
        // next rest starts a fresh one.
        closingEnd?.cancel()
        closingEnd = nil
        if lastState?.phase == .closing {
            activity = nil
            lastState = nil
            // Only the activities listed now: one requested later in this update must survive the queued end.
            let ids = Set(Activity<RestActivityAttributes>.activities.map(\.id))
            endedIDs.formUnion(ids)
            enqueue { await Self.end(ids: ids) }
        }
        if workoutID != nil, workoutID != session.workout.id {
            end()
        }
        // The attributes' title is fixed when the activity starts: a workout that turns private (or public) mid-session
        // ends the activity so the next rest starts one with the right title.
        if Self.needsRestart(shownPrivate: lastState?.isPrivate, nowPrivate: session.isPrivate) {
            end()
        }
        let realNow = Date.now
        // Masked at the source: a private workout's exercise, weight, reps and set number never reach the activity.
        let state = Self.contentState(planned: session.isPrivate ? Self.maskedSet : planned,
                                      restEndsAt: session.restEndsAt, restTotal: session.restTotal,
                                      appNow: AppClock.adjust(realNow), realNow: realNow, isPrivate: session.isPrivate)
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
            // An activity this controller already ended (a privacy flip) can still be listed for a moment: not it.
            let listed = Activity<RestActivityAttributes>.activities
            endedIDs.formIntersection(listed.map(\.id))
            let pick = Self.adoptable(listed.map { ($0.id, $0.activityState == .active) }, excluding: endedIDs)
            activity = listed.first { $0.id == pick }
            if activity != nil {
                workoutID = session.workout.id
            }
        }
        if let activity {
            lastState = state
            let id = activity.id, content = Self.content(state)
            // The activity carries no alert: the rest end rings as one local notification (RestAlert).
            enqueue { await Self.push(content, to: id) }
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

    /// The first active activity that was not ended by this controller (the id of the one to adopt, if any).
    static func adoptable(_ listed: [(id: String, isActive: Bool)], excluding ended: Set<String>) -> String? {
        listed.first { $0.isActive && !ended.contains($0.id) }?.id
    }

    /// Whether the running activity was started under the other privacy: it must end so the title is remade.
    static func needsRestart(shownPrivate: Bool?, nowPrivate: Bool) -> Bool {
        guard let shownPrivate else { return false }
        return shownPrivate != nowPrivate
    }

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

    /// What a private workout's activity carries in place of the planned set: nothing.
    static let maskedSet = PlannedSet(exercise: "", setNumber: 0, weight: 0, reps: 0)

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
                             realNow: Date, followsLook: Bool = Choice.lockScreenFollowsLook(),
                             isPrivate: Bool = false) -> State
    {
        let shift = realNow.timeIntervalSince(appNow)
        let isResting = restEndsAt.map { $0 > appNow } ?? false
        let endsAt = (restEndsAt ?? appNow).addingTimeInterval(shift).timeIntervalSinceReferenceDate.rounded()
        return State(exercise: planned.exercise, setNumber: planned.setNumber, weight: planned.weight,
                     reps: planned.reps,
                     restEndsAt: isResting ? Date(timeIntervalSinceReferenceDate: endsAt) : .distantPast,
                     restTotal: restTotal, phase: isResting ? .resting : .ready,
                     lookDay: followsLook ? ThemeStore.shared.pair.day.name : nil,
                     lookNight: followsLook ? ThemeStore.shared.pair.night.name : nil,
                     isPrivate: isPrivate)
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
            self.update(for: session)
        }
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
        // The face is the activity's final content, dismissed by iOS 60 s out: a locked phone cannot keep it for
        // hours when the app is suspended and its own timer never runs.
        let dismissAt = Self.closingDismissal(from: .now)
        enqueue { await Self.endClosing(content, to: id, dismissAt: dismissAt) }
        closingEnd?.cancel()
        closingEnd = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Self.closingLife))
            guard !Task.isCancelled else { return }
            self.end()
        }
    }

    /// When the system removes the closing face: 60 s after it appears, whatever the app is doing (locked and
    /// suspended included).
    static func closingDismissal(from now: Date) -> Date {
        now.addingTimeInterval(closingLife)
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
        let listed = Activity<RestActivityAttributes>.activities
        let hadActivities = !listed.isEmpty
        endedIDs.formUnion(listed.map(\.id))
        activity = nil
        workoutID = nil
        lastState = nil
        guard hadActivities else { return }
        let ids = Set(listed.map(\.id))
        enqueue { await Self.end(ids: ids) }
    }

    /// `Activity` isn't Sendable: the ActivityKit calls run off the main actor on activities looked up there.
    private nonisolated static func push(_ content: ActivityContent<State>, to id: String) async {
        guard let activity = Activity<RestActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.update(content)
    }

    private nonisolated static func endClosing(_ content: ActivityContent<State>, to id: String,
                                               dismissAt: Date) async
    {
        guard let activity = Activity<RestActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.end(content, dismissalPolicy: .after(dismissAt))
    }

    /// Ends exactly the activities that were listed when the end was asked for, never one requested after.
    private nonisolated static func end(ids: Set<String>) async {
        let listed = Activity<RestActivityAttributes>.activities
        let doomed = Set(idsToEnd(listed: listed.map(\.id), captured: ids))
        for activity in listed where doomed.contains(activity.id) {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// Of the activities listed now, those captured when the end was queued (a later request is not among them).
    nonisolated static func idsToEnd(listed: [String], captured: Set<String>) -> [String] {
        listed.filter { captured.contains($0) }
    }

    private func enqueue(_ work: @escaping @Sendable () async -> Void) {
        let previous = queue
        queue = Task {
            await previous?.value
            await work()
        }
    }
}
