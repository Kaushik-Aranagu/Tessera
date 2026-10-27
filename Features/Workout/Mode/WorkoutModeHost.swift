import SwiftUI
import TesseraCore

/// The cover's content for a live workout: the whole-blackboard mode when it is on, the older live screen otherwise.
/// On with the `workoutMode.chalk` default (the phone) or the `-workoutChalk` launch flag (the simulator); Core has no
/// feature flag for it yet, so the switch is this one line.
struct WorkoutCover: View {
    @Environment(AppModel.self) private var model
    /// The keystone's slot on the Deck, so the screen grows from it (sheet 330); empty falls back to a plain open.
    var from: CGRect = .zero

    static var isChalkOn: Bool {
        LaunchFlags.has("-workoutChalk") || UserDefaults.standard.bool(forKey: "workoutMode.chalk")
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
                state = WorkoutModeState.make(from: session, warmUp: CoreWarmUp())
            }
        }
    }

    private var actions: WorkoutModeActions {
        WorkoutModeActions(
            close: { model.isWorkoutPresented = false },
            logged: { liftID, weight, reps in log(liftID: liftID, weight: weight, reps: reps) },
            finished: { session.finish() },
            changed: { _ in }
        )
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
