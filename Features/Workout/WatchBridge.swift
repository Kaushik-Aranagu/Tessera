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

    private override init() {
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
    func applyForTesting(_ command: WatchCommand) {
        apply(command)
    }

    fileprivate func apply(_ command: WatchCommand) {
        guard let model else { return }
        switch command {
        case .hello:
            lastSent = nil
        case .logSet(let weight, let reps):
            guard let session = model.session else { break }
            if let entry = session.currentEntry, session.isFinished(entry), let next = session.nextUnfinishedIndex {
                session.select(entryAt: next)
            }
            let untouched = session.weight == weight && Int(session.reps) == reps
            session.weight = weight
            session.reps = Double(reps)
            session.logSet(source: untouched ? .hold : .dial)
        case .undo:
            model.session?.undoLastSet()
        case .extendRest(let seconds):
            model.session?.extendRest(by: TimeInterval(seconds))
        case .skipRest:
            model.session?.skipRest()
        }
        RestActivityController.shared.update(for: model.session)
        update(for: model.session)
    }
}

extension WatchBridge: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?)
    {
        let active = state == .activated
        Task { @MainActor in
            self.isActive = active
            self.lastSent = nil
            self.update(for: self.model?.session)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

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

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
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
        let sets = rows.reversed().prefix(6).map {
            WatchSnapshot.line(weight: $0.weight, reps: Int($0.reps))
        }
        let count = entry.map(session.targetSets(of:)) ?? 0
        let state: WatchSnapshot.Phase
        var restEnd: Date?
        switch phase {
        case .workoutDone:
            state = .finished
        case .rest(let end):
            state = .rest
            restEnd = end
        case .set, .exerciseDone:
            state = .set
        }
        // The Watch counts down in real time; the phone's rest end is in app time (-demoTime may shift it).
        let shift = Date.now.timeIntervalSince(AppClock.now)
        return WatchSnapshot(phase: state, exercise: name, setNumber: session.currentSetNumber, setCount: count,
                             weight: session.weight, reps: Int(session.reps), unit: unit, weightStep: step,
                             restEndsAt: restEnd.map { Date(timeIntervalSinceReferenceDate: $0.addingTimeInterval(shift).timeIntervalSinceReferenceDate.rounded()) }, restTotal: session.restTotal, sets: sets,
                             isPrivate: isPrivate, revision: 0)
    }
}
