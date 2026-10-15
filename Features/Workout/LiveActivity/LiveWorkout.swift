import Foundation

/// The app's end of the rest Live Activity buttons. Setting `model` (once, at launch) installs the handler the shared
/// `LiveActivityIntent`s forward to; the intents then act on `model.session` and refresh the activity.
@MainActor
enum LiveWorkout {
    weak static var model: AppModel? {
        didSet { RestIntentRelay.handler = { action in handle(action) } }
    }

    static func handle(_ action: RestAction) {
        guard let session = model?.session else {
            // No workout in memory (e.g. the app was relaunched): don't leave a dead activity on the Lock Screen.
            RestActivityController.shared.update(for: nil)
            return
        }
        switch action {
        case .logPlannedSet:
            // Hold to log seats the dialled set; when this exercise is already done, the key pages on first.
            if let entry = session.currentEntry, session.isFinished(entry), let next = session.nextUnfinishedIndex {
                session.select(entryAt: next)
            }
            session.logSet()
        case .extendRest:
            session.extendRest(by: 15)
        case .skipRest:
            session.skipRest()
        }
        RestActivityController.shared.update(for: session)
    }
}
