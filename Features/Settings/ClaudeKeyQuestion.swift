import SwiftUI

/// The found-key question in Settings › Claude (G687, Design sheet 106 section 1): "Claude key found. Not used
/// yet.", then "Use the Claude key still on this phone?", then Yes, No and Later as ink words, 44 pt each, in that
/// order. Yes and No are one op each; Later writes nothing and the question returns on the next cold launch. No
/// character of the key, its length or its prefix ever shows: only that one was found.
struct ClaudeKeyQuestion: View {
    /// Yes (true), No (false) or Later (nil).
    let answer: (Bool?) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(ClaudeKeyQuestionCopy.question)
                .textRole(.body)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            // At accessibility sizes the three words stack, one per row (sheet 106).
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                : AnyLayout(HStackLayout(spacing: Theme.Spacing.l))
            layout {
                word(ClaudeKeyQuestionCopy.yes, hint: ClaudeKeyQuestionCopy.yesHint, ink: Theme.Colors.ink, true)
                word(ClaudeKeyQuestionCopy.no, hint: ClaudeKeyQuestionCopy.noHint, ink: Theme.Colors.inkSecondary,
                     false)
                word(ClaudeKeyQuestionCopy.later, hint: ClaudeKeyQuestionCopy.laterHint,
                     ink: Theme.Colors.inkSecondary, nil)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func word(_ title: String, hint: String, ink: Color, _ value: Bool?) -> some View {
        Button { answer(value) } label: {
            Text(title)
                .textRole(.bodyStrong)
                .foregroundStyle(ink)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityHint(hint)
    }
}

/// The one Now line while the question is due (sheet 106): Tess's voice, no buttons of its own; a tap opens Claude's
/// section, where the three words are.
struct ClaudeKeyQuestionNowLine: View {
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            Text(ClaudeKeyQuestionCopy.question)
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.tess)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44, alignment: .leading)
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityHint(ClaudeKeyQuestionCopy.nowHint)
    }
}

enum ClaudeKeyQuestionCopy {
    static let question = "Use the Claude key still on this phone?"
    static let yes = "Yes"
    static let no = "No"
    static let later = "Later"
    static let yesHint = "Uses the Claude key"
    static let noHint = "Does not use it"
    static let laterHint = "Asks again next time you open Tessera"
    static let nowHint = "Opens Claude's settings to answer"
    /// Tess's line after Yes (sheet 106).
    static let yesReceipt = "Using the Claude key"
    /// The key's line after No: never a dead end, since the switch beside it turns it on.
    static let noReceipt = "Claude key found. Not used"
    /// The key's row while the question is unanswered.
    static let found = "Claude key found. Not used yet"
    /// Under "Tess asks Claude: no." while unanswered.
    static let waiting = "Waiting on your answer"
    static let notSaved = "Didn't save that. Try again"
}
