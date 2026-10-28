import SwiftUI
import TesseraCore

/// The EXPORT row (kitchen gap hunt G38, Product's ruling): in Settings beside the Backups folder line, apart from
/// SAVE A COPY, which keeps everything. The export is plain JSON for outside Tessera and hides his private things,
/// so it says so in one line, and a restore of one warns first.
///
/// Built against a stub of Core's flag: Core writes `masked: true` into the file and owns the restore check. Until
/// Core's PR lands, `ExportFile.ready` is false and the row doesn't show.
enum ExportFile {
    /// Turned on in the PR that wires Core's masked export.
    static let ready = false

    /// "This file hides your private things."
    static let line = "This file hides your private things"
    static let restoreWarning =
        "This file hides your private things, so they will not come back. Restore from Backups to keep them"

    /// Whether a file says it was masked: a top-level `masked` true. Anything unreadable isn't treated as masked here
    /// (the restore itself refuses what it can't read).
    static func isMasked(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return object["masked"] as? Bool == true
    }

    enum RestoreStep: Equatable {
        /// Go straight on: nothing in the file is hidden.
        case restore
        /// Show the warning with RESTORE and CANCEL first.
        case warn(String)
    }

    /// What a restore of this file does first.
    static func restoreStep(for data: Data) -> RestoreStep {
        isMasked(data) ? .warn(restoreWarning) : .restore
    }
}

/// The warning before a masked file is restored: the line, then RESTORE and CANCEL as label words. Nothing is
/// replaced until RESTORE (the before-restore copy is kept either way, G26).
struct MaskedRestoreWarning: View {
    let onRestore: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text(ExportFile.restoreWarning)
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Theme.Spacing.xl) {
                Button("Restore", action: onRestore)
                    .accessibilityHint("Replaces your data with this file, without your private things")
                Button("Cancel", action: onCancel)
            }
            .buttonStyle(.labelWord)
        }
    }
}

/// EXPORT and its one line. Shown only once Core's masked export is wired (`ExportFile.ready`).
struct ExportRow: View {
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Button("Export", action: onExport)
                .buttonStyle(.labelWord)
                .accessibilityHint("Saves a plain file for use outside Tessera, without your private things")
            Text(ExportFile.line)
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
