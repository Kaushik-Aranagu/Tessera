import SwiftUI
import TesseraCore

// Parts Money and Reading share: the writing line, Tess's line on a covering layer, and the sentence whose numbers
// sit at 600.

/// One writing line: a Label word, his typing, a hairline that takes the word's colour while he writes.
struct AreaWritingLine: View {
    let word: String
    let prompt: String
    let label: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    var keyboard: UIKeyboardType = .default
    let onSubmit: () -> Void

    var body: some View {
        let active = focused.wrappedValue || !text.isEmpty
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .center, spacing: Theme.Spacing.m) {
                Text(word)
                    .textRole(.label)
                    .textCase(.uppercase)
                    .foregroundStyle(active ? Theme.Colors.tess : Theme.Colors.inkSecondary)
                    .tesseraAnimation(Theme.Motion.house, value: active)
                    .accessibilityHidden(true)
                TextField("", text: $text, prompt: Text(prompt).foregroundStyle(Theme.Colors.inkSecondary))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .focused(focused)
                    .keyboardType(keyboard)
                    .submitLabel(.done)
                    .onSubmit(onSubmit)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel(label)
            }
            .frame(minHeight: 44)
            Rectangle()
                .fill(active ? Theme.Colors.tess : Theme.Colors.hairline)
                .frame(height: Theme.Stroke.hairline)
                .tesseraAnimation(Theme.Motion.house, value: active)
        }
    }
}

/// Tess's reply line as the bottom chrome draws it (right-aligned, Tess ink, UNDO as the vermilion label word), for
/// the full-screen layers that cover her soul.
struct AreaTessLine: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var undone = 0
    private let voice = TessVoice.shared

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let note = voice.note {
                Text(note.text)
                    .frame(maxWidth: 270, alignment: .trailing)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.tess)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                if note.undo != nil || note.takeBack != nil {
                    Button("Undo") {
                        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                            if let record = note.undo {
                                _ = model.engine.undo(record)
                            }
                            note.takeBack?()
                            model.touch()
                            voice.clear()
                        }
                        undone += 1
                    }
                    .buttonStyle(InkLabelWordStyle.undo)
                    .accessibilityLabel(AreaUndo.label(note.text))
                    .accessibilityHint("Undoes what Tess just said")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.trailing, Theme.Spacing.gutter)
        .padding(.bottom, Theme.Spacing.s)
        .tesseraAnimation(Theme.Motion.house, value: voice.note)
        .tesseraFeedback(.undo, trigger: undone)
    }
}

/// The UNDO key names the thing (amendment 1): "Undo 12.40 lunch" from "12.40 lunch, logged.".
enum AreaUndo {
    static func label(_ line: String) -> String {
        guard let comma = line.firstIndex(of: ",") else { return "Undo" }
        return "Undo \(line[..<comma])"
    }
}

/// A sentence in Body with every number at 600: "7 spends. Most went to lunch, 24.80, and coffee, 9.00."
struct NumberedSentence: View {
    let text: String

    var body: some View {
        Text(Self.attributed(text))
            .textRole(.body)
            .foregroundStyle(Theme.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Words carrying a digit are strongly emphasized; the rest stay plain.
    static func attributed(_ text: String) -> AttributedString {
        var result = AttributedString()
        for (index, word) in text.split(separator: " ", omittingEmptySubsequences: false).enumerated() {
            if index > 0 {
                result += AttributedString(" ")
            }
            var part = AttributedString(String(word))
            if word.contains(where: \.isNumber) {
                part.inlinePresentationIntent = .stronglyEmphasized
            }
            result += part
        }
        return result
    }
}
