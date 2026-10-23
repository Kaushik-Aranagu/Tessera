import Foundation

/// Sheet 139, Builder B's finishing moments (Review › Together › Finish moments, default Off). Each moment writes
/// its result in words, dries to ink, and plays one haptic. No scores, streaks or counts of misses. These are the
/// pure pieces; the views read them only when the switch is On, so Off is today exactly.
enum FinishMoments {
    static let switchID = "finishMoments"

    static var isOn: Bool {
        isOn(defaults: .standard)
    }

    static func isOn(defaults: UserDefaults) -> Bool {
        Choice.value(switchID, options: ["Off", "On"], default: "Off", defaults: defaults) == "On"
    }

    /// The line under a finished list's name: "All packed." for a packing list, else "All done.".
    static func listLine(name: String) -> String {
        name.localizedCaseInsensitiveContains("pack") ? "All packed." : "All done."
    }

    /// The word a reusable finished list offers beside the line.
    static let resetWord = "Reset it for next time"

    /// Whether a list has its moment: every item struck, at least one item, and not a pick-one list.
    static func listIsFinished(left: Int, total: Int, isPickOne: Bool) -> Bool {
        !isPickOne && total > 0 && left == 0
    }

    /// The day sentence's tasks clause: "3 done today.", only once something is done.
    static func tasksClause(done: Int) -> String? {
        done > 0 ? "\(done) done today." : nil
    }
}

import SwiftUI
import TesseraCore

/// Sheet 139 part 3 on a list's page: once the last item is struck the name gets "All packed." or "All done." in ink
/// under it (a reusable list adds the ink word "Reset it for next time"), with one haptic as it lands. It is empty
/// while the switch is Off, the list is a pick-one list or items are still open, so Off is today exactly.
struct FinishedListLine: View {
    let list: ObjectRecord
    let name: String
    let contents: ListContents
    let reset: () -> Void

    var body: some View {
        let finished = FinishMoments.isOn && FinishMoments.listIsFinished(
            left: contents.open(in: list).count,
            total: contents.open(in: list).count + contents.done(in: list).count,
            isPickOne: contents.isPickOne(list)
        )
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if finished {
                Text(FinishMoments.listLine(name: name))
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .transition(.opacity)
                if contents.isReusable(list) {
                    Button(FinishMoments.resetWord, action: reset)
                        .buttonStyle(LandingWordStyle())
                        .transition(.opacity)
                }
            }
        }
        .padding(.top, finished ? Theme.Spacing.s : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tesseraAnimation(value: finished)
        .tesseraFeedback(trigger: finished) { old, new in !old && new ? .done : nil }
    }
}
