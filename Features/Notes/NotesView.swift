import SwiftUI
import TesseraCore

/// Notes v0 (M2 slice 10): a page of plain-text notes, newest edit first, with a writing line at the top.
/// Rows are paint-and-hairline, not cards; opening one zooms out of its row into the editor.
///
/// Entry point: present `NotesView()` (it brings its own navigation), or launch with `-notes` in DEBUG.
struct NotesView: View {
    @Environment(AppModel.self) private var model
    @Namespace private var zoom
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            NotesIndex(zoom: zoom) { path.append($0) }
                .navigationDestination(for: UUID.self) { id in
                    NoteEditor(noteID: id)
                        .navigationTransition(.zoom(sourceID: id, in: zoom))
                }
        }
        .environment(\.animateEntrance, true)
        #if DEBUG
            .task { NotesDemo.seedIfRequested(model) }
        #endif
    }
}

#if DEBUG
    /// `-demoNotes`: a few notes to look at, for previews and recordings.
    @MainActor
    enum NotesDemo {
        static func seedIfRequested(_ model: AppModel) {
            guard ProcessInfo.processInfo.arguments.contains("-demoNotes"),
                  NoteList(store: model.store, classes: model.classes).recent().isEmpty else { return }
            for body in [
                "Sleep is training too\nEight hours this week and the bar moved faster.",
                "@Bench Press felt heavy on the third set\nMaybe the grip. Try a touch narrower on Thursday.",
                "Ideas for the garage gym\nRubber floor, a second bench, chalk that doesn't get everywhere.",
            ] {
                _ = try? model.engine.perform(CreateNote(body: body), by: .user)
            }
            model.touch()
        }
    }
#endif

/// The list page: context line, hero, the writing line, then the notes.
private struct NotesIndex: View {
    let zoom: Namespace.ID
    let open: (UUID) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft = ""
    @State private var justWritten: UUID?
    @FocusState private var writing: Bool

    var body: some View {
        let _ = model.revision
        let notes = NoteList(store: model.store, classes: model.classes).recent(limit: 200)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(NotesCopy.context(count: notes.count, latest: notes.first?.updatedAt, now: AppClock.now))
                    .font(Theme.voice)
                    .foregroundStyle(Theme.Colors.context)
                    .entrance(0)
                Text("Notes")
                    .textRole(.hero)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                    .entrance(1, hero: true)

                WritingLine(text: $draft, focused: $writing, onSubmit: write)
                    .padding(.top, Theme.Spacing.xxl)
                    .entrance(2)

                if notes.isEmpty {
                    NotesEmpty()
                        .padding(.top, Theme.Spacing.section)
                        .entrance(3)
                } else {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                            NoteRow(note: note, now: AppClock.now, isNew: note.id == justWritten) { open(note.id) }
                                .matchedTransitionSource(id: note.id, in: zoom)
                                .entrance(3 + min(index, 2))
                                .transition(.asymmetric(insertion: .push(from: .top).combined(with: .opacity),
                                                        removal: .opacity))
                            RowSeparator()
                        }
                    }
                    .padding(.top, Theme.Spacing.xl)
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { ThemedBackground() }
        .toolbarTitleDisplayMode(.inline)
    }

    private func write() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              let note = try? model.engine.perform(CreateNote(body: text), by: .user).output else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            justWritten = note.id
            draft = ""
            model.touch()
        }
    }
}

/// The writing line: a cobalt dab, the text, and a hairline that inks in while you type.
private struct WritingLine: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .center, spacing: Theme.Spacing.m) {
                PaintDab(color: Theme.Colors.tess, size: CGSize(width: 14, height: 12), seed: 3,
                         filled: focused.wrappedValue || !text.isEmpty)
                TextField("", text: $text, prompt: Text("Write something. @ links a thing.")
                    .foregroundStyle(Theme.Colors.inkTertiary), axis: .vertical)
                    .textRole(.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .focused(focused)
                    .submitLabel(.done)
                    .onSubmit(onSubmit)
                    .lineLimit(1 ... 4)
                    .accessibilityLabel("New note")
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.Colors.hairline)
                    Rectangle().fill(Theme.Colors.tess)
                        .frame(width: focused.wrappedValue || !text.isEmpty ? proxy.size.width : 0)
                }
            }
            .frame(height: Theme.Stroke.hairline)
            .tesseraAnimation(Theme.Motion.house, value: focused.wrappedValue || !text.isEmpty)
        }
    }
}

/// One note: its first line, a second line of the rest, and when, hanging right.
private struct NoteRow: View {
    let note: ObjectRecord
    let now: Date
    let isNew: Bool
    let open: () -> Void

    @Environment(AppModel.self) private var model

    var body: some View {
        let body = model.store.value("body", of: note)?.stringValue ?? ""
        let rest = NotesCopy.rest(of: body)
        let links = model.store.linkedObjects("about", of: note)
        Button(action: open) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.l) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(NotesCopy.inked(note.title))
                        .textRole(.bodyStrong)
                        .foregroundStyle(Theme.Colors.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if !rest.isEmpty {
                        Text(rest)
                            .font(Theme.voice)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    if !links.isEmpty {
                        HStack(spacing: Theme.Spacing.s) {
                            PaintDab(color: Theme.Colors.tess, size: CGSize(width: 10, height: 8),
                                     seed: links.count)
                            Text(NotesCopy.linkLine(links, store: model.store))
                                .textRole(.data)
                                .foregroundStyle(Theme.Colors.tess)
                                .lineLimit(1)
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }
                }
                Spacer(minLength: Theme.Spacing.s)
                Text(NotesCopy.when(note.updatedAt, now: now))
                    .textRole(.data)
                    .foregroundStyle(isNew ? Theme.Colors.tess : Theme.Colors.inkSecondary)
                    .fixedSize()
            }
            .padding(.vertical, Theme.Spacing.l)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the note")
    }
}

private struct NotesEmpty: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Nothing written yet.")
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
            Text("Write above, or tell Tess \u{201C}note: bar felt heavy\u{201D}. @ links a note to a thing.")
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
        }
    }
}

/// Copy for notes, kept in one place.
enum NotesCopy {
    static func context(count: Int, latest: Date?, now: Date) -> String {
        guard count > 0, let latest else { return "A place for loose thoughts" }
        let notes = count == 1 ? "One note" : "\(count) notes"
        return "\(notes), the latest \(when(latest, now: now, spoken: true))"
    }

    /// "now", "12 min", "3 h", "yesterday", "Tue", "14 Oct". Spoken form: "just now", "12 minutes ago"…
    static func when(_ date: Date, now: Date, spoken: Bool = false) -> String {
        let seconds = now.timeIntervalSince(date)
        let calendar = Calendar.current
        if seconds < 60 {
            return spoken ? "just now" : "now"
        }
        if seconds < 3600 {
            return spoken ? "\(Int(seconds / 60)) minutes ago" : "\(Int(seconds / 60)) min"
        }
        if calendar.isDate(date, inSameDayAs: now) {
            return spoken ? "\(Int(seconds / 3600)) hours ago" : "\(Int(seconds / 3600)) h"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(
            date,
            inSameDayAs: yesterday
        ) {
            return "yesterday"
        }
        if seconds < 6 * 86400 {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    /// @ mentions in cobalt, the rest in the surrounding ink.
    static func inked(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        for match in text.matches(of: /@\[[^\]]+\]|@[^\s@]+(?: [A-Z][^\s@]*)*/) {
            guard let lower = AttributedString.Index(match.range.lowerBound, within: attributed),
                  let upper = AttributedString.Index(match.range.upperBound, within: attributed) else { continue }
            attributed[lower ..< upper].foregroundColor = Theme.Colors.tess
        }
        return attributed
    }

    /// Everything after the first line, joined into one line.
    static func rest(of body: String) -> String {
        body.split(separator: "\n").dropFirst().map(String.init).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    @MainActor
    static func linkLine(_ links: [ObjectRecord], store: ObjectStore) -> String {
        links.map { $0.isClassObject ? ($0.classDef?.name ?? $0.title) : store.displayTitle(of: $0) }
            .joined(separator: " · ")
    }
}
