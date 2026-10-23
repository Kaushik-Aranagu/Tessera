import SwiftUI
import TesseraCore

/// One Undo, for the foot line and the Recent changes list alike: Core's `UndoLog.undo`, which is the op-log Undo.
@MainActor
enum UndoRun {
    enum Result: Equatable {
        case putBack, blocked, gone
    }

    /// Puts one change back, redraws, and says Tess's one short line (nothing when it is already gone).
    @discardableResult
    static func perform(_ entry: UndoEntry, model: AppModel) -> Result {
        let outcome = UndoLog.undo(entry.id, engine: model.engine)
        model.touch()
        if let line = UndoWords.said(outcome, money: entry.isMoney) {
            TessVoice.shared.say(line)
        }
        switch outcome {
        case .putBack: return .putBack
        case .blocked: return .blocked
        case .gone: return .gone
        }
    }
}

/// The page foot on Today and Home v2 (164, undoLogV2): the last change of the last 10 minutes as a quiet sentence,
/// with an ink "Undo". Drawn only while its switch is On and there is such a change; otherwise nothing at all.
struct UndoFootLine: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var putBacks = 0
    @State private var refusals = 0

    var body: some View {
        if Tier1b.undoIsOn {
            // The 10 minutes pass with the clock, so the line is looked at again every half minute.
            TimelineView(.periodic(from: .now, by: 30)) { _ in
                let _ = model.revision
                if let entry = UndoLog.latest(engine: model.engine, now: AppClock.now) {
                    foot(entry)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .tesseraFeedback(.undo, trigger: putBacks)
            .tesseraFeedback(.notNow, trigger: refusals)
        }
    }

    private func foot(_ entry: UndoEntry) -> some View {
        // At accessibility sizes the word goes under the sentence, never beside it.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        return layout {
            Text(entry.sentence)
                .textRole(.data)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
            Button(UndoWords.undo) {
                switch UndoRun.perform(entry, model: model) {
                case .putBack: putBacks += 1
                case .blocked: refusals += 1
                case .gone: break
                }
            }
            .buttonStyle(InkLabelWordStyle.undo)
            .accessibilityHint("Puts that change back")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.l)
        .accessibilityElement(children: .contain)
    }
}
