import SwiftUI
import TesseraCore

/// Reading, the shelf (ship list screen 7 under the one-line grammar, sheet money-reading-grammar): ‹ REVIEW, the
/// title, the context line ("Dune last night"), the writing line ("reading Dune"), then one line per book under
/// READING, NEXT, FINISHED and SET ASIDE, where it is as the value at the right. Titles as a typographic column: no
/// covers, no grid, no counts. A line opens its book (one tap down: the page drum). Finished and set-aside books
/// sit dimmer. At accessibility sizes the value sits under the title.
///
/// Entry: present `ReadingView()` from the area index once areas are shown (`AreasShown.isOn`).
struct ReadingView: View {
    var back = "Review"

    var body: some View {
        NavigationStack {
            ReadingPage(back: back)
                .navigationDestination(for: Route.self) { ObjectPage(route: $0) }
                .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.animateEntrance, true)
    }
}

private struct ReadingPage: View {
    let back: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var draft = ""
    @State private var made = 0
    @State private var spoke = false
    @FocusState private var writing: Bool

    var body: some View {
        let _ = model.revision
        let shelf = ReadingShelf(store: model.store, classes: model.classes, now: AppClock.now)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackWord(title: back) { dismiss() }
                    .entrance(0)
                Text("Reading")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0)
                Text(shelf.context)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.xs)
                    .entrance(1)

                AreaWritingLine(word: "Book", prompt: ReadingCopy.prompt, label: "Add a book", text: $draft,
                                focused: $writing, onSubmit: add)
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(2)

                if shelf.isEmpty {
                    Text("No books yet.")
                        .font(Theme.voice)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .padding(.top, Theme.Spacing.xxl)
                        .entrance(3)
                }

                ForEach(Array(shelf.sections.enumerated()), id: \.element.id) { index, section in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(section.word)
                            .textRole(.labelStrong)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.bottom, Theme.Spacing.xs)
                        ForEach(section.rows) { row in
                            BookLine(row: row, isCurrent: section.word == "Reading",
                                     isPast: section.word == "Finished" || section.word == "Set aside",
                                     stacked: typeSize.isAccessibilitySize)
                        }
                    }
                    .padding(.top, index == 0 ? Theme.Spacing.xxl : Theme.Spacing.xl)
                    .entrance(3 + min(index, 2))
                }
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
            .tesseraAnimation(Theme.Motion.house, value: shelf.sections)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .safeAreaInset(edge: .bottom, spacing: 0) { AreaTessLine() }
        .tesseraFeedback(.made, trigger: made)
        .onAppear {
            guard !spoke else { return }
            spoke = true
            if shelf.isEmpty, TessVoice.shared.note == nil {
                TessVoice.shared.say(ReadingCopy.emptyTess)
            }
        }
    }

    /// "Dune, in the queue." or "Dune, started." with UNDO 4 s (a new thing; amendment 7).
    private func add() {
        guard let intent = ReadingCapture.intent(draft) else { return }
        let engine = model.engine!
        let line: String
        let record: OpRecord
        let book: ObjectRecord
        do {
            switch intent {
            case let .queue(title):
                let done = try engine.perform(QueueBook(title: title), by: .user)
                (line, record, book) = (done.record.receipt ?? "\(done.output.title), in the queue.", done.record,
                                        done.output)
            case let .start(title):
                let queued = try engine.perform(QueueBook(title: title), by: .user).output
                let done = try engine.perform(StartReading(book: queued.id, time: AppClock.now), by: .user)
                (line, record, book) = (done.record.receipt ?? "\(queued.title), started.", done.record, queued)
            }
        } catch {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            draft = ""
            model.touch()
        }
        // Queuing a title he already marked private returns that book: its line is masked too.
        TessVoice.shared.say(AreaPrivacy.bookLine(line, book: book, store: model.store, classes: model.classes),
                             undo: record, holds: .seconds(4))
        made += 1
    }
}

/// One book: its name (larger and in full ink while it's being read, dimmer once finished or set aside), its value at
/// the right in Label tier.
private struct BookLine: View {
    let row: ReadingShelf.Row
    let isCurrent: Bool
    let isPast: Bool
    let stacked: Bool

    var body: some View {
        NavigationLink(value: Route.object(row.id)) {
            Group {
                if stacked {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        name
                        value
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                        name
                        Spacer(minLength: Theme.Spacing.m)
                        value
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.spoken)
        .accessibilityHint("Opens the book")
        .transition(.opacity)
    }

    private var name: some View {
        Text(row.name)
            .textRole(isCurrent ? .bodyStrong : .body)
            .foregroundStyle(isPast ? Theme.Colors.inkSecondary : Theme.Colors.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var value: some View {
        if let value = row.value {
            Text(value)
                .textRole(.label)
                .textCase(.uppercase)
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.inkSecondary)
        }
    }
}
