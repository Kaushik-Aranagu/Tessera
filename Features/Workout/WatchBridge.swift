import Foundation
import Observation
import WatchConnectivity

/// The phone's end of the wrist (docs/design/watch-set-logging-105.md). The phone is the source of truth: this builds a
/// `WatchSnapshot` from the live `WorkoutSession` and pushes it as the application context, and it applies the Watch's
/// `WatchCommand`s through the same session calls the phone's own Done uses, so the ledger shows no difference.
/// WatchConnectivity needs no entitlement, so it works on the free team.
@MainActor
final class WatchBridge: NSObject {
    static let shared = WatchBridge()

    weak var model: AppModel?
    private var revision = 0
    private var lastSent: WatchSnapshot?
    private var isActive = false

    override private init() {
        super.init()
    }

    /// Starts the session (once, at launch). A no-op where there is no Watch to talk to.
    func start(model: AppModel) {
        self.model = model
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Pushes the current state when it changed. Called wherever the Live Activity is refreshed.
    func update(for session: WorkoutSession?) {
        guard isActive else { return }
        var snapshot = WatchSnapshotMapper.snapshot(of: session)
        snapshot.revision = lastSent?.revision ?? 0
        guard snapshot != lastSent else { return }
        revision += 1
        snapshot.revision = revision
        lastSent = snapshot
        guard let data = snapshot.encoded() else { return }
        try? WCSession.default.updateApplicationContext([WatchLink.snapshotKey: data])
    }

    /// Tests drive the same path a received message takes.
    @discardableResult
    func applyForTesting(_ command: WatchCommand) -> Bool {
        apply(command)
    }

    @discardableResult
    fileprivate func apply(_ command: WatchCommand) -> Bool {
        guard let model else { return false }
        var accepted = true
        switch command {
        case .hello:
            lastSent = nil
        case let .logSet(weight, reps):
            guard let session = model.session else { break }
            if let entry = session.currentEntry, session.isFinished(entry), let next = session.nextUnfinishedIndex {
                session.select(entryAt: next)
            }
            let untouched = session.weight == weight && Int(session.reps) == reps
            session.weight = weight
            session.reps = Double(reps)
            session.logSet(source: untouched ? .hold : .dial)
        case let .undo(setID):
            // Only the set the wrist named: one logged on the phone since is not touched.
            let latest = model.session?.undoable?.setID.uuidString
            if WatchUndo.accepts(requested: setID, latest: latest), model.session?.canUndo == true {
                model.session?.undoLastSet()
            } else {
                accepted = false
            }
        case let .extendRest(seconds):
            model.session?.extendRest(by: TimeInterval(seconds))
        case .skipRest:
            model.session?.skipRest()
        }
        RestActivityController.shared.update(for: model.session)
        update(for: model.session)
        return accepted
    }
}

extension WatchBridge: WCSessionDelegate {
    nonisolated func session(_: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                             error _: Error?)
    {
        let active = state == .activated
        Task { @MainActor in
            self.isActive = active
            self.lastSent = nil
            self.update(for: self.model?.session)
        }
    }

    nonisolated func sessionDidBecomeInactive(_: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in
            self.lastSent = nil
            self.update(for: self.model?.session)
        }
    }

    nonisolated func session(_: WCSession, didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void)
    {
        guard let data = message[WatchLink.commandKey] as? Data, let command = WatchCommand.decode(data) else {
            replyHandler(["ok": false])
            return
        }
        nonisolated(unsafe) let reply = replyHandler
        Task { @MainActor in reply(["ok": self.apply(command)]) }
    }

    nonisolated func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        guard let data = message[WatchLink.commandKey] as? Data, let command = WatchCommand.decode(data) else { return }
        Task { @MainActor in self.apply(command) }
    }
}

/// Session → snapshot, in the units the phone shows. Masked at source: a private workout carries no exercise name.
@MainActor
enum WatchSnapshotMapper {
    static func snapshot(of session: WorkoutSession?) -> WatchSnapshot {
        guard let session else { return .idle }
        let unit = Format.unit.symbol
        let step = Format.unit == .kilograms ? 2.5 : 5
        let isPrivate = session.shownTitle != session.workout.title
        let phase = session.phase()
        let entry = session.currentEntry
        let name = isPrivate ? "Private workout" : (session.currentExercise?.name ?? entry?.title ?? "")
        let rows = entry.map(session.setRows(of:)) ?? []
        let latest = rows.reversed().prefix(6)
        let sets = latest.map { WatchSnapshot.line(weight: $0.weight, reps: Int($0.reps)) }
        let setIDs = latest.map(\.id.uuidString)
        let count = entry.map(session.targetSets(of:)) ?? 0
        let state: WatchSnapshot.Phase
        var restEnd: Date?
        switch phase {
        case .workoutDone:
            state = .finished
        case let .rest(end):
            state = .rest
            restEnd = end
        case .set, .exerciseDone:
            state = .set
        }
        // The Watch counts down in real time; the phone's rest end is in app time (-demoTime may shift it).
        let shift = Date.now.timeIntervalSince(AppClock.now)
        return WatchSnapshot(phase: state, exercise: name, setNumber: session.currentSetNumber, setCount: count,
                             weight: session.weight, reps: Int(session.reps), unit: unit, weightStep: step,
                             restEndsAt: restEnd
                                 .map {
                                     Date(timeIntervalSinceReferenceDate: $0.addingTimeInterval(shift)
                                         .timeIntervalSinceReferenceDate.rounded())
                                 }, restTotal: session.restTotal, sets: sets,
                             setIDs: setIDs,
                             isPrivate: isPrivate, revision: 0)
    }
}
