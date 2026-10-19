import SwiftUI

/// "Use the Claude key still on this phone?" with Yes · No · Later (G687, reinstall-key-and-restore-spec 1.4). A key
/// found on a fresh store sends nothing until he answers: Yes and No are one op each; Later writes nothing. Never a
/// modal or a sheet: one line in Settings › Claude, always, and once on Now per cold launch while it is due.
struct ClaudeKeyQuestion: View {
    /// Yes (true), No (false) or Later (nil).
    let answer: (Bool?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(ClaudeKeyQuestionCopy.question)
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.tess)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Theme.Spacing.l) {
                Button(ClaudeKeyQuestionCopy.yes) { answer(true) }
                Button(ClaudeKeyQuestionCopy.no) { answer(false) }
                Button(ClaudeKeyQuestionCopy.later) { answer(nil) }
            }
            .buttonStyle(.labelWord)
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ClaudeKeyQuestionCopy.spoken)
    }
}

enum ClaudeKeyQuestionCopy {
    static let question = "Use the Claude key still on this phone?"
    static let yes = "Yes"
    static let no = "No"
    static let later = "Later"
    /// VoiceOver: the question, then the three answers.
    static let spoken = "Use the Claude key still on this phone? Yes, No or Later."
    static let yesReceipt = "Claude on. Turn this off in Settings: Claude."
    static let noReceipt = "Claude off. Turn this on in Settings: Claude."
    /// The key's row in Settings while the question is unanswered.
    static let found = "Claude key found. Not used yet."
    static let notSaved = "Didn't save that. Try again."
}
