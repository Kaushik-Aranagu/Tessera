import SwiftUI
import TesseraCore

/// The cover's content for a live workout: the whole-blackboard mode when it is on, the older live screen otherwise.
/// On with the `workoutMode.chalk` default (the phone) or the `-workoutChalk` launch flag (the simulator); Core has no
/// feature flag for it yet, so the switch is this one line.
struct WorkoutCover: View {
    @Environment(AppModel.self) private var model
    /// The keystone's slot on the Deck, so the screen grows from it (sheet 330); empty falls back to a plain open.
    var from: CGRect = ModeOpenFrames.keystone

    static var isChalkOn: Bool {
        // On by default; the old screen only when it is explicitly turned off (the `workoutMode.chalk` default set to
        // false, or `-workoutChalkOff` on the simulator, for tests of the old screen).
        if LaunchFlags.has("-workoutChalkOff") {
            return false
        }
        if LaunchFlags.has("-workoutChalk") {
            return true
        }
        return UserDefaults.standard.object(forKey: "workoutMode.chalk") as? Bool ?? true
    }

    var body: some View {
        if Self.isChalkOn, let session = model.session {
            WorkoutModeHost(session: session)
                .modeGrow(from: from)
        } else {
            WorkoutModeView()
        }
    }
}

/// Maps the screen's moves onto the live `WorkoutSession` (every write still goes through Core's ActionEngine).
struct WorkoutModeHost: View {
    let session: WorkoutSession
    @Environment(AppModel.self) private var model
    @State private var state: WorkoutModeState?

    var body: some View {
        // Built once, on first appearance: the screen owns its state from there.
        Group {
            if let state {
                WorkoutModeScreen(state: state, actions: actions)
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            if state == nil {
                let made = WorkoutModeState.make(from: session, warmUp: CoreWarmUp())
                state = made
                publish(made)
            }
        }
        .onDisappear {
            ModeLiveBridge.current = nil
            RestActivityController.shared.update(for: session)
        }
    }

    private var actions: WorkoutModeActions {
        WorkoutModeActions(
            close: { model.isWorkoutPresented = false },
            logged: { liftID, weight, reps in log(liftID: liftID, weight: weight, reps: reps) },
            finished: { session.finish() },
            undone: {
                session.undoLastSet()
                RestActivityController.shared.update(for: session)
            },
            changed: { state in publish(state) }
        )
    }

    /// Tells the lock screen what the mode says now (one activity, fed through the rest controller).
    private func publish(_ state: WorkoutModeState) {
        ModeLiveBridge.current = ModeLiveContent.workout(state, at: AppClock.now)
        RestActivityController.shared.update(for: session)
    }

    private func log(liftID: String, weight: Double, reps: Int) {
        guard let index = session.entries.firstIndex(where: { $0.id.uuidString == liftID }) else { return }
        session.select(entryAt: index)
        session.weight = Format.unit.toKilograms(weight)
        session.reps = Double(reps)
        session.logSet()
        RestActivityController.shared.update(for: session)
    }
}
