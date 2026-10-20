import SwiftUI
import TesseraCore

/// One book (ship list screen 5, sheet money-reading-grammar fifth panel): the title is the hero, one context line
/// ("p 142 of 612, started 9 days ago"), then the page drum: the page at hero size with "of 612" beside it, the pages
/// either side dim. Drag it to turn; release writes `SetBookPage` ("Dune, p 168.", UNDO 10 s, a change). A tap on the
/// numeral types the page instead (VoiceOver's path, G305). FINISHED is a hold (0.6 s) and, under VoiceOver, a named
/// action only ("Finish Dune", G304); it plays `.done` once and opens "One line on it?". SET ASIDE is a plain word and
/// plays nothing. A queued, finished or set-aside book shows START READING instead of the drum.
///
/// A book is a process: leaving this page while its Reading process runs suspends it (resume is on Now).
struct BookPage: View {
    let bookID: UUID
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var typing = false
    @State private var typed = ""
    @State private var review = ""
    @State private var finishedNow = false
    @State private var finishes = 0
    @FocusState private var pageFocused: Bool
    @FocusState private var reviewFocused: Bool

    private var shelf: Bookshelf {
        Bookshelf(store: model.store, classes: model.classes)
    }

    var body: some View {
        let _ = model.revision
        Group {
            if let book = model.object(bookID), !book.isDeleted {
                page(book)
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    BackWord(title: "Reading") { dismiss() }
                    Text("Book gone.")
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.ink)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background { ThemedBackground() }
        .background { EdgeSwipeBack() }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { AreaTessLine() }
        .tesseraFeedback(.done, trigger: finishes)
        .onAppear(perform: announceArrival)
        .onDisappear(perform: suspendIfRunning)
    }

    private func page(_ book: ObjectRecord) -> some View {
        let store = model.store
        let state = store.value("state", of: book)?.stringValue ?? "queued"
        let current = shelf.page(of: book)
        let pages = shelf.pages(of: book)
        let process = model.processes.process(for: book)
        let started = process?.startedAt
        let now = AppClock.now
        let line = state == "reading"
            ? ReadingCopy.bookContext(page: current, pages: pages, started: started, now: now)
            : stateLine(book, state: state, page: current, pages: pages)
        let spokenLine = state == "reading"
            ? ReadingCopy.spokenBookContext(page: current, pages: pages, started: started, now: now) : line
        let reviewLine = store.value("review", of: book)?.stringValue.flatMap { $0.isEmpty ? nil : $0 }
        let isPrivate = store.value("isPrivate", of: book) == .bool(true)

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BackWord(title: "Reading") { dismiss() }
                    .entrance(0)
                Text(book.title)
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .entrance(0, hero: true)
                Text(line)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.context)
                    .padding(.top, Theme.Spacing.xs)
                    .accessibilityLabel(spokenLine)
                    .entrance(1)

                if state == "reading" {
                    PageDrum(page: current, pages: pages, onSet: { setPage($0, of: book) },
                             onType: { openTyping(current) })
                        .padding(.top, Theme.Spacing.xl)
                        .entrance(2)
                    if typing {
                        AreaWritingLine(word: "Page", prompt: "\(current)", label: "Page", text: $typed,
                                        focused: $pageFocused, keyboard: .numberPad) { submitTyped(book) }
                            .padding(.top, Theme.Spacing.m)
                            .transition(.opacity)
                    }
                    HStack(spacing: Theme.Spacing.xxl) {
                        finishKey(book)
                        Button("Set aside") { setAside(book) }
                            .buttonStyle(InkLabelWordStyle())
                            .frame(minHeight: 44)
                            .accessibilityLabel("Set \(book.title) aside")
                    }
                    .padding(.top, Theme.Spacing.xl)
                    .entrance(3)
                } else {
                    Button("Start reading") { start(book) }
                        .buttonStyle(InkLabelWordStyle())
                        .frame(minHeight: 44)
                        .padding(.top, Theme.Spacing.xl)
                        .accessibilityLabel("Start reading \(book.title)")
                        .entrance(2)
                }

                if state == "finished" {
                    if let reviewLine {
                        Text(reviewLine)
                            .textRole(.body)
                            .foregroundStyle(Theme.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, Theme.Spacing.xl)
                            .entrance(3)
                    } else {
                        AreaWritingLine(word: "Line", prompt: ReadingCopy.reviewPrompt, label: "One line on it",
                                        text: $review, focused: $reviewFocused) { keepReview(book) }
                            .padding(.top, Theme.Spacing.xl)
                            .transition(.opacity)
                    }
                }

                Button(isPrivate ? "Not private" : "Keep private") { setPrivate(!isPrivate, book) }
                    .buttonStyle(InkLabelWordStyle())
                    .frame(minHeight: 44)
                    .padding(.top, Theme.Spacing.xxl)
                    .accessibilityHint(isPrivate ? "Shows the title everywhere" :
                        "Shows Private book outside this page")
                    .entrance(4)
            }
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.section)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tesseraAnimation(Theme.Motion.house, value: state)
            .tesseraAnimation(Theme.Motion.house, value: typing)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func stateLine(_ book: ObjectRecord, state: String, page: Int, pages: Int?) -> String {
        switch state {
        case "finished":
            let when = model.store.value("finishedAt", of: book)?.dateValue
            return when.map { "Finished \(ReadingCopy.finished($0))" } ?? "Finished"
        case "dropped": return "Set aside, \(ReadingCopy.page(page, of: pages))"
        default: return "In the queue"
        }
    }

    /// Hold 0.6 s to finish; the hold is the only sighted path and the named action the only VoiceOver one.
    private func finishKey(_ book: ObjectRecord) -> some View {
        Text("Finished")
            .textRole(.labelStrong)
            .textCase(.uppercase)
            .foregroundStyle(Theme.Colors.ink)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.6) { finish(book) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(ReadingCopy.finishName(book.title))
            .accessibilityHint("Use the action to finish")
            .accessibilityAction(named: ReadingCopy.finishName(book.title)) { finish(book) }
    }

    // MARK: Writes

    private func setPage(_ page: Int, of book: ObjectRecord) {
        guard page != shelf.page(of: book) else { return }
        guard let done = try? model.engine.perform(SetBookPage(book: book.id, page: page, time: AppClock.now),
                                                   by: .user)
        else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        model.touch()
        say(done.record.receipt ?? "\(book.title), p \(page).", book: book, undo: done.record,
            holds: .seconds(10))
    }

    private func openTyping(_: Int) {
        typed = ""
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { typing = true }
        pageFocused = true
    }

    private func submitTyped(_ book: ObjectRecord) {
        pageFocused = false
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { typing = false }
        guard let page = Int(typed.trimmingCharacters(in: .whitespaces)) else { return }
        setPage(page, of: book)
    }

    private func finish(_ book: ObjectRecord) {
        guard let done = try? model.engine.perform(FinishBook(book: book.id, time: AppClock.now), by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        say(done.record.receipt ?? "\(book.title), finished.", book: book, undo: done.record,
            holds: .seconds(10))
        finishes += 1
        reviewFocused = true
    }

    /// The review after a finish: written onto the same finish ("Dune, finished: slow start, great end.").
    private func keepReview(_ book: ObjectRecord) {
        let line = review.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }
        let when = model.store.value("finishedAt", of: book)?.dateValue ?? AppClock.now
        guard let done = try? model.engine.perform(FinishBook(book: book.id, review: line, time: when), by: .user)
        else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        review = ""
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        say(done.record.receipt ?? "\(book.title), finished.", book: book, undo: done.record,
            holds: .seconds(10))
    }

    private func setAside(_ book: ObjectRecord) {
        guard let done = try? model.engine.perform(SetBookAside(book: book.id, time: AppClock.now), by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        say(done.record.receipt ?? "\(book.title), set aside.", book: book, undo: done.record,
            holds: .seconds(10))
    }

    private func start(_ book: ObjectRecord) {
        guard let done = try? model.engine.perform(StartReading(book: book.id, time: AppClock.now), by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { model.touch() }
        say(done.record.receipt ?? "\(book.title), started.", book: book, undo: done.record,
            holds: .seconds(4))
    }

    private func setPrivate(_ isPrivate: Bool, _ book: ObjectRecord) {
        guard let done = try? model.engine.perform(EditBook(book: book.id, isPrivate: isPrivate), by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        model.touch()
        TessVoice.shared.say(isPrivate ? "Book, kept private." : "\(book.title), not private.",
                             undo: done.record, holds: .seconds(10))
    }

    /// Every receipt goes through the mask: a private book reads "Private book", its review left on this page.
    private func say(_ receipt: String, book: ObjectRecord, undo record: OpRecord, holds: Duration) {
        TessVoice.shared.say(AreaPrivacy.bookLine(receipt, book: book, store: model.store, classes: model.classes),
                             undo: record, holds: holds)
    }

    // MARK: The process

    /// Resumed from Now: VoiceOver hears where he stopped, once (G311).
    private func announceArrival() {
        guard let book = model.object(bookID), model.processes.process(for: book)?.state == .running else { return }
        AccessibilityNotification.Announcement(ReadingCopy.arrival(title: book.title, page: shelf.page(of: book)))
            .post()
    }

    /// Leaving the page puts a running book back to suspended, at its page.
    private func suspendIfRunning() {
        guard let book = model.object(bookID), let process = model.processes.process(for: book),
              process.state == .running else { return }
        let page = shelf.page(of: book)
        _ = try? model.engine.perform(SuspendProcess(process: process.id, resumePoint: ResumePoint(index: page),
                                                     nextStep: shelf.line(for: book), time: AppClock.now),
                                      by: .user)
        model.touch()
    }
}

/// The page drum: the reps drum's sibling. The page at hero size, "of 612" beside it, the page either side dim. A
/// vertical drag turns it a page per row, ticking `.selection` no closer than 40 ms apart; it never coasts, so Reduce
/// Motion and Low Power need no other form. Release writes the page. VoiceOver: one adjustable element ("page 142 of
/// 612") whose steps write the page, and a named action to type it.
private struct PageDrum: View {
    let page: Int
    let pages: Int?
    let onSet: (Int) -> Void
    let onType: () -> Void

    @State private var dragged: Int?
    @State private var tick = 0
    @State private var lastTick = Date.distantPast
    @ScaledMetric(relativeTo: .largeTitle) private var pitch: CGFloat = 72

    private var shown: Int {
        dragged ?? page
    }

    private var upper: Int {
        min(99999, max(pages.map { $0 + 50 } ?? 99999, page))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            neighbour(shown - 1)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                Text("\(shown)")
                    .textRole(.heroNumber)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.ink)
                    .contentTransition(.identity)
                if let pages {
                    Text("of \(pages)")
                        .textRole(.title)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
            .onTapGesture(perform: onType)
            neighbour(shown + 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    let steps = Int((-value.translation.height / pitch).rounded())
                    let next = min(max(0, page + steps), upper)
                    if next != shown {
                        dragged = next
                        // The tick floor: never closer than 40 ms; a skipped tick is dropped, not queued.
                        if Date().timeIntervalSince(lastTick) >= 0.04 {
                            lastTick = Date()
                            tick += 1
                        }
                    }
                }
                .onEnded { _ in
                    if let landed = dragged {
                        tick += 1
                        onSet(landed)
                    }
                    dragged = nil
                }
        )
        .tesseraFeedback(.selection, trigger: tick)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue(ReadingCopy.spokenPage(page, of: pages))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onSet(min(upper, page + 1))
            case .decrement: onSet(max(0, page - 1))
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Type the page", onType)
    }

    private func neighbour(_ value: Int) -> some View {
        Text(value >= 0 ? "\(value)" : " ")
            .textRole(.titleNumber)
            .monospacedDigit()
            .foregroundStyle(Theme.Colors.inkTertiary)
            .accessibilityHidden(true)
    }
}
