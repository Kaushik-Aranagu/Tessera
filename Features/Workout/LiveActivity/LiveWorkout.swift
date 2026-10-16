import Foundation
import TesseraCore

/// The app's end of the rest Live Activity buttons. Setting `model` (once, at launch) installs the handler the shared
/// `LiveActivityIntent`s forward to; the intents then act on `model.session` and refresh the activity.
@MainActor
enum LiveWorkout {
    weak static var model: AppModel? {
        didSet { RestIntentRelay.handler = { action in handle(action) } }
    }

    static func handle(_ action: RestAction) {
        guard let session = model.flatMap(resumeSession) else {
            // No workout running at all: don't leave a dead activity on the Lock Screen.
            RestActivityController.shared.update(for: nil)
            return
        }
        switch action {
        case .logPlannedSet:
            // Hold to log seats the dialled set; when this exercise is already done, the key pages on first.
            if let entry = session.currentEntry, session.isFinished(entry), let next = session.nextUnfinishedIndex {
                session.select(entryAt: next)
            }
            session.logSet(source: .lockScreen)
        case .extendRest:
            session.extendRest(by: 15)
        case .skipRest:
            session.skipRest()
        case .skipSet:
            session.skipSet()
        }
        RestActivityController.shared.update(for: session)
    }

    /// The session in memory, or, if the app was relaunched by the button, the running workout picked back up
    /// from the engine's process table, so Done still logs instead of ending the activity.
    private static func resumeSession(_ model: AppModel) -> WorkoutSession? {
        if let session = model.session {
            return session
        }
        guard let workout = ProcessTable(engine: model.engine).running()?.subject,
              let workoutClass = model.classDef(.workout), let classDef = workout.classDef,
              ClassResolver.isSubclass(classDef, of: workoutClass) else { return nil }
        model.session = WorkoutSession(workout: workout, model: model)
        return model.session
    }
}
