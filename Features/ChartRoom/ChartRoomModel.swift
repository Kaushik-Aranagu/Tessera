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

/// Tess's line when a rule says no, with at most one button: her offer.
struct RoomNote: Equatable {
    var line: String
    var button: String?
    var patch: RoomPatch?
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
    /// The place he pointed at (sheet 360): a tap on a filled place picks it for 30 s. Writes nothing.
    private(set) var picked: Place?
    /// Sheet 362: the room's history, open, and the version he is previewing (nothing is written by looking).
    private(set) var historyOpen = false
    private(set) var previewing: HistoryRow?
    private(set) var historyRows: [HistoryRow] = []
    @ObservationIgnored var now: () -> Date = { AppClock.now }
    @ObservationIgnored private var memory: [HistoryRow] = []
    /// Tess's line with one receipt button (sheet 361): a refusal and her offer, run as a normal ghost change.
    private(set) var note: RoomNote?
    @ObservationIgnored private(set) var data: RoomData
    @ObservationIgnored private var pickTask: Task<Void, Never>?
    @ObservationIgnored var pickFor: Duration = .seconds(30)
    @ObservationIgnored private let defaults: UserDefaults?
    @ObservationIgnored private let drying: Duration
    @ObservationIgnored private var dryTask: Task<Void, Never>?
    @ObservationIgnored private var say: (String, @escaping () -> Void) -> Void
    @ObservationIgnored private(set) var engine: ActionEngine?
    @ObservationIgnored private var record: OpRecord?

    /// The room's own name and the blank document every room starts from.
    static let blank = ChartDoc(name: "Chart room")

    init(data: RoomData = DemoRoomData(), defaults: UserDefaults? = nil, drying: Duration = .seconds(PartGhost.drying),
         say: ((String, @escaping () -> Void) -> Void)? = nil)
    {
        self.data = data
        self.defaults = defaults
        self.drying = drying
        self.say = say ?? { _, _ in }
        if let defaults, let json = defaults.string(forKey: Self.defaultsKey),
           let saved = try? ChartDoc.decode(json)
        {
            document = saved
            cursor = defaults.integer(forKey: Self.cursorKey)
        } else {
            document = Self.blank
            cursor = 0
        }
        if say == nil {
            self.say = { [weak self] text, undo in self?.showReceipt(text, undo: undo) }
        }
    }

    // MARK: The receipt (sheet 382: the shared UndoLine draws it)

    struct Receipt: Identifiable {
        let id = UUID()
        let text: String
        let undo: () -> Void
    }

    private(set) var receipt: Receipt?

    /// Tess's receipt line with Undo for 10 s. Drawn by the shared `UndoLine`, never by the room.
    func showReceipt(_ text: String, undo: @escaping () -> Void) {
        let next = Receipt(text: text, undo: undo)
        receipt = next
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            if self?.receipt?.id == next.id {
                self?.receipt = nil
            }
        }
    }

    /// Undo was tapped: the change is taken back at once and the line goes.
    func undoReceipt() {
        guard let current = receipt else { return }
        receipt = nil
        current.undo()
    }

    /// Attaches Core's engine: the room is read from, and written to, its objects from here on.
    func attach(_ engine: ActionEngine) {
        guard self.engine == nil else { return }
        self.engine = engine
        // The real store: Core's sample Plant class (until he says production-ready) and the binds read through it.
        _ = try? RoomSample.seedPlants(store: engine.store, classes: engine.classes, now: AppClock.now)
        data = EngineRoomData(engine: engine)
        // Another room's colour is never taken: the whole dial's table, from the rooms' own colours.
        RoomColor.otherRooms = Dictionary(uniqueKeysWithValues: LayoutRoom.allCases.compactMap { room in
            room.hex.map { (room.name, RoomColor.Pair($0.light, $0.dark)) }
        })
        // `-resetChart` (simulator only) starts a blank room: a room already in the store is taken down, not deleted.
        if LaunchFlags.has("-resetChart"), let room = RoomBook(store: engine.store, classes: engine.classes)
            .room(named: document.name)
        {
            _ = try? engine.perform(TakeDownRoom(room: room.id), by: .user)
        }
        if let stored = storedDocument() {
            document = stored
            // The sentences already in the room are the first ones he said: the next is the one after them.
            cursor = Self.canned.prefix { step in
                step.patch.ops.filter { $0.op == "add" }.allSatisfy { stored.part($0.id ?? "") != nil }
            }.count
        }
    }

    // MARK: Taking a room down (sheet 371)

    /// True while the fold plays (the room's outlines fold into their corners before the room is gone).
    private(set) var takingDown = false

    /// Take the room down: it is archived in ONE op group and nothing it binds to is touched (the plants stay). The
    /// receipt "Room taken down, not the plants" has a 10 s Undo that brings the room back. A room waiting for his
    /// Allow
    /// stays up, and Core's line is the refusal.
    func takeDown() {
        guard pending == nil, !takingDown else { return }
        let was = document
        guard let engine else {
            document = Self.blank
            persist()
            say("Room taken down, not the plants") { [weak self] in
                self?.document = was
                self?.persist()
            }
            return
        }
        let book = RoomBook(store: engine.store, classes: engine.classes)
        guard let room = book.room(named: document.name) else {
            document = Self.blank
            return
        }
        do {
            let record = try engine.perform(TakeDownRoom(room: room.id), by: .user).record
            document = Self.blank
            say("Room taken down, not the plants") { [weak self] in
                // Bring back: the room, its history and its grants, from the room Core finds taken down.
                if let down = RoomBook(store: engine.store, classes: engine.classes).takenDownRoom(named: was.name) {
                    _ = try? engine.perform(BringBackRoom(room: down.id), by: .user)
                } else {
                    engine.undo(record)
                }
                self?.document = self?.storedDocument() ?? was
            }
        } catch let ActionError.invalidArguments(_, reason) {
            refuse(reason)
        } catch {
            refuse("That room could not be taken down")
        }
    }

    private func storedDocument() -> ChartDoc? {
        guard let engine else { return nil }
        let book = RoomBook(store: engine.store, classes: engine.classes)
        return book.room(named: "Chart room").map { ChartDoc(book.document(of: $0)) }
    }

    /// The document as it should draw now: the pending patch applied (as a ghost) over the committed room.
    var shown: ChartDoc {
        if let previewing {
            return previewing.doc ?? document
        }
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
        // A preview of the room as it was: every filled place is a ghost, and nothing is written.
        if previewing != nil {
            return Set(nodes.keys)
        }
        guard let pending else { return [] }
        let now = PartResolver.resolve(pending.before) { [data] in data.items($0) }
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
            // Core's house rules and validator speak for the store: a refusal is Tess's line (sheet 361), never a
            // ghost.
            do {
                switch try RoomPatcher.apply(core, sentence: said, picked: picked?.rawValue, engine: engine) {
                case let .applied(applied, _):
                    record = applied
                    after = storedDocument() ?? after
                case let .refused(refusal, queued):
                    var offer: (label: String, patch: RoomPatch)?
                    if let label = refusal.offerLabel, let patch = refusal.offer {
                        offer = (label, patch)
                    }
                    refuse(refusal.line, offer: offer)
                    if let queued {
                        say(refusal.receipt) { [weak engine] in engine?.undo(queued) }
                    }
                    return
                }
            } catch {
                refuse("That did not change the room")
                return
            }
        }
        picked = nil
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

    /// Sheet 373: while a change is drying, touching his own words or saying "wait" or "stop" calls this. Nothing is
    /// written: the staged group is thrown away (`RoomPatcher.stop`), the ghost lets go, and Tess says "Stopped,
    /// nothing changed" with no Undo, and the same sentence is offered again. Past the 2 s the change has set and can
    /// only be undone, so then the normal Undo receipt stands. Returns whether anything was stopped.
    @discardableResult
    func cancelPending() -> Bool {
        guard let current = pending, !unDrying, !current.dried || current.needsAllow else { return false }
        if let engine, let record {
            guard RoomPatcher.stop([record], in: engine) else { return false }
        }
        dryTask?.cancel()
        let again = current.patch.heard
        record = nil
        pending = nil
        heard = ""
        cue.play(.selection)
        retry = again.isEmpty ? nil : again
        say("Stopped, nothing changed") {}
        return true
    }

    /// The sentence the action word offers again after a stop.
    private(set) var retry: String?

    /// A tap on the ghost sets it now (a patch that widens reach never sets this way).
    func tapGhost() {
        guard let pending, !pending.needsAllow, !unDrying else { return }
        commit()
    }

    /// Allow: the widening patch sets, and its grant with it (`RoomReach.allow` when the engine holds it). Undo takes
    /// both back in one step.
    func allow() {
        guard let pending, pending.needsAllow, !unDrying else { return }
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
        remember(patch, after: current.after)
        say(patch.say) { [weak self] in self?.restore(before, cursor: cursorBefore, record: kept, patch: patch) }
    }

    /// Undo: the document before the patch (and so its grant, which lives in the same document), as it was.
    func restore(_ before: ChartDoc, cursor: Int, record: OpRecord? = nil, patch: ChartPatch? = nil) {
        guard !unDrying else { return }
        func finish() {
            if let engine, let record {
                engine.undo(record)
            }
            document = before
            self.cursor = cursor
            pending = nil
            unDrying = false
            cue.play(.undo)
            persist()
        }
        guard let patch, pending == nil else {
            finish()
            return
        }
        // Sheet 368: Undo un-dries. The change goes back to a ghost, its drying line runs right to left in 600 ms
        // (ease in), and the op group is marked undone only when the line reaches 0.
        dryTask?.cancel()
        pending = PendingPatch(patch: patch, before: before, after: document, dried: true)
        unDrying = true
        dryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.unDrySeconds))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    /// How long Undo's drying line takes to run back to 0.
    static let unDrySeconds = 0.6

    /// An undo is running its drying line backwards; nothing else may change the room meanwhile.
    private(set) var unDrying = false

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

    // MARK: History (sheet 362)

    /// One sentence he said to the room, with when, and the room as it stood right after it.
    struct HistoryRow: Identifiable, Equatable {
        let id: UUID
        let note: String
        let at: Date
        var doc: ChartDoc?
        var entry: RoomHistory.Entry?

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }

    /// "1:18 pm".
    static func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func remember(_ patch: ChartPatch, after doc: ChartDoc) {
        memory.append(HistoryRow(id: UUID(), note: patch.heard.isEmpty ? patch.say : patch.heard, at: now(), doc: doc))
    }

    /// Every sentence he said, newest first: Core's op log filtered to the room's patch groups when the store is
    /// attached; else the sentences of this run.
    func openHistory() {
        guard pending == nil else { return }
        if let engine {
            historyRows = RoomHistory.entries(of: document.name, engine: engine).map {
                HistoryRow(id: $0.record, note: $0.note, at: $0.at, doc: nil, entry: $0)
            }
        } else {
            historyRows = memory.reversed()
        }
        previewing = nil
        historyOpen = true
    }

    func closeHistory() {
        historyOpen = false
        previewing = nil
    }

    /// A tap on a row: the room as it was then, every place a ghost. Writes nothing.
    func preview(_ row: HistoryRow) {
        var shown = row
        if let engine, let entry = row.entry,
           let version = try? RoomHistory.version(of: document.name, after: entry, engine: engine)
        {
            shown.doc = ChartDoc(version)
        }
        previewing = shown
    }

    /// What the action word reads while previewing: "Go back to how it was at 1:18 pm".
    var goBackObject: String? {
        previewing.map { "to how it was at \(Self.clock($0.at))" }
    }

    /// Go back: ONE inverse op group through the same write a Tess patch uses, receipt "Back to 1:18 pm" with a 10 s
    /// Undo that returns to the latest version.
    func goBack() {
        guard let row = previewing else { return }
        let label = "Back to \(Self.clock(row.at))"
        let latest = document
        if let engine, let entry = row.entry,
           let record = try? RoomHistory.goBack(room: document.name, to: entry, label: label, engine: engine)
        {
            document = storedDocument() ?? document
            say(label) { [weak self] in
                engine.undo(record)
                self?.document = self?.storedDocument() ?? latest
            }
        } else if let doc = row.doc {
            document = doc
            memory.append(HistoryRow(id: UUID(), note: label, at: now(), doc: doc))
            say(label) { [weak self] in self?.document = latest }
            persist()
        }
        closeHistory()
    }

    // MARK: Point, then say (sheet 360)

    /// What the pointed-at place is called in the foot's small line.
    static func name(of place: Place) -> String {
        switch place {
        case .switcher: "line"
        case .needs: "needs"
        default: place.rawValue
        }
    }

    /// A tap on a filled place picks it (a tap on the picked one lets it go). One light tick; nothing is written.
    func pick(_ place: Place) {
        guard nodes[place] != nil, pending == nil else { return }
        pickTask?.cancel()
        if picked == place {
            picked = nil
            return
        }
        picked = place
        cue.play(.selection)
        pickTask = Task { [weak self, pickFor] in
            try? await Task.sleep(for: pickFor)
            guard !Task.isCancelled else { return }
            self?.picked = nil
        }
    }

    /// What the Say word's small line reads: "what to change about the keystone", or "what to build".
    var sayObject: String {
        picked.map { "what to change about the \(Self.name(of: $0))" } ?? DocumentRoom.sayObject
    }

    // MARK: How the room says no (sheet 361)

    /// A rule refusal: Tess's one line, and her offer as a receipt button that runs it as a normal ghost change.
    func refuse(_ reason: String, offer: (label: String, patch: RoomPatch)? = nil) {
        note = RoomNote(line: PartText.shown(reason), button: offer?.label, patch: offer?.patch)
    }

    /// The offer was taken: it plays as a ghost change like any other.
    func takeOffer() {
        guard let patch = note?.patch else { return }
        note = nil
        propose(patch)
    }

    func dismissNote() {
        note = nil
    }

    /// A kit miss (a part the kit does not have): queued for the next install, with Undo to take the request back.
    func kitMiss(_ part: String) {
        queued.append(part)
        say("\(part), queued for your next install") { [weak self] in self?.queued.removeAll { $0 == part } }
    }

    /// Parts asked for that the kit lacks, waiting for the next install.
    private(set) var queued: [String] = []

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
