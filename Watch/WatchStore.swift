import Foundation
import Observation
import WatchConnectivity
import WatchKit

/// The wrist's state: the phone's last snapshot plus what is being dialled here. The phone owns the workout; this
/// only asks (`send`) and shows what comes back.
@MainActor
@Observable
final class WatchStore: NSObject {
    private(set) var snapshot = WatchSnapshot.idle
    var weight: Double = 0
    var reps: Int = 0
    /// Which numeral the Digital Crown moves.
    var crownMovesWeight = true
    /// "Set 4, removed." for ten seconds after an undo; UNDO beside it logs the removed set back.
    private(set) var undoNote: String?
    /// The set that was just taken out, for the UNDO word.
    private(set) var removed: (weight: Double, reps: Int)?
    /// THIS EXERCISE is showing over the set screen.
    var sideShown = false
    private(set) var writeFailed = false
    private var undoTask: Task<Void, Never>?
    private var restTask: Task<Void, Never>?

    func start() {
        #if targetEnvironment(simulator)
            // Simulator only: `-demoSet` / `-demoRest` / `-demoPrivate` show a face without a paired phone.
            let args = CommandLine.arguments
            if args.contains("-demoSet") || args.contains("-demoRest") || args.contains("-demoPrivate") {
                var demo = WatchSnapshot.idle
                demo.phase = args.contains("-demoRest") ? .rest : .set
                demo.exercise = args.contains("-demoPrivate") ? "Private workout" : "Incline Dumbbell Press"
                demo.isPrivate = args.contains("-demoPrivate")
                demo.setNumber = 4
                demo.setCount = 5
                demo.weight = 82.5
                demo.reps = 8
                demo.restTotal = 120
                demo.restEndsAt = Date.now.addingTimeInterval(95)
                demo.sets = ["82.5 x 8", "82.5 x 8", "80 x 8"]
                take(demo)
                return
            }
        #endif
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// The numerals reopen on the phone's prefill whenever the set (or the exercise) changes under us.
    private func take(_ next: WatchSnapshot) {
        guard next.revision >= snapshot.revision || next.phase == .idle else { return }
        let reopened = next.setNumber != snapshot.setNumber || next.exercise != snapshot.exercise
            || next.phase != snapshot.phase || next.weight != snapshot.weight || next.reps != snapshot.reps
        snapshot = next
        if reopened {
            weight = next.weight
            reps = next.reps
        }
        armRestEnd()
    }

    /// One wrist tap when the rest ends (the only haptic the set screen adds).
    private func armRestEnd() {
        restTask?.cancel()
        guard snapshot.phase == .rest, let end = snapshot.restEndsAt else { return }
        restTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(max(end.timeIntervalSinceNow, 0)))
            guard !Task.isCancelled else { return }
            WKInterfaceDevice.current().play(.notification)
        }
    }

    // MARK: Asking the phone

    func done() {
        send(.logSet(weight: weight, reps: reps))
        undoNote = nil
        removed = nil
    }

    func undo() {
        // The set the wrist can see is the one it removes, with exactly its numbers; the phone takes it out only if it
        // is still the latest, and the note appears only once the phone says so.
        guard let removal = WatchUndo.removal(in: snapshot) else {
            say("Not removed.", removed: nil)
            return
        }
        let number = max(snapshot.setNumber - 1, 1)
        send(.undo(setID: removal.setID)) { [weak self] done in
            guard let self else { return }
            if done {
                say("Set \(number), removed.", removed: (removal.weight, removal.reps))
            } else {
                say("Not removed.", removed: nil)
            }
        }
    }

    /// Shows a line under the numerals for ten seconds; UNDO shows beside it only when a set was taken out.
    private func say(_ note: String, removed: (weight: Double, reps: Int)?) {
        self.removed = removed
        undoNote = note
        undoTask?.cancel()
        undoTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            undoNote = nil
            self.removed = nil
        }
    }

    /// UNDO beside "Set 4, removed.": logs the removed weight and reps back.
    func putBack() {
        guard let removed else { return }
        undoTask?.cancel()
        undoNote = nil
        self.removed = nil
        weight = removed.weight
        reps = removed.reps
        send(.logSet(weight: removed.weight, reps: removed.reps))
    }

    func extendRest() {
        send(.extendRest(seconds: 15))
    }

    func skipRest() {
        send(.skipRest)
    }

    /// Sends a command; with `confirm`, the phone's yes or no comes back to it (no reply, or a failed send, is a no).
    private func send(_ command: WatchCommand, confirm: (@MainActor (Bool) -> Void)? = nil) {
        guard let data = command.encoded() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else {
            fail()
            confirm?(false)
            return
        }
        session.sendMessage([WatchLink.commandKey: data], replyHandler: { reply in
            let ok = reply["ok"] as? Bool ?? false
            Task { @MainActor in confirm?(ok) }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in
                self?.fail()
                confirm?(false)
            }
        })
    }

    /// A failed write: one soft warning, the only warning.
    private func fail() {
        writeFailed = true
        WKInterfaceDevice.current().play(.failure)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            writeFailed = false
        }
    }
}

extension WatchStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                             error _: Error?)
    {
        let data = session.receivedApplicationContext[WatchLink.snapshotKey] as? Data
        if state == .activated, session.isReachable, let hello = WatchCommand.hello.encoded() {
            session.sendMessage([WatchLink.commandKey: hello], replyHandler: nil, errorHandler: nil)
        }
        Task { @MainActor in self.read(data) }
    }

    nonisolated func session(_: WCSession, didReceiveApplicationContext context: [String: Any]) {
        let data = context[WatchLink.snapshotKey] as? Data
        Task { @MainActor in self.read(data) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable, let hello = WatchCommand.hello.encoded() else { return }
        session.sendMessage([WatchLink.commandKey: hello], replyHandler: nil, errorHandler: nil)
    }

    private func read(_ data: Data?) {
        guard let data, let next = WatchSnapshot.decode(data) else { return }
        take(next)
    }
}
