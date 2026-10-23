import SwiftUI
import TesseraCore

enum BackupDatesCopy {
    static let undo = "Undo"
    static let lead = "Restore from"

    /// "Restore from Thursday, Oct 22" for VoiceOver.
    static func spoken(_ date: String) -> String {
        "\(lead) \(date)"
    }
}

/// backupsV2: the last copies on this phone as dates in ink, each a word that picks that copy for a restore. Counts
/// and dates only; nothing in a copy is named. A tap goes through the same check and "Replace" hold as Restore.
struct BackupDatesList: View {
    let copies: [BackupKeeper.LocalCopy]
    let onPick: (URL) -> Void

    var body: some View {
        let dates = BackupWords.restoreDates(copies.map(\.createdAt))
        if !copies.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text(BackupDatesCopy.lead)
                    .textRole(.data)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(zip(copies, dates).enumerated()), id: \.offset) { _, pair in
                    Button { onPick(pair.0.url) } label: {
                        Text(pair.1)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(BackupDatesCopy.spoken(pair.1))
                    .accessibilityHint("Shows what it would change before anything is replaced")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
