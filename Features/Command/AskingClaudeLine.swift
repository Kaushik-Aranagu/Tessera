import SwiftUI

/// "Asking Claude." with Cancel, under the Ask while a capture is on the network (batch 3, CL31). It shows only
/// once a request has really left the phone (Core's willSend), never for a grammar answer; Core's one 8 s deadline
/// ends it, and Cancel ends it at once with "Cancelled". VoiceOver hears it once, as one element with a Cancel action.
struct AskingClaudeLine: View {
    let cancel: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.l) {
            Text(AskingClaudeCopy.line)
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.tess)
            // Cancel at the right edge (Design on #1123).
            Spacer(minLength: Theme.Spacing.m)
            Button(AskingClaudeCopy.cancel, action: cancel)
                .buttonStyle(.labelWord)
                .frame(minHeight: 44)
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AskingClaudeCopy.spoken)
        .accessibilityAction(named: Text(AskingClaudeCopy.cancel), cancel)
        .onAppear { AccessibilityNotification.Announcement(AskingClaudeCopy.spoken).post() }
    }
}

enum AskingClaudeCopy {
    static let line = "Asking Claude"
    static let cancel = "Cancel"
    /// One element, spoken once (CL31).
    static let spoken = "Asking Claude. Cancel"
}

/// What a newline in the Ask's draft means: Return's own (one character added, at the end) sends; any other line break,
/// as from a paste, is a space and sends nothing.
enum AskDraft {
    /// Lines the field grows to before it scrolls inside: five, or four at the largest size, where five would not fit
    /// above the keyboard and the top line would show cut (Design on #1170). Whole lines only, no fade.
    static func maxLines(at size: DynamicTypeSize) -> Int {
        size >= .accessibility5 ? 4 : 5
    }

    static func read(old: String, new: String) -> (text: String, send: Bool) {
        let typedReturn = new.count == old.count + 1 && new.hasSuffix("\n") && new.dropLast() == Substring(old)
        let text = new.replacingOccurrences(of: "\n", with: " ")
        return typedReturn ? (text.trimmingCharacters(in: .whitespaces), true) : (text, false)
    }
}
