import Foundation
import TesseraCore
import WidgetKit

/// Surfaces v2 (Design 142), the app's half: writes the day sentence to the widget's shared snapshot, only while the
/// Review switch "Surfaces v2" is On. Off clears the snapshot and the mirrored flag, so the widgets draw nothing of
/// the new look. The clauses are Core's `HomeSentence` (masked on the phone: "Private workout", money as due words
/// only); `SurfacesSnapshot.scrubbed` is the second lock before anything is written.
@MainActor
enum SurfacesWriter {
    /// The Review switch.
    static var isOn: Bool {
        SurfacesV2.isOn(value: ReviewChoices.shared.value(of: SurfacesV2.choiceID))
    }

    /// One Core clause as the snapshot keeps it: no object ids, only the words, the key range and the time.
    nonisolated static func map(_ clause: HomeSentence.Clause) -> SurfaceClause {
        SurfaceClause(app: clause.app?.rawValue ?? "", text: clause.text, keyFrom: clause.keyWord?.lowerBound,
                      keyTo: clause.keyWord?.upperBound, at: clause.time)
    }

    /// Writes (On) or clears (Off) the snapshot and asks the widgets to redraw. A sample-data model never writes:
    /// example things do not belong on his Home Screen.
    static func refresh(model: AppModel, now: Date = AppClock.now) {
        let on = isOn
        guard !model.isSample else { return }
        var clauses: [SurfaceClause] = []
        if on {
            let inputs = HomeSentence.inputs(engine: model.engine, plan: model.plan, now: now)
            clauses = HomeSentence.compose(inputs).map(map)
        }
        SurfacesSnapshot.store(clauses, on: on, now: now)
        WidgetCenter.shared.reloadTimelines(ofKind: DaySentenceKind.id)
    }
}

/// The widget's kind, shared by name with `DaySentenceWidget.kind` in the extension.
enum DaySentenceKind {
    static let id = "TesseraDaySentence"
}
