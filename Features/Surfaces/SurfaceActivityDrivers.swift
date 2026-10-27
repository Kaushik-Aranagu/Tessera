import ActivityKit
import Foundation
import TesseraCore

/// Surfaces v2 (Design 142): the Live Activities beyond Training's rest face. Cook is driven from the cook clock page;
/// Routine is built but not started by anything yet (see `RoutineActivityDriver`). All of it needs the Review switch
/// "Surfaces v2" On, and everything is masked before it reaches an activity.
@MainActor
enum SurfaceActivityDrivers {
    /// Training: sets done and planned for the exercise the rest is before. Nil when there is nothing left to log.
    static func marks(for session: WorkoutSession) -> (done: Int, total: Int)? {
        let entry: ObjectRecord? = switch session.phase() {
        case .exerciseDone: session.nextUnfinishedIndex.map { session.entries[$0] }
        case .set, .rest: session.currentEntry
        case .workoutDone: nil
        }
        guard let entry else { return nil }
        let done = session.setRows(of: entry).count
        let total = session.targetSets(of: entry)
        return (done, max(total, done + 1))
    }
}

/// Cook: the soonest timer, the others as "+2", the next step. One activity per cook page; it ends when no timer runs
/// or the switch is Off.
@MainActor
final class CookActivityDriver {
    static let shared = CookActivityDriver()
    private var activityID: String?
    private var cookID: UUID?
    private init() {}

    func update(for session: CookClockSession?) {
        guard SurfacesWriter.isOn, let session, !session.model.isSample else {
            end()
            return
        }
        let inputs = session.timers.map { CookTimerInput(label: $0.label, endsAt: $0.endsAt, startedAt: $0.startedAt) }
        let next = session.steps.indices.contains(session.current + 1)
            ? CookFace.shortStep(session.text(of: session.current + 1)) : nil
        let realNow = Date.now
        guard var state = CookFace.state(timers: inputs, nextStep: next, isPrivate: session.isPrivate,
                                         appNow: AppClock.adjust(realNow), realNow: realNow)
        else {
            end()
            return
        }
        // Sheet 344: the link opens the ticket with the alert printed.
        state.link = CookFace.alertLink(cook: session.cookID, food: state.readyFood)
        let content = ActivityContent(state: state, staleDate: state.endsAt.addingTimeInterval(60))
        if let id = activityID, cookID == session.cookID {
            Task { await Self.push(id: id, content) }
            return
        }
        end()
        let name = session.isPrivate ? CookFace.privateRecipe : session.recipeName
        activityID = (try? Activity.request(attributes: CookActivityAttributes(recipeName: name), content: content))?.id
        cookID = session.cookID
    }

    func end() {
        guard let id = activityID else { return }
        activityID = nil
        cookID = nil
        Task { await Self.finish(id: id) }
    }

    private nonisolated static func push(
        id: String,
        _ content: ActivityContent<CookActivityAttributes.ContentState>
    ) async {
        await Activity<CookActivityAttributes>.activities.first { $0.id == id }?.update(content)
    }

    private nonisolated static func finish(id: String) async {
        await Activity<CookActivityAttributes>.activities.first { $0.id == id }?.end(nil, dismissalPolicy: .immediate)
    }
}

/// Routine: its step with the Thread. Built and ready, but nothing starts it yet: the only routines that run today are
/// workout routines, and those already have the Training rest activity (a second activity for the same workout would
/// double it). The default runner for morning and night routines starts this one.
@MainActor
final class RoutineActivityDriver {
    static let shared = RoutineActivityDriver()
    private var activityID: String?
    private init() {}

    func update(name: String, step: String, position: Int, count: Int, startedAt: Date, isPrivate: Bool) {
        guard SurfacesWriter.isOn else {
            end()
            return
        }
        let state = RoutineFace.state(step: step, position: position, count: count, startedAt: startedAt,
                                      isPrivate: isPrivate)
        let content = ActivityContent(state: state, staleDate: nil)
        if let id = activityID {
            Task { await Self.push(id: id, content) }
            return
        }
        let shown = isPrivate ? "Private routine" : name
        activityID = (try? Activity.request(attributes: RoutineActivityAttributes(routineName: shown),
                                            content: content))?.id
    }

    func end() {
        guard let id = activityID else { return }
        activityID = nil
        Task { await Self.finish(id: id) }
    }

    private nonisolated static func push(id: String,
                                         _ content: ActivityContent<RoutineActivityAttributes.ContentState>) async
    {
        await Activity<RoutineActivityAttributes>.activities.first { $0.id == id }?.update(content)
    }

    private nonisolated static func finish(id: String) async {
        await Activity<RoutineActivityAttributes>.activities.first { $0.id == id }?.end(
            nil,
            dismissalPolicy: .immediate
        )
    }
}
