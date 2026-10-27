import Foundation
import SwiftUI
import TesseraCore

/// What the room's binds read and what its one action word may write (spec: binds are `ObjectPath` queries resolved at
/// render time, the document never holds a copy of his data). The live store has no `Plant` class, so the room reads
/// the board's plants until a bind resolver for user classes lands in Core.
@MainActor
protocol RoomData: AnyObject {
    func items(_ bind: String) -> [BoundItem]
    /// Runs the single field write an action word does on the named item, returning what takes it back.
    func write(_ does: String, to item: String) -> (() -> Void)?
}

/// The board's four plants: days since water 6, 4, 2 and 1, watered every 7, 5, 3 and 2 days. In memory only.
@MainActor
final class DemoRoomData: RoomData {
    private var plants: [BoundItem] = [("Orchid", 6, 7), ("Monstera", 4, 5), ("Fern", 2, 3), ("Basil", 1, 2)].map {
        BoundItem(name: $0.0, fields: ["daysSince(lastWatered)": Double($0.1), "waterEvery": Double($0.2)])
    }

    func items(_ bind: String) -> [BoundItem] {
        RoomWalls.className(of: bind) == "Plant" ? plants : []
    }

    func write(_ does: String, to item: String) -> (() -> Void)? {
        let key = "daysSince(lastWatered)"
        guard does == "write Plant.lastWatered", let index = plants.firstIndex(where: { $0.name == item }) else {
            return nil
        }
        let was = plants[index].fields[key] ?? 0
        plants[index].fields[key] = 0
        return { [weak self] in
            if let at = self?.plants.firstIndex(where: { $0.name == item }) {
                self?.plants[at].fields[key] = was
            }
        }
    }
}

/// A patch shown before it is set.
struct PendingPatch: Equatable, Identifiable {
    let id = UUID()
    var patch: ChartPatch
    var before: ChartDoc
    var after: ChartDoc
    /// The drying line has run its 2 s.
    var dried = false

    /// A patch that widens reach waits on Allow; the others set when the line ends or on a tap.
    var needsAllow: Bool {
        patch.widensReach
    }
}

/// The Chart room's state: the committed document, at most one pending patch (the ghost), and what Undo takes back.
/// With an engine attached the room is Core's objects: a patch is `PatchRoom` performed as Tess, pending; it commits
/// with `engine.commit` (or `RoomReach.allow` when it widens reach); Undo is `engine.undo`. Without one (tests, and the
/// canned demo before a store has the classes) the same flow runs on the document in memory.
@MainActor
@Observable
final class ChartRoomModel {
    static let defaultsKey = "chartRoom.document"
    static let cursorKey = "chartRoom.cursor"

    private(set) var document: ChartDoc
    private(set) var pending: PendingPatch?
    /// What he said, in the widget place in quotes, while Tess works.
    private(set) var heard = ""
    /// One light tick as a ghost sets.
    private(set) var cue = HapticCue()
    /// How many of the canned sentences have set (the next one is `canned[cursor]`).
    private(set) var cursor: Int
    @ObservationIgnored let data: RoomData
    @ObservationIgnored private let defaults: UserDefaults?
    @ObservationIgnored private let drying: Duration
    @ObservationIgnored private var dryTask: Task<Void, Never>?
    @ObservationIgnored private let say: (String, @escaping () -> Void) -> Void
    @ObservationIgnored private(set) var engine: ActionEngine?
    @ObservationIgnored private var record: OpRecord?

    /// The room's own name and the blank document every room starts from.
    static let blank = ChartDoc(name: "Chart room")

    init(data: RoomData = DemoRoomData(), defaults: UserDefaults? = nil, drying: Duration = .seconds(PartGhost.drying),
         say: @escaping (String, @escaping () -> Void) -> Void = { text, undo in
             TessVoice.shared.say(text, holds: .seconds(10), takeBack: undo)
         })
    {
        self.data = data
        self.defaults = defaults
        self.drying = drying
        self.say = say
        if let defaults, let json = defaults.string(forKey: Self.defaultsKey),
           let saved = try? ChartDoc.decode(json)
        {
            document = saved
            cursor = defaults.integer(forKey: Self.cursorKey)
        } else {
            document = Self.blank
            cursor = 0
        }
    }

    /// Attaches Core's engine: the room is read from, and written to, its objects from here on.
    func attach(_ engine: ActionEngine) {
        guard self.engine == nil else { return }
        self.engine = engine
        if let stored = storedDocument() {
            document = stored
        }
    }

    private func storedDocument() -> ChartDoc? {
        guard let engine else { return nil }
        let book = RoomBook(store: engine.store, classes: engine.classes)
        return book.room(named: "Chart room").map { ChartDoc(book.document(of: $0)) }
    }

    /// The document as it should draw now: the pending patch applied (as a ghost) over the committed room.
    var shown: ChartDoc {
        guard let pending else { return document }
        // A patch that widens reach does not hold its grant until Allow, so what needs the grant stays away.
        var after = pending.after
        if pending.needsAllow {
            after.reach = pending.before.reach
        }
        return after
    }

    /// The nodes of every place, resolved against what the binds read now.
    var nodes: [Place: [PartNode]] {
        PartResolver.resolve(shown) { [data] in data.items($0) }
    }

    /// The places a ghost fills, whose outline lets go and whose drying line runs.
    var ghostPlaces: Set<Place> {
        guard let pending else { return [] }
        let now = PartResolver.resolve(document) { [data] in data.items($0) }
        let next = nodes
        var places = Set(Place.allCases.filter { now[$0] != next[$0] })
        // The reach line sits in the Widget's place, so the Widget's outline lets go for it.
        if pending.needsAllow {
            places.insert(.widget)
        }
        return places
    }

    var isBlank: Bool {
        document.parts.isEmpty && pending == nil
    }

    /// The reach line a widening patch shows in wine, with Allow.
    var reachLine: String? {
        guard let pending, pending.needsAllow, let grant = pending.patch.grantLine else { return nil }
        return "This room can now " + Self.words(for: grant)
    }

    /// "write Plant.lastWatered" in words. Unknown writes read as the field they change.
    static func words(for grant: String) -> String {
        let table = ["write Plant.lastWatered": "mark plants watered"]
        return table[grant] ?? RoomDocument.words(for: grant)
    }

    // MARK: Proposing

    /// Tess proposes a patch: it shows as a ghost, dries for 2 s, then sets (or waits on Allow when it widens reach).
    func propose(_ core: RoomPatch, heard said: String = "") {
        guard pending == nil else { return }
        let patch = ChartPatch(core, heard: said)
        // Money can never be written by a room: such a grant is refused, nothing shows.
        if patch.ops
            .contains(where: {
                if case let .grant(reach) = $0 {
                    RoomWalls.refusesWrite(reach)
                } else {
                    false
                }
            })
        {
            say("Rooms can't change money") {}
            return
        }
        let before = document
        var after = document.applying(patch)
        record = nil
        if let engine {
            // The engine's validator speaks for the store: a refusal (a class it has not got) shows the demo ghost.
            if let result = try? engine.perform(PatchRoom(patch: core), by: .tess, pending: true) {
                record = result.record
                after = storedDocument() ?? after
            }
        }
        heard = said
        let next = PendingPatch(patch: patch, before: before, after: after)
        pending = next
        dryTask?.cancel()
        let id = next.id
        dryTask = Task { [weak self, drying] in
            try? await Task.sleep(for: drying)
            guard !Task.isCancelled else { return }
            self?.dried(id)
        }
    }

    private func dried(_ id: UUID) {
        guard var current = pending, current.id == id else { return }
        current.dried = true
        pending = current
        if current.needsAllow {
            heard = ""
        } else {
            commit()
        }
    }

    /// A tap on the ghost sets it now (a patch that widens reach never sets this way).
    func tapGhost() {
        guard let pending, !pending.needsAllow else { return }
        commit()
    }

    /// Allow: the widening patch sets, and its grant with it (`RoomReach.allow` when the engine holds it). Undo takes
    /// both back in one step.
    func allow() {
        guard let pending, pending.needsAllow else { return }
        if let engine, let record {
            guard RoomReach.allow(record, in: engine) else { return }
        }
        commit(allowed: true)
    }

    /// Dismissing a pending patch marks it undone: the room is as it was.
    func dismiss() {
        dryTask?.cancel()
        if let engine, let record {
            _ = try? engine.discard(record)
        }
        record = nil
        pending = nil
        heard = ""
    }

    private func commit(allowed: Bool = false) {
        guard let current = pending else { return }
        dryTask?.cancel()
        let before = current.before
        let patch = current.patch
        let cursorBefore = cursor
        let kept = record
        if let engine, let kept, !allowed {
            try? engine.commit(kept)
        }
        document = current.after
        pending = nil
        record = nil
        heard = ""
        cursor = min(Self.canned.count, cursor + 1)
        cue.play(.selection)
        persist()
        say(patch.say) { [weak self] in self?.restore(before, cursor: cursorBefore, record: kept) }
    }

    /// Undo: the document before the patch (and so its grant, which lives in the same document), as it was.
    func restore(_ before: ChartDoc, cursor: Int, record: OpRecord? = nil) {
        if let engine, let record {
            engine.undo(record)
        }
        document = before
        self.cursor = cursor
        cue.play(.undo)
        persist()
    }

    // MARK: Saying (canned sentences until Core's `patchRoom` job lands)

    /// The next of the board's four sentences.
    var nextCanned: (heard: String, patch: RoomPatch)? {
        Self.canned.indices.contains(cursor) ? Self.canned[cursor] : nil
    }

    /// The Say word: plays the next canned sentence.
    func saySomething() {
        guard pending == nil, let next = nextCanned else { return }
        propose(next.patch, heard: next.heard)
    }

    /// The action word the room built: its single field write, on the top item.
    func does(_ partID: String) {
        guard let node = nodes[.actionWord]?.first(where: { $0.id == partID }),
              case let .actionWord(_, _, _, does?) = node,
              let bind = shown.part(partID)?.bind ?? PartResolver.bind(of: does),
              let top = PartResolver.topItem(in: shown, bind: bind, data: { [data] in data.items($0) }),
              let undo = data.write(does, to: top.name)
        else { return }
        say("\(top.name), watered") { undo() }
    }

    /// Simulator stills: the room as it is after the first `count` canned sentences, with every grant allowed.
    func setSentences(_ count: Int) {
        var doc = Self.blank
        for step in Self.canned.prefix(count) {
            doc = doc.applying(ChartPatch(step.patch))
        }
        document = doc
        cursor = min(count, Self.canned.count)
    }

    func load(_ doc: ChartDoc) {
        document = doc
        cursor = Self.canned.count
    }

    func reset() {
        dryTask?.cancel()
        pending = nil
        heard = ""
        document = Self.blank
        cursor = 0
        persist()
    }

    private func persist() {
        defaults?.set(document.encoded(), forKey: Self.defaultsKey)
        defaults?.set(cursor, forKey: Self.cursorKey)
    }
}

extension PartResolver {
    /// The class an action's write names: "write Plant.lastWatered" is "Plant".
    static func bind(of does: String) -> String? {
        let words = does.split(separator: " ")
        guard words.count > 1 else { return nil }
        return String(words[1].split(separator: ".").first ?? "")
    }

    /// The item an action word or `{top}` names: the highest of the `top` modifier's field in its bind, else the first.
    static func topItem(in doc: ChartDoc, bind: String, data: (String) -> [BoundItem]) -> BoundItem? {
        guard !RoomWalls.isWalled(bind) else { return nil }
        let all = data(bind)
        guard let field = doc.parts.first(where: { $0.kind == .top })?.props.text("field") else { return all.first }
        return all.max { value($0, field) < value($1, field) }
    }
}
