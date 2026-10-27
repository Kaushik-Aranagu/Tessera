import SwiftUI
import TesseraCore

/// The Notes landing on the shared kit (246, landing contract): the word wall of note titles in the keystone slot,
/// the doors on the dial, one line about the last note, "New note" at the foot. Private notes never reach the wall.
struct NotesLandingPage: View {
    let zoom: Namespace.ID
    let openNote: (UUID) -> Void
    let openThing: (Route) -> Void
    let openDoor: (NotesDoor) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus = 0
    @State private var switcherIndex = 0
    @State private var switcherVerticalIndex = 0
    @State private var widgetIndex = 0
    @State private var writing = false
    @State private var draft = ""

    private struct Shown {
        let words: [WallWord]
        let doors: [DialDoor]
        let stateLine: [String]
        let needs: [String]
        let widget: [WidgetItem]
        let latest: ObjectRecord?
        let latestIsPrivate: Bool
        let count: Int
    }

    var body: some View {
        let _ = model.revision
        let shown = load()
        LandingScaffold(title: "Log", accent: Self.plum(scheme), navWord: "Bridge", onBack: { dismiss() },
                        switcher: ["Newest", "Due", "Pinned", "From Tess"],
                        switcherVertical: ["Today", "This week", "Earlier"],
                        switcherIndex: $switcherIndex, switcherVerticalIndex: $switcherVerticalIndex,
                        needs: shown.needs,
                        keystone: {
                            LandingKeystone(label: "Your notes") {
                                WordWallView(words: shown.words) { id in
                                    if let uuid = UUID(uuidString: id) { openNote(uuid) }
                                }
                            }
                        },
                        caption: ["Tap a word to open its note."],
                        widget: shown.widget, widgetIndex: $widgetIndex,
                        openWidget: { item in
                            if let uuid = UUID(uuidString: item.id) { openNote(uuid) }
                        },
                        glyph: { item in LandingGlyph(item: item, color: Self.plum(scheme), room: .log) },
                        doors: shown.doors, focus: $focus,
                        openDoor: { door in
                            switch door.id {
                            case "loose": openDoor(.loose)
                            case "private": openDoor(.privates)
                            default: openDoor(.all)
                            }
                        },
                        action: LandingFootAction(word: "Write", object: "A note", hint: "Writes a note",
                                                  alternates: [
                                                      .init(verb: "Speak", object: "To Tess") { TessVoice.shared.say("Say \"note: ...\" and I'll keep it.") },
                                                      .init(verb: "List", object: "A checklist") { draft = ""; writing = true },
                                                  ]) {
                            draft = ""
                            writing = true
                        })
            .toolbar(.hidden, for: .navigationBar)
            .alert("New note", isPresented: $writing) {
                TextField("", text: $draft)
                Button("Keep") { write() }
                Button("Cancel", role: .cancel) {}
            }
    }

    // MARK: Facts

    private func load() -> Shown {
        let landing = NotesLanding(store: model.store, classes: model.classes)
        let notes = NoteList(store: model.store, classes: model.classes).recent(limit: 60)
        let open = notes.filter { !landing.isPrivate($0) }
        let hidden = notes.count - open.count
        let facts = NotesLandingFacts.load(
            store: model.store,
            classes: model.classes,
            lastSeen: nil,
            linkSuggest: false
        )
        let words = open.enumerated().map { index, note in
            WallWord(id: note.id.uuidString, text: Self.short(note.title),
                     weight: 1 - Double(index) / Double(max(open.count, 1)))
        }
        let slate = scheme == .dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
        let now = AppClock.now
        var doors: [DialDoor] = []
        doors.append(DialDoor(id: "all", name: "All notes", count: open.isEmpty ? nil : "\(open.count)",
                              color: Theme.Colors.ink,
                              label: open.first.map { "Newest \(NotesCopy.when($0.updatedAt, now: now))" },
                              lines: open.prefix(3).map { Self.short($0.title) }))
        if facts.hasLoose {
            doors.append(DialDoor(id: "loose", name: "Loose", color: LandingAccent.notes, label: "Not about a thing"))
        }
        if hidden > 0 || facts.hasPrivate {
            doors.append(DialDoor(id: "private", name: "Private", count: hidden > 0 ? "\(hidden)" : nil, color: slate,
                                  lines: ["\(max(hidden, 1)) private \(hidden == 1 ? "note" : "notes")"]))
        }
        let top = Array(facts.things.prefix(2).map(\.name))
        let sentence = NotesLandingWords.subtitle(hasNotes: facts.hasNotes, topThings: top).text
        let line = notes.isEmpty ? ["Write the first thing down."] : [sentence, "\(notes.count) notes."]
        let latest = notes.first
        let needs = notes.isEmpty ? ["Write the first thing down."] : [line[0], "\(open.count) notes here."]
        let widget = open.prefix(4).map { note in
            WidgetItem(id: note.id.uuidString, header: "Newest", big: Self.short(note.title).uppercased(),
                       middle: "Written \(NotesCopy.when(note.updatedAt, now: now))",
                       small: "Tap to open it", strikeable: false)
        }
        return Shown(words: words, doors: doors, stateLine: line, needs: needs, widget: widget, latest: latest,
                     latestIsPrivate: latest.map { landing.isPrivate($0) } ?? false, count: notes.count)
    }

    private static let small: Set<String> = [
        "and",
        "the",
        "a",
        "an",
        "of",
        "to",
        "by",
        "in",
        "on",
        "or",
        "for",
        "with",
        "at",
        "is",
    ]

    /// A wall word: the title cut on a whole word at 14 characters, then stepped back past trailing small words
    /// and punctuation (228). Never "...", never an empty word.
    /// The Log's own colour (sheet 241 and 283: plum 8A4570 / E3A3CB), not the app-wide Notes violet.
    static func plum(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0xE3A3CB) : Color(hex: 0x8A4570)
    }

    static func short(_ title: String) -> String {
        let words = title.replacingOccurrences(of: "@", with: "").split(separator: " ").map(String.init)
        var kept: [String] = []
        for word in words {
            let next = (kept + [word]).joined(separator: " ")
            if next.count > 14, !kept.isEmpty {
                break
            }
            kept.append(word)
        }
        while kept.count > 1, let last = kept.last,
              Self.small.contains(last.lowercased().trimmingCharacters(in: .punctuationCharacters))
        {
            kept.removeLast()
        }
        let joined = kept.joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: ",;:"))
        return joined.isEmpty ? title : joined
    }

    @ViewBuilder
    private func brief(_ shown: Shown) -> some View {
        if let latest = shown.latest {
            let when = NotesCopy.when(latest.updatedAt, now: AppClock.now)
            if shown.latestIsPrivate {
                Text("You last wrote a private note, \(when).")
                    .font(.custom("Figtree", size: 15, relativeTo: .callout))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
            } else {
                (Text("You last wrote in ") + Text(Self.short(latest.title)).fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.ink) + Text(", \(when)."))
                    .font(.custom("Figtree", size: 15, relativeTo: .callout))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    // MARK: Writing

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
