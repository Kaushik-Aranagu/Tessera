import SwiftUI
import TesseraCore
import UniformTypeIdentifiers

/// Backups: where his history is kept safe, said in sentences, not a settings list. The hero says how safe it is
/// right now; the folder outside the app is a value word inside a sentence (tap to pick or change it); saving a copy
/// and restoring are label words. A restore is checked, then applied the next time Tessera opens.
///
/// Entry point: present `BackupView()`, or launch with `-backup` in DEBUG (`-backupFailure` shows a failed copy).
struct BackupView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var picking = false
    @State private var folderTaps = 0
    @State private var importing = false
    @State private var saving: BackupFile?
    @State private var line: String?
    /// A folder he just stopped using, kept in memory for its 10 s UNDO.
    @State private var forgotten: Data?
    @State private var forgetTimer: Task<Void, Never>?
    @State private var refresh = 0
    /// A picked backup, checked and copied in, waiting for "Replace everything".
    @State private var confirming: Picked?
    /// The staged restore, read once and refreshed on stage or cancel (the check reads the whole file).
    @State private var pending: TesseraBackup.Info?

    var body: some View {
        let _ = refresh
        let folder = BackupKeeper.pickedFolder
        let failures = BackupKeeper.failures
        let latest = BackupKeeper.latestLocal
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isPresented {
                    Button { dismiss() } label: {
                        Text("‹ Review")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .accessibilityLabel("Back to Review")
                }
                Text("your history")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(0)
                // Two places only when the folder copy is actually saving.
                Text(folder == nil || failures.contains { $0.place == .folder } ? "Kept on this iPhone"
                    : "Kept in two places")
                    .textRole(.hero)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)

                Text(BackupCopy.local(latest, now: AppClock.now))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(2)

                // A fresh install with nothing done yet: say a restore is possible (restore-walk 3). Restore first,
                // then reopen, then pick the folder again.
                // Anything he, Tess or Siri did counts (QA R3, like Core's userOps): only seeding is "nothing yet".
                if !model.engine.history(limit: 2000).contains(where: {
                    // Settings writes (a look, a switch) don't count either (QA C4).
                    $0.actor != .system && $0.action != WriteSettings.descriptor.name
                }) {
                    Text("Reinstalled? Restore brings back your copy from iCloud Drive.")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.s)
                        .entrance(2)
                }

                // Quiet, not an alarm: what didn't save and that it tries again.
                ForEach(failures, id: \.place) { failure in
                    Text(BackupCopy.failure(failure, folder: folder, now: AppClock.now))
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.s)
                }

                // One sentence that wraps as text; the folder is a value word in 600 ink that opens the picker.
                Text(folder == nil ? BackupCopy.rememberedSentence(SettingsStore(engine: model.engine).read()
                        .backupFolderName) ?? BackupCopy.folderSentence(nil) : BackupCopy.folderSentence(folder))
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .tint(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.openURL, OpenURLAction { _ in
                        folderTaps += 1
                        picking = true
                        return .handled
                    })
                    .sensoryFeedback(.selection, trigger: folderTaps)
                    .accessibilityAction(named: "Choose the folder") { picking = true }
                    .padding(.top, Theme.Spacing.m)
                    .entrance(3)

                // A way to stop using the folder: one ink word, with UNDO for 10 s (settings-object.md).
                if folder != nil {
                    Button("Stop using it", action: forgetFolder)
                        .buttonStyle(.labelWord)
                        .accessibilityHint("Copies stay on this iPhone only")
                } else if forgotten != nil {
                    Button("Undo", action: undoForget)
                        .buttonStyle(InkLabelWordStyle.undo)
                }

                Text(folder == nil
                    ? "Copies on this iPhone go if the app is deleted. A folder in iCloud Drive keeps them."
                    : "These survive deleting the app.")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(4)

                HStack(spacing: Theme.Spacing.xl) {
                    Button("Save a copy", action: saveCopy)
                        .buttonStyle(.labelWord)
                    Button("Restore") { importing = true }
                        .buttonStyle(.labelWord)
                        .accessibilityHint("Picks a backup; it replaces your data next time Tessera opens")
                }
                .padding(.top, Theme.Spacing.section)
                .entrance(5)

                restoreSection

                if let line {
                    Text(line)
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.tess)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Spacing.m)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .navigationBarBackButtonHidden(isPresented)
        .background { EdgeSwipeBack() }
        .task {
            #if DEBUG
                BackupKeeper.simulateFailureIfRequested()
            #endif
            pending = TesseraBackup.pendingRestore()
            refresh += 1
        }
        .environment(\.animateEntrance, true)
        .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
            guard case let .success(url) = result else { return }
            do {
                try BackupKeeper.pick(url, context: model.context, engine: model.engine)
                say("Saved a copy there. One a day from now on.")
            } catch {
                say("Couldn't use that folder. Try another one.")
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.tesseraBackup, .data]) { result in
            guard case let .success(url) = result else { return }
            restore(from: url)
        }
        .fileExporter(isPresented: Binding(get: { saving != nil }, set: {
            if !$0 {
                saving = nil
            }
        }),
        document: saving, contentType: .tesseraBackup, defaultFilename: saving?.name) { result in
            if case .success = result {
                say("Copy saved.")
            }
        }
    }

    /// The restore in progress: a picked copy waiting for "Replace", or a staged one that can be cancelled.
    @ViewBuilder private var restoreSection: some View {
        if let confirming {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("Replace everything with the copy from \(BackupCopy.fileDay(confirming.info.createdAt))?")
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let weight = confirming.weight {
                    Text(weight)
                        .textRole(.label)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                PaintKey(paint: Theme.Colors.live, hint: "Restores this backup", action: confirmRestore) { _ in
                    Text("Replace")
                } meta: {
                    Text("Hold")
                }
                .accessibilityHint("Replaces your data with this copy next time Tessera opens")
                Button("Keep what's here") { dropPicked() }
                    .buttonStyle(.labelWord)
            }
            .padding(.top, Theme.Spacing.xl)
            .transition(.opacity)
        } else if let staged = pending {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("A restore is waiting")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                Text("The copy from \(BackupCopy.fileDay(staged.createdAt)) replaces everything the next time "
                    + "Tessera opens. Close Tessera from the app switcher to restore now.")
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Cancel restore") {
                    TesseraBackup.cancelRestore()
                    pending = nil
                    say("Cancelled. Nothing will be replaced.")
                }
                .buttonStyle(.labelWord)
            }
            .padding(.top, Theme.Spacing.xl)
            .transition(.opacity)
        }
    }

    private func saveCopy() {
        guard let url = try? BackupKeeper.copyForSaving(model.context), let data = try? Data(contentsOf: url) else {
            say("Couldn't make a copy just now.")
            return
        }
        saving = BackupFile(data: data, name: url.deletingPathExtension().lastPathComponent)
    }

    /// Checks the picked file and copies it in while access lasts; nothing is staged until "Replace" is held.
    private func restore(from url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let info = try TesseraBackup.inspect(url)
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent("picked-\(UUID().uuidString).\(TesseraBackup.fileExtension)")
            try FileManager.default.copyItem(at: url, to: copy)
            dropPicked()
            withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                line = nil
                confirming = Picked(url: copy, info: info,
                                    weight: TesseraBackup.restoreWeightLine(copyAt: copy, replacing: model.context))
            }
        } catch TesseraBackup.BackupError.newerSchema {
            say("That copy is from a newer Tessera. Update first.")
        } catch TesseraBackup.BackupError.damaged {
            // A real copy that didn't survive (restore-walk 8): a different answer from "not a backup".
            say("That copy is damaged. Try the day before.")
        } catch {
            say("That file isn't a Tessera backup.")
        }
    }

    private func confirmRestore() {
        guard let picked = confirming else { return }
        do {
            pending = try TesseraBackup.stageRestore(from: picked.url)
            dropPicked()
            say("What's here now is kept in Backups, so this can be undone.")
        } catch {
            dropPicked()
            say("That copy couldn't be staged. Nothing was replaced.")
        }
    }

    private func dropPicked() {
        if let picked = confirming {
            try? FileManager.default.removeItem(at: picked.url)
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { confirming = nil }
    }

    private func forgetFolder() {
        forgotten = BackupKeeper.bookmark
        BackupKeeper.forget()
        say("Copies stay on this iPhone only now.")
        forgetTimer?.cancel()
        forgetTimer = Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            withTesseraAnimation(reduceMotion: reduceMotion) { forgotten = nil }
        }
    }

    private func undoForget() {
        forgetTimer?.cancel()
        if let forgotten {
            BackupKeeper.bookmark = forgotten
        }
        forgotten = nil
        say("The folder is back.")
    }

    private func say(_ text: String) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            line = text
            refresh += 1
        }
    }
}

/// A picked backup, copied in and checked, awaiting confirmation.
private struct Picked {
    let url: URL
    let info: TesseraBackup.Info
    /// "That copy has 6 recipes. The 9 you have now are kept in Backups." when the Kitchen differs (G26).
    let weight: String?
}

/// A backup file for the export sheet.
struct BackupFile: FileDocument {
    static var readableContentTypes: [UTType] {
        [.tesseraBackup]
    }

    let data: Data
    var name = "Tessera"

    init(data: Data, name: String) {
        self.data = data
        self.name = name
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum BackupCopy {
    /// "A copy is made every day. The last one was today." / "The first copy is made when you leave the app today."
    static func local(_ latest: Date?, now: Date) -> String {
        guard let latest else { return "The first copy is made when you leave the app today." }
        let calendar = Calendar.current
        // His day (04:00 to 04:00): a 23:55 copy read at 01:15 is today's.
        let tesseraDay = TesseraDay(calendar: calendar)
        let when = tesseraDay.isSameDay(latest, now) ? "today"
            : tesseraDay.day(of: latest) == tesseraDay.day(-1, after: now) ? "yesterday"
            : latest.formatted(.dateTime.weekday(.wide))
        return "A copy is made every day, the last one \(when). Seven are kept."
    }

    /// "Also keep them in a folder you choose." with the folder as a tappable value word in 600.
    /// After a restore, with no folder on this phone yet: "Your copies were kept in iCloud Drive/Tessera. Choose it
    /// again." with "Choose it again" as the tappable value word (restore-walk 3b).
    static func rememberedSentence(_ name: String?) -> AttributedString? {
        guard let name, !name.isEmpty else { return nil }
        var sentence = AttributedString("Your copies were kept in \(name). ")
        var value = AttributedString("Choose\u{00A0}it\u{00A0}again")
        value.inlinePresentationIntent = .stronglyEmphasized
        value.link = URL(string: "tessera://backups/folder")
        sentence += value
        sentence += AttributedString(".")
        return sentence
    }

    static func folderSentence(_ folder: URL?) -> AttributedString {
        var sentence = AttributedString(folder == nil ? "Also keep them in " : "Also kept in ")
        var value = AttributedString(folder.map(folderName) ?? "a\u{00A0}folder\u{00A0}you\u{00A0}choose")
        value.inlinePresentationIntent = .stronglyEmphasized
        value.link = URL(string: "tessera://backups/folder")
        sentence += value
        sentence += AttributedString(".")
        return sentence
    }

    /// "Yesterday's copy to iCloud Drive/Tessera didn't save. It tries again when you leave the app."
    static func failure(_ failure: BackupKeeper.Failure, folder: URL?, now: Date) -> String {
        let day = TesseraDay().isSameDay(failure.at, now) ? "Today's" : "The last"
        if failure.place == .folder, folder == nil {
            return "The folder you chose can't be reached, so copies are only on this iPhone. Choose it again."
        }
        let place = failure.place == .folder ? folder.map { " to \(folderName($0))" } ?? " to your folder"
            : " on this iPhone"
        return "\(day) copy\(place) didn't save. It tries again when you leave the app."
    }

    /// "Tuesday 14 October"
    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    /// The copy's own day, his 4 AM day as in its file name (restore-walk 7): a copy made at 01:30 Wednesday is
    /// Tuesday's.
    static func fileDay(_ createdAt: Date) -> String {
        let key = TesseraDay().day(of: createdAt)
        return day(Calendar.current.date(byAdding: .hour, value: 12, to: key) ?? key)
    }

    /// "iCloud Drive/Tessera"
    static func folderName(_ url: URL) -> String {
        let parts = url.pathComponents
        if let index = parts.firstIndex(where: { $0.hasPrefix("com~apple~CloudDocs") }) {
            return (["iCloud Drive"] + parts[(index + 1)...]).joined(separator: "/")
        }
        return parts.suffix(2).joined(separator: "/")
    }
}
