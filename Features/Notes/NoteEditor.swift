import SwiftUI
import TesseraCore

/// One note, open: its first line at the Title tier, the rest at body size, when it was edited above and what it
/// links to below. The first line is its own field (return moves into the rest), so it's stored as one plain body.
/// Saves through the engine (EditNote, undoable) a moment after typing stops and when leaving.
struct NoteEditor: View {
    let noteID: UUID

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var heading = ""
    @State private var text = ""
    @FocusState private var focus: Field?

    private enum Field { case heading, rest }
    @State private var loaded = false
    /// Set by the first real edit, so opening and leaving writes nothing.
    @State private var edited = false
    /// The text as it was opened (the load itself fires onChange; that isn't an edit).
    @State private var openedAs = ""
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
                    TextField("", text: $heading, prompt: Text("First line").foregroundStyle(Theme.Colors.inkSecondary),
                              axis: .vertical)
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                        .focused($focus, equals: .heading)
                        .submitLabel(.next)
                        .onSubmit { focus = .rest }
                        .padding(.top, Theme.Spacing.l)
                        .accessibilityLabel("First line")
                        .entrance(1, hero: true)
                    TextEditor(text: $text)
                        .textRole(.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .focused($focus, equals: .rest)
                        .frame(minHeight: 180, alignment: .topLeading)
                        .padding(.top, Theme.Spacing.s)
                        .padding(.horizontal, -5) // TextEditor's built-in inset, so text aligns with the first line
                        .accessibilityLabel("Note text")
                        .entrance(2)

                    if !links.isEmpty {
                        MarginSection(label: "Links", color: Theme.Colors.inkSecondary) {
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
                    .accessibilityHint("Deletes the note")
                } else {
                    Text("This note is gone.")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
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
            let body = model.store.value("body", of: note)?.stringValue ?? note.title
            let parts = NotesEditorCopy.split(body)
            heading = parts.heading
            text = parts.rest
            openedAs = NotesEditorCopy.join(heading: heading, rest: text)
            loaded = true
        }
        .onChange(of: text) { _, _ in noteEdit() }
        .onChange(of: heading) { _, _ in noteEdit() }
        .onDisappear { save() }
    }

    private func noteEdit() {
        guard loaded, edited || NotesEditorCopy.join(heading: heading, rest: text) != openedAs else { return }
        edited = true
        scheduleSave()
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
        let trimmed = NotesEditorCopy.join(heading: heading, rest: text)
        // Never touched since it was opened: nothing to save (no rewrite, no jump to the top, no op). Once edited,
        // compare with what's stored, so typing back to the original after an autosave still saves.
        guard edited else { return }
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
    /// A body as its first line and the rest.
    static func split(_ body: String) -> (heading: String, rest: String) {
        guard let newline = body.firstIndex(of: "\n") else { return (body, "") }
        return (String(body[..<newline]), String(body[body.index(after: newline)...]))
    }

    /// The first line and the rest, back into one plain body: the exact inverse of `split` (blank lines after the
    /// heading stay), with only trailing whitespace trimmed.
    static func join(heading: String, rest: String) -> String {
        let first = heading.replacingOccurrences(of: "\n", with: " ")
        let body = rest.replacing(/\s+$/, with: "")
        if first.trimmingCharacters(in: .whitespaces).isEmpty {
            return body.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return body.isEmpty ? first.replacing(/\s+$/, with: "") : first + "\n" + body
    }

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
