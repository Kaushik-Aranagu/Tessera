import SwiftUI

/// "Asking Claude." with Cancel, under the Ask while a capture is on the network (batch 3, CL31). It shows only
/// once a request has really left the phone (Core's willSend), never for a grammar answer; Core's one 8 s deadline
/// ends it, and Cancel ends it at once with "Cancelled.". VoiceOver hears it once, as one element with a Cancel action.
struct AskingClaudeLine: View {
    let cancel: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.l) {
            Text(AskingClaudeCopy.line)
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.tess)
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
    static let line = "Asking Claude."
    static let cancel = "Cancel"
    /// One element, spoken once (CL31).
    static let spoken = "Asking Claude. Cancel."
}
