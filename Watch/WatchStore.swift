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
    /// The numbers last sent with Done, for the undo that follows.
    private var lastLogged: (weight: Double, reps: Int)?
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
        lastLogged = (weight, reps)
        send(.logSet(weight: weight, reps: reps))
        undoNote = nil
        removed = nil
    }

    func undo() {
        let number = max(snapshot.setNumber - 1, 1)
        removed = lastLogged ?? Self.numbers(in: snapshot.sets.first)
        send(.undo)
        undoNote = "Set \(number), removed."
        undoTask?.cancel()
        undoTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            undoNote = nil
            removed = nil
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
        lastLogged = removed
        send(.logSet(weight: removed.weight, reps: removed.reps))
    }

    /// "82.5 x 8" back into numbers, when the app has not logged a set itself this run.
    private static func numbers(in line: String?) -> (weight: Double, reps: Int)? {
        guard let parts = line?.split(separator: " ").filter({ $0 != "x" && $0 != "×" }), parts.count == 2,
              let weight = Double(parts[0]), let reps = Int(parts[1]) else { return nil }
        return (weight, reps)
    }

    func extendRest() {
        send(.extendRest(seconds: 15))
    }

    func skipRest() {
        send(.skipRest)
    }

    private func send(_ command: WatchCommand) {
        guard let data = command.encoded() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else {
            fail()
            return
        }
        session.sendMessage([WatchLink.commandKey: data], replyHandler: nil) { [weak self] _ in
            Task { @MainActor in self?.fail() }
        }
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
                             error: Error?)
    {
        let data = session.receivedApplicationContext[WatchLink.snapshotKey] as? Data
        if state == .activated, session.isReachable, let hello = WatchCommand.hello.encoded() {
            session.sendMessage([WatchLink.commandKey: hello], replyHandler: nil, errorHandler: nil)
        }
        Task { @MainActor in self.read(data) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
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
