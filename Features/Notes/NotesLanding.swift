import SwiftUI
import TesseraCore

// The Notes landing, design 131 section 2 and the build sheet product/notes-lists-landing-build-sheet-oct22.md
// section 2A. Behind Review switch "Landing pages" (default Off). Its facts are Core's `NotesLanding` (#1230).

// MARK: - Words (build sheet section 3, T-N1 to T-N10)

enum NotesLandingWords {
    /// T-N1 to T-N4: the subtitle. The key word is a thing's name, or "own".
    static func subtitle(hasNotes: Bool, topThings: [String]) -> AccentedSentence {
        guard hasNotes else { return AccentedSentence(text: "A place for loose thoughts", key: nil) }
        switch topThings.count {
        case 0: return AccentedSentence(text: "Your notes are on their own", key: "own")
        case 1: return AccentedSentence(text: "\(topThings[0]) comes up most", key: topThings[0])
        default: return AccentedSentence(text: "\(topThings[0]) and \(topThings[1]) come up most", key: topThings[0])
        }
    }

    /// T-N5: "You write about A, B, and C." (2 things: "A and B"; 1: "A"); nil with none.
    static func paragraph(_ names: [String]) -> String? {
        names.isEmpty ? nil : "You write about \(LandingList.joined(names))"
    }

    /// T-N6: the filter found no thing.
    static func noMatch(_ typed: String) -> String {
        "No thing called \u{201C}\(typed)\u{201D}. Return writes it as a note"
    }

    /// T-N7: a book is open; the page adds the ink word "Read".
    static func reading(_ title: String) -> String {
        "\(title) is open"
    }

    /// T-N8: a note names a thing without linking it.
    static func names(weekday: String, thing: String) -> String {
        "Your note from \(weekday) names \(thing)"
    }

    /// T-N10: since he last looked. Several things (or notes): "New notes about A and B."
    static func newNotes(things: [String], loose: Bool, notes: Int) -> String? {
        guard notes > 0 else { return nil }
        let top = Array(things.prefix(2))
        if top.isEmpty {
            return loose ? (notes == 1 ? "A new loose note" : "New loose notes") : nil
        }
        return notes == 1 && top.count == 1 ? "A new note about \(top[0])"
            : top.count == 2 && notes == 1 ? "A new note about \(LandingList.joined(top))"
            : "New notes about \(LandingList.joined(top))"
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
            case openThing(Route)
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

    /// A note any surface would mask: Core's one rule (NotesLanding.isPrivate, #1230), the flag or walled words.
    @MainActor static func isPrivate(_ note: ObjectRecord, store: ObjectStore,
                                     classes: [SystemCatalog.Key: ClassDef]) -> Bool
    {
        NotesLanding(store: store, classes: classes).isPrivate(note)
    }

    @MainActor
    static func load(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], lastSeen: Date?,
                     linkSuggest: Bool) -> NotesLandingFacts
    {
        let core = NotesLanding(store: store, classes: classes)
            .facts(NotesLanding.Options(margin: true, linkSuggest: linkSuggest, lastSeen: lastSeen, now: AppClock.now))
        var facts = NotesLandingFacts()
        facts.hasNotes = core.hasNotes
        facts.hasLoose = core.hasLoose
        facts.hasPrivate = core.hasPrivate
        let routes = Dictionary(core.things.map { thing in
            (thing.id, thing.classID.map(Route.classDef) ?? .object(thing.id))
        }, uniquingKeysWith: { first, _ in first })
        facts.things = core.things.map { thing in
            Thing(id: thing.id, route: routes[thing.id] ?? .object(thing.id), name: thing.name, weight: thing.weight,
                  latest: .distantPast)
        }
        for (index, entry) in core.margin.enumerated() {
            let act: Margin.Act = switch entry.target {
            case let .link(note, _): .openNote(note)
            case let .about(thing?): .openThing(routes[thing] ?? .object(thing))
            case .about(nil), .makeThing: .none
            }
            let margin = Margin(
                id: "\(entry.kind)-\(index)",
                text: entry.sentence.text,
                word: entry.action ?? "",
                act: act
            )
            switch entry.kind {
            case .waiting: facts.waiting.append(margin)
            case .new: facts.new.append(margin)
            }
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
            case .loose: return !isPrivate && (note.outgoingLinks ?? [])
                .allSatisfy { $0.toObject == nil && $0.toClass == nil }
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
