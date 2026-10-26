import SwiftUI
import TesseraCore

/// The Log as content for the standing shell (sheet 283 v5): level 0 is the landing (the same content as
/// `NotesLandingPage`), level 1 a door page (All notes, Loose, Private): the Door title and a Page of the newest notes'
/// titles. Private notes never reach the wall or a page as words. Pure: no views, no store reads.
struct NotesRoomContent: RoomContent {
    static let room = "log"

    struct Facts: Equatable {
        var words: [WallWord] = []
        var doors: [DialDoor] = []
        /// The needs' first line (the subtitle sentence) and the open notes' dates, for the switcher's windows.
        var sentence = "Write the first thing down."
        var openDates: [Date] = []
        var widget: [WidgetItem] = []
        /// The rows of each door, newest first.
        var rows: [String: [ShellRow]] = [:]
        var now = Date.now
        var hasNotes: Bool {
            !rows.values.allSatisfy(\.isEmpty)
        }
    }

    let facts: Facts
    var accent: Color = LandingAccent.notes

    static let across = ["Newest", "Due", "Pinned", "From Tess"]
    static let vertical = ["Today", "This week", "Earlier"]

    func screen(for route: ShellRoute, state: RoomState) -> Screen {
        route.level == 0 ? landing(state) : door(route.door ?? "all")
    }

    // MARK: Level 0

    private func landing(_ state: RoomState) -> Screen {
        let item = facts.widget.indices.contains(state.widgetIndex) ? facts.widget[state.widgetIndex] : facts.widget
            .first
        let focused = facts.doors.isEmpty ? nil
            : facts.doors[((state.dialFocus % facts.doors.count) + facts.doors.count) % facts.doors.count]
        let window = Self.vertical.indices.contains(state.switcherVerticalIndex) ? state.switcherVerticalIndex : 0
        return Screen(layout: .landing, flip: .rows, slots: [
            .title: title,
            .navWord: SlotContent(id: "log.nav.bridge", kind: .text, payload: .navWord("Bridge")),
            .switcher: SlotContent(id: "log.switcher", kind: .switcher,
                                   payload: .switcher(across: Self.across, vertical: Self.vertical)),
            .needs: SlotContent(id: ContentID("log.needs.\(window)"), kind: .text, payload: .lines(needs(window))),
            .keystone: keystone,
            .caption: caption,
            .widget: facts.widget.isEmpty ? nil
                : SlotContent(id: "log.widget", kind: .widget, payload: .widget(facts.widget)),
            .glyph: item.map { SlotContent(
                id: ContentID("log.glyph.\($0.id)"),
                kind: .glyph,
                payload: .glyph($0, color: accent)
            ) },
            .dial: facts.doors.isEmpty ? nil : SlotContent(id: "log.dial", kind: .dial, payload: .dial(facts.doors)),
            .doorSummary: focused.flatMap { door in
                door.label == nil && door.lines.isEmpty ? nil
                    : SlotContent(id: ContentID("log.summary.\(door.id)"), kind: .summary, payload: .summary(door))
            },
            .actionWord: action,
            .tess: nil,
        ])
    }

    /// The needs change with the switcher's up-and-down window: the subtitle, then how many notes the window holds.
    private func needs(_ window: Int) -> [String] {
        guard facts.hasNotes else { return [facts.sentence] }
        let calendar = Calendar.current
        let count = facts.openDates.filter { date in
            switch window {
            case 0: calendar.isDate(date, inSameDayAs: facts.now)
            case 1: calendar.isDate(date, equalTo: facts.now, toGranularity: .weekOfYear)
            default: !calendar.isDate(date, equalTo: facts.now, toGranularity: .weekOfYear)
            }
        }.count
        let span = ["today", "this week", "before this week"][window]
        let noun = count == 1 ? "note" : "notes"
        return [facts.sentence, count == 0 ? "No notes \(span)." : "\(count) \(noun) \(span)."]
    }

    // MARK: Level 1

    private func door(_ id: String) -> Screen {
        let door = facts.doors.first { $0.id == id }
        let rows = facts.rows[id] ?? []
        let name = door?.name ?? "All notes"
        let line = rows.isEmpty ? "Nothing here yet." : "\(rows.count) \(rows.count == 1 ? "note" : "notes"), newest first."
        return Screen(layout: .door, flip: .rows, slots: [
            .title: title,
            .navWord: SlotContent(id: "log.nav.log", kind: .text, payload: .navWord("Log")),
            .doorTitle: SlotContent(id: ContentID("log.door.\(id).title"), kind: .text,
                                    payload: .doorTitle(
                                        name: name,
                                        line: line,
                                        color: door?.color ?? Theme.Colors.ink
                                    )),
            .keystone: keystone,
            .caption: caption,
            .page: SlotContent(id: ContentID("log.door.\(id).page"), kind: .list, payload: .list(rows)),
            .actionWord: action,
            .tess: nil,
        ])
    }

    // MARK: Shared by both levels (same ids: the keystone, title, caption and action are not touched)

    private var title: SlotContent {
        SlotContent(id: "log.title", kind: .text, payload: .title("Log", accent: accent))
    }

    private var keystone: SlotContent {
        SlotContent(id: "log.wall", kind: .wall, payload: .wall(facts.words, label: "Your notes"))
    }

    private var caption: SlotContent {
        SlotContent(id: "log.caption", kind: .text, payload: .lines(["Tap a word to open its note."]))
    }

    private var action: SlotContent {
        SlotContent(id: "log.action", kind: .action, payload: .action([
            ShellStep(id: "write", verb: "Write", object: "A note"),
            ShellStep(id: "speak", verb: "Speak", object: "To Tess"),
            ShellStep(id: "list", verb: "List", object: "A checklist"),
        ], accent: accent))
    }
}

extension NotesRoomContent.Facts {
    /// The Log's facts from the store, the same reads as `NotesLandingPage.load()`. Private notes are counted, never
    /// worded: a private row reads "Private note" and its time.
    @MainActor
    static func load(model: AppModel, scheme: ColorScheme) -> Self {
        let store = model.store
        let classes = model.classes
        let landing = NotesLanding(store: store, classes: classes)
        let notes = NoteList(store: store, classes: classes).recent(limit: 60)
        let open = notes.filter { !landing.isPrivate($0) }
        let hidden = notes.count - open.count
        let lists = NotesLandingFacts.load(store: store, classes: classes, lastSeen: nil, linkSuggest: false)
        let now = AppClock.now
        var facts = Self()
        facts.now = now
        facts.words = open.enumerated().map { index, note in
            WallWord(id: note.id.uuidString, text: NotesLandingPage.short(note.title),
                     weight: 1 - Double(index) / Double(max(open.count, 1)))
        }
        let slate = scheme == .dark ? Color(hex: 0xA7BCD6) : Color(hex: 0x34506F)
        var doors = [DialDoor(id: "all", name: "All notes", count: open.isEmpty ? nil : "\(open.count)",
                              color: Theme.Colors.ink,
                              label: open.first.map { "Newest \(NotesCopy.when($0.updatedAt, now: now))" },
                              lines: open.prefix(3).map { NotesLandingPage.short($0.title) })]
        if lists.hasLoose {
            doors.append(DialDoor(id: "loose", name: "Loose", color: LandingAccent.notes, label: "Not about a thing"))
        }
        if hidden > 0 || lists.hasPrivate {
            doors.append(DialDoor(id: "private", name: "Private", count: hidden > 0 ? "\(hidden)" : nil, color: slate,
                                  lines: ["\(max(hidden, 1)) private \(hidden == 1 ? "note" : "notes")"]))
        }
        facts.doors = doors
        let top = Array(lists.things.prefix(2).map(\.name))
        facts.sentence = notes.isEmpty ? "Write the first thing down."
            : NotesLandingWords.subtitle(hasNotes: lists.hasNotes, topThings: top).text
        facts.openDates = open.map(\.updatedAt)
        facts.widget = open.prefix(4).map { note in
            WidgetItem(id: note.id.uuidString, header: "Newest", big: NotesLandingPage.short(note.title).uppercased(),
                       middle: "Written \(NotesCopy.when(note.updatedAt, now: now))",
                       small: "Tap to open it", strikeable: false)
        }
        let all = NoteList(store: store, classes: classes).recent(limit: 200)
        func row(_ note: ObjectRecord) -> ShellRow {
            let when = NotesCopy.when(note.updatedAt, now: now)
            return landing.isPrivate(note)
                ? ShellRow(id: note.id.uuidString, title: "Private note", detail: when, isPrivate: true)
                : ShellRow(
                    id: note.id.uuidString,
                    title: note.title.replacingOccurrences(of: "@", with: ""),
                    detail: when
                )
        }
        facts.rows["all"] = all.map(row)
        facts.rows["private"] = all.filter { landing.isPrivate($0) }.map(row)
        facts.rows["loose"] = all.filter { note in
            !landing.isPrivate(note) && (note.outgoingLinks ?? [])
                .allSatisfy { $0.toObject == nil && $0.toClass == nil }
        }.map(row)
        return facts
    }
}

/// The Log as a room the standing shell holds (sheet 283 v5): its content, its intents and what it presents (the
/// note editor, the New note ask). Taps come back as intents: a door pushes its route, a word or row opens its
/// note, the action word writes, and back pops (restoring every place).
@MainActor
@Observable
final class NotesRoomDriver: ShellRoomDriver {
    let room = NotesRoomContent.room
    var accent: Color {
        LandingAccent.notes
    }

    let tessRoom: AppID? = .notes
    let flip = KeystoneFlip.rows

    struct OpenNote: Identifiable {
        let id: UUID
    }

    var opened: OpenNote?
    var writing = false
    var draft = ""
    @ObservationIgnored weak var model: AppModel?

    func content(model: AppModel, scheme: ColorScheme) -> any RoomContent {
        self.model = model
        return NotesRoomContent(facts: .load(model: model, scheme: scheme))
    }

    func handle(_ intent: ShellIntent, navigator: ShellNavigator) -> Bool {
        switch intent {
        case .back:
            return false
        case let .openDoor(id):
            navigator.push(.door(room, id))
        case let .openItem(id):
            if let uuid = UUID(uuidString: id) {
                opened = OpenNote(id: uuid)
            }
        case let .action(id):
            if id == "speak" {
                TessVoice.shared.say("Say \"note: ...\" and I'll keep it.")
            } else {
                draft = ""
                writing = true
            }
        }
        return true
    }

    func presenter() -> AnyView {
        AnyView(NotesRoomPresenter(driver: self))
    }

    func write(reduceMotion: Bool) {
        guard let model else { return }
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

/// The Log's presentations: the note editor and the New note ask.
private struct NotesRoomPresenter: View {
    @Bindable var driver: NotesRoomDriver
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .sheet(item: $driver.opened) { note in
                NavigationStack { NoteEditor(noteID: note.id) }
            }
            .alert("New note", isPresented: $driver.writing) {
                TextField("", text: $driver.draft)
                Button("Keep") { driver.write(reduceMotion: reduceMotion) }
                Button("Cancel", role: .cancel) {}
            }
    }
}

/// The Log alone in the standing shell (`-shell` on the simulator, and the registry's Log entry).
struct NotesShellHost: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme
    @State private var navigator = ShellNavigator(root: .landing(NotesRoomContent.room))
    @State private var driver = NotesRoomDriver()

    var body: some View {
        let _ = model.revision
        ShellView(room: AnyRoomContent(base: driver.content(model: model, scheme: scheme)), navigator: navigator,
                  accent: driver.accent, act: handle)
            .background { driver.presenter() }
        #if DEBUG
            .task {
                NotesDemo.seedIfRequested(model)
                await ShellStills.walk(navigator, room: NotesRoomContent.room)
            }
        #endif
    }

    private func handle(_ intent: ShellIntent) {
        if !driver.handle(intent, navigator: navigator), intent == .back {
            navigator.pop()
        }
    }
}

#if DEBUG
    /// `-shellDoor all` (simulator only, LaunchFlags): opens that door 2 s after launch and, with `-shellBack`,
    /// comes back 3 s later, so stills and recordings can catch the merge and the split.
    @MainActor
    enum ShellStills {
        static func walk(_ navigator: ShellNavigator, room: String) async {
            guard let door = LaunchFlags.value(after: "-shellDoor") else { return }
            try? await Task.sleep(for: .seconds(2))
            navigator.push(.door(room, door))
            guard LaunchFlags.has("-shellBack") else { return }
            try? await Task.sleep(for: .seconds(3))
            navigator.pop()
        }

        /// `-shellWalk log` (simulator only): from Bridge into that room 3 s after launch, its All notes door 2.5 s
        /// later, back up, and back to Bridge, 2.5 s apart; for recordings of every move.
        static func walkRoot(_ navigator: ShellNavigator) async {
            guard let room = LaunchFlags.value(after: "-shellWalk") else { return }
            try? await Task.sleep(for: .seconds(3))
            navigator.push(.landing(room))
            if let door = LaunchFlags.value(after: "-shellDoor") {
                try? await Task.sleep(for: .seconds(2.5))
                navigator.push(.door(room, door))
                try? await Task.sleep(for: .seconds(2.5))
                navigator.pop()
            }
            guard LaunchFlags.has("-shellBack") else { return }
            try? await Task.sleep(for: .seconds(2.5))
            navigator.pop()
        }
    }
#endif
