import SwiftUI
import TesseraCore

// CLOUD-WRITTEN, NOT COMPILED (see the PR). The Notes landing, design 131 section 2 and the build sheet
// product/notes-lists-landing-build-sheet-oct22.md section 2A. Behind Review switch `notesLanding` (default Off).
//
// Core's `NotesLanding.facts` (Core PR 1) is not on master, so `NotesLandingFacts` below computes the same facts from
// APIs that exist today. When Core's facts land, delete `NotesLandingFacts.load` and map Core's struct onto this one.

// MARK: - Words (build sheet section 3, T-N1 to T-N10)

enum NotesLandingWords {
    /// T-N1 to T-N4: the subtitle. The key word is a thing's name, or "own".
    static func subtitle(hasNotes: Bool, topThings: [String]) -> AccentedSentence {
        guard hasNotes else { return AccentedSentence(text: "A place for loose thoughts.", key: nil) }
        switch topThings.count {
        case 0: return AccentedSentence(text: "Your notes are on their own.", key: "own")
        case 1: return AccentedSentence(text: "\(topThings[0]) comes up most.", key: topThings[0])
        default: return AccentedSentence(text: "\(topThings[0]) and \(topThings[1]) come up most.", key: topThings[0])
        }
    }

    /// T-N5: "You write about A, B, and C." (2 things: "A and B"; 1: "A"); nil with none.
    static func paragraph(_ names: [String]) -> String? {
        names.isEmpty ? nil : "You write about \(LandingList.joined(names))."
    }

    /// T-N6: the filter found no thing.
    static func noMatch(_ typed: String) -> String {
        "No thing called \u{201C}\(typed)\u{201D}. Return writes it as a note."
    }

    /// T-N7: a book is open; the page adds the ink word "Read".
    static func reading(_ title: String) -> String {
        "\(title) is open."
    }

    /// T-N8: a note names a thing without linking it.
    static func names(weekday: String, thing: String) -> String {
        "Your note from \(weekday) names \(thing)."
    }

    /// T-N10: since he last looked. Several things (or notes): "New notes about A and B."
    static func newNotes(things: [String], loose: Bool, notes: Int) -> String? {
        guard notes > 0 else { return nil }
        let top = Array(things.prefix(2))
        if top.isEmpty {
            return loose ? (notes == 1 ? "A new loose note." : "New loose notes.") : nil
        }
        return notes == 1 && top.count == 1 ? "A new note about \(top[0])."
            : top.count == 2 && notes == 1 ? "A new note about \(LandingList.joined(top))."
            : "New notes about \(LandingList.joined(top))."
    }

    /// Whether a typed filter matches a name by the start of any of its words (case and accent blind).
    static func matches(_ name: String, filter: String) -> Bool {
        func fold(_ text: String) -> String {
            text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        }
        let needle = fold(filter.trimmingCharacters(in: .whitespaces))
        guard !needle.isEmpty else { return true }
        let hay = fold(name)
        return hay.hasPrefix(needle) || hay.split(separator: " ").contains { $0.hasPrefix(needle) }
            || hay.contains(" " + needle)
    }
}

// MARK: - Facts

struct NotesLandingFacts {
    struct Thing: Identifiable, Equatable {
        let id: UUID
        let route: Route
        let name: String
        let weight: Int
        let latest: Date
    }

    /// A margin sentence with its link word and what the word does.
    struct Margin: Identifiable, Equatable {
        enum Act: Equatable {
            case openNote(UUID)
            case none
        }

        let id: String
        let text: String
        let word: String
        let act: Act
    }

    var hasNotes = false
    /// By weight (notes written), ties latest first, at most 12. Names only: no counts ever reach a view.
    var things: [Thing] = []
    var hasLoose = false
    var hasPrivate = false
    var waiting: [Margin] = []
    var new: [Margin] = []
    /// The book being read, by last touched: its id and the name a page may show.
    var reading: (id: UUID, title: String)?

    @MainActor
    /// A note any surface would mask: the private flag, or words that are walled (ObjectPrivacy's label).
    static func isPrivate(_ note: ObjectRecord, store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) -> Bool {
        store.value("isPrivate", of: note) == .bool(true)
            || ObjectPrivacy.shownLabel(of: note, in: store, classes: classes) != nil
    }

    static func load(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], lastSeen: Date?,
                     linkSuggest: Bool) -> NotesLandingFacts
    {
        var facts = NotesLandingFacts()
        let notes = NoteList(store: store, classes: classes).recent(limit: 500)
        facts.hasNotes = !notes.isEmpty

        struct Tally {
            var route: Route
            var name: String
            var weight = 0
            var latest = Date.distantPast
        }
        var tallies: [UUID: Tally] = [:]
        var linkedIDs: [UUID: Set<UUID>] = [:]
        var newTallies: [UUID: Int] = [:]
        var newLoose = 0
        var newNotes = 0

        for note in notes {
            // A private note adds nothing: no thing, no weight, no sentence (build sheet 2A, N-A7). Private by the flag
            // or by its words (QA on #1226): whatever any surface would mask.
            if Self.isPrivate(note, store: store, classes: classes) {
                facts.hasPrivate = true
                continue
            }
            let isNew = lastSeen.map { note.createdAt > $0 } ?? false
            var linked = false
            for link in note.outgoingLinks ?? [] {
                let key: UUID, route: Route, name: String
                if let target = link.toObject, !target.isDeleted {
                    // A walled thing contributes nothing, as its note would not.
                    guard ObjectPrivacy.shownLabel(of: target, in: store, classes: classes) == nil else { continue }
                    key = target.id
                    route = .object(target.id)
                    name = store.displayTitle(of: target)
                } else if let classDef = link.toClass {
                    key = classDef.id
                    route = .classDef(classDef.id)
                    name = classDef.name
                } else {
                    continue
                }
                linked = true
                linkedIDs[note.id, default: []].insert(key)
                var tally = tallies[key] ?? Tally(route: route, name: name)
                tally.weight += 1
                tally.latest = max(tally.latest, note.updatedAt)
                tallies[key] = tally
                if isNew {
                    newTallies[key, default: 0] += 1
                }
            }
            if !linked {
                facts.hasLoose = true
            }
            if isNew {
                newNotes += 1
                newLoose += linked ? 0 : 1
            }
        }

        facts.things = tallies.map { Thing(id: $0.key, route: $0.value.route, name: $0.value.name,
                                           weight: $0.value.weight, latest: $0.value.latest) }
            .sorted { ($0.weight, $0.latest) > ($1.weight, $1.latest) }
            .prefix(12).map { $0 }

        // Waiting: a note names a thing in words without linking it (switch notesLinkSuggest).
        if linkSuggest {
            outer: for note in notes.prefix(60) where !Self.isPrivate(note, store: store, classes: classes) {
                let body = store.value("body", of: note)?.stringValue ?? ""
                for thing in facts.things where thing.name.count >= 3 && !(linkedIDs[note.id]?.contains(thing.id) ?? false)
                    && body.range(of: thing.name, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                {
                    let weekday = note.updatedAt.formatted(.dateTime.weekday(.abbreviated))
                    facts.waiting.append(Margin(id: "link-\(note.id)",
                                                text: NotesLandingWords.names(weekday: weekday, thing: thing.name),
                                                word: LandingSentences.linkThem, act: .openNote(note.id)))
                    break outer
                }
            }
        }

        // New: since he last looked.
        let newNames = newTallies.sorted { $0.value > $1.value }
            .compactMap { tallies[$0.key]?.name }
        if let line = NotesLandingWords.newNotes(things: newNames, loose: newLoose > 0, notes: newNotes) {
            facts.new.append(Margin(id: "new", text: line, word: "", act: .none))
        }

        // Reading: only when a book is being read.
        if let book = Bookshelf(store: store, classes: classes).lastTouchedReading(), !book.isDeleted {
            let shown = ObjectPrivacy.shownLabel(of: book, in: store, classes: classes) ?? book.title
            facts.reading = (book.id, shown)
        }
        return facts
    }
}

// MARK: - Which page opens from the landing

/// Pages the landing pushes: all notes (the old front, kept), notes with no thing, private notes.
enum NotesDoor: Hashable {
    case all, loose, privates
}

// MARK: - The page

/// The landing on Builder B's `LandingPage`: the subtitle sentence, the write-and-search field and the things
/// paragraph as the lead, the margin as the Waiting and New bands, "All notes" as the one door, Read as the action.
struct NotesLandingPage: View {
    let zoom: Namespace.ID
    let openNote: (UUID) -> Void
    let openThing: (Route) -> Void
    let openDoor: (NotesDoor) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft = ""
    @State private var seenAtOpen: Date?
    @State private var spoke = false
    @FocusState private var writing: Bool

    private var margin: Bool {
        Choice.value("notesMargin", options: ["Off", "On"], default: "Off") == "On"
    }

    private var linkSuggest: Bool {
        Choice.value("notesLinkSuggest", options: ["Off", "On"], default: "Off") == "On"
    }

    var body: some View {
        let _ = model.revision
        let facts = NotesLandingFacts.load(store: model.store, classes: model.classes, lastSeen: seenAtOpen,
                                           linkSuggest: linkSuggest)
        let top = Array(facts.things.prefix(2).map(\.name))
        let sentence = NotesLandingWords.subtitle(hasNotes: facts.hasNotes, topThings: top)
        let accent = LandingAccent.notes
        LandingPage(back: (title: "Home", action: { dismiss() }),
                    title: "Notes",
                    sentence: sentence.attributed(accent: accent),
                    accent: accent,
                    running: facts.reading.map { [LandingLine(text: NotesLandingWords.reading($0.title))] } ?? [],
                    waiting: margin ? facts.waiting.map(line) : [],
                    new: margin ? facts.new.map(line) : [],
                    lead: {
                        // N3 first under the subtitle, never scrolled under anything; N4 the things; N5 end words.
                        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                            writeField
                            thingsParagraph(facts)
                            endWords(facts)
                        }
                    },
                    doors: [LandingDoor(word: "All notes") { openDoor(.all) }],
                    // N7: the page's one action underline, only while a book is being read.
                    action: facts.reading.map { book in
                        LandingAction(word: "Read", hint: "Opens \(book.title)") { openThing(.object(book.id)) }
                    })
            .background { ThemedBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if seenAtOpen == nil {
                    seenAtOpen = LandingSeen.date("notes")
                }
                LandingSeen.mark("notes", at: AppClock.now)
                // Empty first use: Tess's own line, once, and no "Nothing written yet." band.
                if !facts.hasNotes, !spoke {
                    spoke = true
                    TessVoice.shared.say("Say \"note: bar felt heavy\" and I'll keep it here.")
                }
            }
    }

    private func line(_ entry: NotesLandingFacts.Margin) -> LandingLine {
        guard !entry.word.isEmpty else { return LandingLine(text: entry.text) }
        return LandingLine(text: entry.text, link: (word: entry.word, action: {
            if case let .openNote(id) = entry.act {
                openNote(id)
            }
        }))
    }

    // MARK: Pieces

    private var writeField: some View {
        TextField("", text: $draft, prompt: Text(LandingSentences.notesPrompt.text)
            .foregroundStyle(Theme.Colors.inkSecondary), axis: .vertical)
            .textRole(.field)
            .foregroundStyle(Theme.Colors.ink)
            .focused($writing)
            .submitLabel(.done)
            .lineLimit(1 ... 4)
            .frame(minHeight: 44, alignment: .leading)
            // A vertical-axis field never submits on Return; a typed newline is Return (as the old writing line).
            .onChange(of: draft) { _, new in
                if new.contains("\n") {
                    draft = new.replacing("\n", with: " ").trimmingCharacters(in: .whitespaces)
                    write()
                }
            }
            .accessibilityLabel("Search or write")
            .accessibilityHint("Return writes a note. @ links a thing.")
    }

    @ViewBuilder
    private func thingsParagraph(_ facts: NotesLandingFacts) -> some View {
        if !facts.things.isEmpty {
            let shown = facts.things.filter { NotesLandingWords.matches($0.name, filter: draft) }
            if shown.isEmpty {
                Text(NotesLandingWords.noMatch(draft.trimmingCharacters(in: .whitespaces)))
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            } else {
                Text(paragraph(shown, all: facts.things))
                    .tint(LandingAccent.notes)
                    .environment(\.openURL, OpenURLAction { url in
                        guard let route = route(for: url, in: facts) else { return .discarded }
                        openThing(route)
                        return .handled
                    })
                    .tesseraAnimation(.easeOut(duration: 0.15), value: draft)
            }
        }
    }

    /// One sentence: "You write about A, B, and C." Each thing an underlined link in violet; the top three at the
    /// large step, the rest at 21. The underline is the only line on the page besides the one action.
    private func paragraph(_ shown: [NotesLandingFacts.Thing], all: [NotesLandingFacts.Thing]) -> AttributedString {
        let topIDs = Set(all.prefix(3).map(\.id))
        var result = AttributedString("You write about ")
        result.font = Theme.voice(size: 21)
        result.foregroundColor = Theme.Colors.inkSecondary
        for (index, thing) in shown.enumerated() {
            var word = AttributedString(thing.name)
            word.font = Theme.voice(size: topIDs.contains(thing.id) ? 34 : 21)
            word.link = URL(string: "tessera-thing://\(thing.id.uuidString)")
            word.underlineStyle = Text.LineStyle(pattern: .solid, color: LandingAccent.notes)
            result += word
            var glue = AttributedString(Self.glue(index: index, count: shown.count))
            glue.font = Theme.voice(size: 21)
            glue.foregroundColor = Theme.Colors.inkSecondary
            result += glue
        }
        return result
    }

    private static func glue(index: Int, count: Int) -> String {
        if index == count - 1 {
            return "."
        }
        if count == 2 {
            return " and "
        }
        return index == count - 2 ? ", and " : ", "
    }

    private func route(for url: URL, in facts: NotesLandingFacts) -> Route? {
        guard url.scheme == "tessera-thing", let host = url.host(), let id = UUID(uuidString: host) else { return nil }
        return facts.things.first { $0.id == id }?.route
    }

    /// N5: Loose and Private, quieter words at the end of the field, underlined in violet.
    @ViewBuilder
    private func endWords(_ facts: NotesLandingFacts) -> some View {
        if facts.hasLoose || facts.hasPrivate {
            HStack(spacing: Theme.Spacing.xl) {
                if facts.hasLoose {
                    endWord("Loose", door: .loose)
                }
                if facts.hasPrivate {
                    endWord("Private", door: .privates)
                }
            }
        }
    }

    private func endWord(_ word: String, door: NotesDoor) -> some View {
        Button { openDoor(door) } label: {
            Text(word)
                .textRole(.body)
                .underline(true, color: LandingAccent.notes)
                .foregroundStyle(Theme.Colors.ink.opacity(0.66))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .accessibilityLabel("\(word) notes, link")
    }

    // MARK: Writing

    /// Return writes the text as a note (the existing path), clears the field and says "Note kept." with UNDO 10 s.
    private func write() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if looksLikeClaudeKey(text) {
            draft = ""
            TessVoice.shared.say(claudeKeyLine)
            return
        }
        guard let result = try? model.engine.perform(CreateNote(body: text), by: .user) else {
            TessVoice.shared.say("Didn't save that. Try again.")
            return
        }
        let isPrivate = model.store.value("isPrivate", of: result.output) == .bool(true)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            draft = ""
            model.touch()
        }
        TessVoice.shared.say(isPrivate ? "Private note, kept." : "Note kept.", undo: result.record)
    }
}

// MARK: - Loose and Private notes

/// The notes with no thing, or the private notes, as the existing rows. A private row reads "Private note" plus its
/// time (`NoteRow` already hides the words of a private note).
struct NotesDoorPage: View {
    let door: NotesDoor
    let zoom: Namespace.ID
    let open: (UUID) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = model.revision
        let store = model.store
        let notes = NoteList(store: store, classes: model.classes).recent(limit: 500).filter { note in
            let isPrivate = NotesLandingFacts.isPrivate(note, store: store, classes: model.classes)
            switch door {
            case .privates: return isPrivate
            case .loose: return !isPrivate && (note.outgoingLinks ?? []).allSatisfy { $0.toObject == nil && $0.toClass == nil }
            case .all: return true
            }
        }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ Notes")
                        .textRole(.data)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(HandleButtonStyle())
                Text(door == .privates ? "Private" : "Loose")
                    .textRole(.title)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(notes, id: \.id) { note in
                        NoteRow(note: note, now: AppClock.now, isNew: false) { open(note.id) }
                            .matchedTransitionSource(id: note.id, in: zoom)
                    }
                }
                .padding(.top, Theme.Spacing.xl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.gutter)
            .padding(.top, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.section)
        }
        .scrollIndicators(.hidden)
        .background { ThemedBackground() }
        .toolbar(.hidden, for: .navigationBar)
    }
}
