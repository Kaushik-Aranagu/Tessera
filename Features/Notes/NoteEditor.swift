import SwiftUI
import TesseraCore

/// One note, open: just the text to edit (the text is the hero: no title above it repeating its first line),
/// with when it was edited above and what it links to below.
/// Saves through the engine (EditNote, undoable) a moment after typing stops and when leaving.
struct NoteEditor: View {
    let noteID: UUID

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var text = ""
    @State private var loaded = false
    @State private var saveTask: Task<Void, Never>?
    @State private var deleted = false

    var body: some View {
        let _ = model.revision
        let note = model.store.object(id: noteID)
        let links = note.map { model.store.linkedObjects("about", of: $0) } ?? []
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let note {
                    Text(NotesEditorCopy.context(note, links: links.count, now: AppClock.now))
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.context)
                        .entrance(0)
                    TextEditor(text: $text)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .frame(minHeight: 220, alignment: .topLeading)
                        .padding(.top, Theme.Spacing.l)
                        .padding(.horizontal, -5) // TextEditor's built-in inset, so text aligns with the context line
                        .accessibilityLabel("Note text")
                        .entrance(1)

                    if !links.isEmpty {
                        MarginSection(label: "Links", color: Theme.Colors.tess) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(links, id: \.id) { link in
                                    HStack(spacing: Theme.Spacing.m) {
                                        PaintDab(color: Theme.Colors.tess, size: CGSize(width: 12, height: 10),
                                                 seed: link.title.count)
                                        Text(NotesCopy.linkLine([link], store: model.store))
                                            .textRole(.bodyStrong)
                                            .foregroundStyle(Theme.Colors.ink)
                                    }
                                    .padding(.vertical, Theme.Spacing.m)
                                    RowSeparator()
                                }
                            }
                        }
                        .padding(.top, Theme.Spacing.section)
                        .transition(.opacity)
                    }

                    Button(role: .destructive, action: delete) {
                        Text("Delete note")
                            .textRole(.label)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(HandleButtonStyle())
                    .padding(.top, Theme.Spacing.section)
                    .accessibilityHint("Undo brings it back")
                } else {
                    Text("This note is gone. Undo brings it back.")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.context)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
            .tesseraAnimation(Theme.Motion.house, value: links.map(\.id))
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
        .onAppear {
            guard !loaded, let note else { return }
            text = model.store.value("body", of: note)?.stringValue ?? note.title
            loaded = true
        }
        .onChange(of: text) { _, _ in scheduleSave() }
        .onDisappear { save() }
    }

    private func scheduleSave() {
        guard loaded else { return }
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            save()
        }
    }

    private func save() {
        saveTask?.cancel()
        guard loaded, !deleted, let note = model.store.object(id: noteID), !note.isDeleted else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let current = model.store.value("body", of: note)?.stringValue ?? ""
        guard !trimmed.isEmpty, trimmed != current else { return }
        _ = try? model.engine.perform(
            EditNote(note: noteID, body: trimmed, title: NotesEditorCopy.heading(from: trimmed, fallback: note.title)),
            by: .user
        )
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
    }

    private func delete() {
        deleted = true
        _ = try? model.engine.perform(DeleteObject(object: noteID), by: .user)
        model.touch()
        dismiss()
    }
}

enum NotesEditorCopy {
    /// The note's first line, as the title.
    static func heading(from text: String, fallback: String) -> String {
        let first = text.split(separator: "\n").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
        guard !first.isEmpty else { return fallback }
        return first.count > 60 ? String(first.prefix(59)) + "…" : first
    }

    @MainActor
    static func context(_ note: ObjectRecord, links: Int, now: Date) -> String {
        let edited = NotesCopy.when(note.updatedAt, now: now, spoken: true)
        let linkText = links == 0 ? "" : links == 1 ? ", one link" : ", \(links) links"
        return "Edited \(edited)\(linkText)"
    }
}
