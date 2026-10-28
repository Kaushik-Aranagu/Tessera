import Foundation
@testable import TesseraCore
import Testing

/// Chart room R1, step 2: the store-side bind resolver, the way the room says no (offers and the install queue), the
/// ΔE76 color rule, point-then-say, and the room's history.
@MainActor
struct RoomStep2Tests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let calendar: Calendar
    let now = Date(timeIntervalSince1970: 1_792_670_400)

    init() throws {
        classes = try store.prepareCatalog()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        calendar = utc
        engine = ActionEngine(store: store, classes: classes)
        engine.now = { Date(timeIntervalSince1970: 1_792_670_400) }
        try RoomSample.seedPlants(store: store, classes: classes, now: now, calendar: calendar)
    }

    var book: RoomBook {
        RoomBook(store: store, classes: classes)
    }

    func resolver() -> RoomBind {
        var bind = RoomBind(store: store, classes: classes)
        bind.now = { now }
        bind.calendar = calendar
        return bind
    }

    func add(_ id: String, _ kind: String, _ place: String, _ props: [String: RawJSON] = [:], bind: String? = nil)
        -> RoomPatch.Step
    {
        RoomPatch.Step(op: "add", id: id, kind: kind, place: place, props: props, bind: bind)
    }

    func patch(_ steps: RoomPatch.Step...) -> RoomPatch {
        RoomPatch(room: "Chart room", say: "Done", ops: steps)
    }

    // MARK: The resolver

    @Test func aBindOnAUserClassResolvesRanksAndFillsItsTokens() throws {
        let bind = resolver()
        let row = try #require(RoomFixture.chart.part("row"))
        let rows = bind.rows(for: row)
        #expect(rows.map(\.title) == ["Orchid", "Monstera", "Fern", "Basil"])
        #expect(rows.first?.number("waterEvery") == 7)
        let line = try #require(RoomFixture.chart.part("line"))
        #expect(bind
            .fill(line.text("text") ?? "", for: line, in: RoomFixture.chart) == "4 plants, the Orchid is thirsty")
        let days = try #require(RoomFixture.chart.part("days"))
        #expect(bind.number(for: days) == 4)
        let soon = try #require(RoomFixture.chart.part("soon"))
        #expect(bind.number(for: soon) == 7)
        // Watering the orchid re-ranks the room by itself: nothing in the room holds a copy.
        let orchid = try #require(rows.first.flatMap { store.object(id: $0.id) })
        try store.set("lastWatered", to: .date(now), on: orchid)
        #expect(bind.rows(for: row).map(\.title) == ["Monstera", "Fern", "Basil", "Orchid"])
        #expect(bind.fill("the {top}", for: line, in: RoomFixture.chart) == "the Monstera")
    }

    @Test func allowRunsAgainstARealEngineWithAPlantClass() throws {
        let steps = RoomFixture.chart.parts.map {
            RoomPatch.Step(op: "add", id: $0.id, kind: $0.kind, place: $0.place, props: $0.props, bind: $0.bind)
        }
        let result = try engine.perform(PatchRoom(patch: RoomPatch(room: "Chart room", say: "Plants, set", ops: steps),
                                                  sentence: "Make this my plant room"), by: .tess, pending: true)
        #expect(result.output.widening == ["write Plant.lastWatered"])
        engine.commitExpired(now: .now.addingTimeInterval(60))
        #expect(result.record.state == .pending)
        #expect(RoomReach.allow(result.record, in: engine) && result.record.state == .committed)
        #expect(RoomHistory.entries(of: "Chart room", engine: engine).map(\.note) == ["Make this my plant room"])
    }

    // MARK: Saying no

    @Test func aBoxIsRefusedWithTheNearestAllowedChangeAndTheOfferRuns() throws {
        let outcome = try RoomPatcher.apply(patch(add("box", "box", "widget")), sentence: "Put a box around each plant",
                                            engine: engine)
        guard case let .refused(refusal, queued) = outcome else {
            Issue.record("a box is refused")
            return
        }
        #expect(queued == nil && book.room(named: "Chart room") == nil, "nothing changed and no ghost")
        #expect(refusal.line == "No boxes in this house. Bigger numbers instead?")
        #expect(refusal.receipt == "Boxes, not here" && refusal.offerLabel == "Bigger numbers")
        let offer = try #require(refusal.offer)
        guard case let .applied(record, _) = try RoomPatcher.apply(offer, sentence: "Bigger numbers", engine: engine)
        else {
            Issue.record("the offer is an ordinary change")
            return
        }
        #expect(record.state == .pending)
        let room = try #require(book.room(named: "Chart room"))
        #expect(book.document(of: room).look["size"] == "bigger")
    }

    @Test func aPartTheKitLacksIsQueuedAndUndoTakesItOff() throws {
        let outcome = try RoomPatcher.apply(patch(add("pots", "ring", "keystone")),
                                            sentence: "Make the keystone a ring of pots I can spin", engine: engine)
        guard case let .refused(refusal, queued) = outcome, let record = queued else {
            Issue.record("a ring is queued")
            return
        }
        #expect(refusal.queue == "ring" && refusal.receipt == "Ring, queued for your next install")
        #expect(refusal.line.hasPrefix("A ring is a new kind of part. I'm building it on the Mac"))
        let room = try #require(book.room(named: "Chart room"))
        #expect(book.queue(of: room) == ["ring"])
        engine.undo(record)
        // The room was made by the queue itself, so Undo takes it all off.
        #expect(book.room(named: "Chart room") == nil)
    }

    @Test func aColorTooNearAnotherRoomOffersTheNearestAllowedOne() throws {
        // Teal is the Purse's (ΔE 0 here); olive is clear of every room in both themes.
        let outcome = try RoomPatcher.apply(patch(.init(op: "look", trait: "color", value: "teal")),
                                            sentence: "Make it teal", engine: engine)
        guard case let .refused(refusal, _) = outcome else {
            Issue.record("teal is refused")
            return
        }
        #expect(refusal.line == "Teal is the Purse's. Olive, like the leaves?")
        #expect(refusal.offerLabel == "Olive" && refusal.offer?.ops.first?.value == "olive")
        for other in RoomColor.otherRooms.values {
            #expect(try RoomColor.distance(#require(RoomColor.roles["olive"]), other) >= RoomColor.minimumDistance)
        }
        #expect(RoomColor.deltaE(0x2A7878, 0x2A7878) == 0 && RoomColor.deltaE(0xFFFFFF, 0x000000) > 99)
    }

    @Test func tessColorsAreNeverARoomsAndOnlySlateAndOliveAreFreeToTakeAsARoomColor() throws {
        #expect(!RoomKit.colorRoles.contains("ember") && !RoomKit.colorRoles.contains("cobalt"))
        let outcome = try RoomPatcher.apply(patch(.init(op: "look", trait: "color", value: "ember")),
                                            sentence: "Make it ember", engine: engine)
        guard case let .refused(refusal, _) = outcome else {
            Issue.record("ember is Tess's")
            return
        }
        #expect(refusal.line == "That's Tess's color. Slate instead?" && refusal.offer?.ops.first?.value == "slate")
        let free = RoomKit.colorRoles.filter { RoomColor.isFree($0) }
        #expect(Set(free) == ["slate", "olive"])
        // The others still colour a part.
        let part = patch(add("g", "glyph", "glyph", ["symbol": .string("leaf"), "color": .string("sage")]))
        guard case .ok = RoomPatchValidator(store: store, classes: classes)
            .validate(part, against: RoomDocument(name: "Chart room"))
        else {
            Issue.record("sage may color a part")
            return
        }
    }

    @Test func aHexColorOffersTheNearestRole() throws {
        let outcome = try RoomPatcher.apply(patch(.init(op: "look", trait: "color", value: "#FF0000")),
                                            sentence: "Make it #FF0000", engine: engine)
        guard case let .refused(refusal, _) = outcome else {
            Issue.record("a hex is refused")
            return
        }
        #expect(refusal.line.contains("named colors") && refusal.offer != nil)
    }

    @Test func aPickedPlaceHoldsThePatchToIt() throws {
        let fixture = RoomFixture.chart
        let steps = fixture.parts.filter { ["days", "soon", "pair"].contains($0.id) }.map {
            RoomPatch.Step(op: "add", id: $0.id, kind: $0.kind, place: $0.place, props: $0.props, bind: $0.bind)
        }
        try engine.perform(PatchRoom(patch: RoomPatch(room: "Chart room", say: "Keystone", ops: steps)), by: .tess)
        let calmer = patch(.init(op: "look", trait: "motion", value: "calm"))
        guard case .applied = try RoomPatcher.apply(calmer, sentence: "Make this calmer", picked: "keystone",
                                                    engine: engine)
        else {
            Issue.record("a keystone look stays inside the keystone")
            return
        }
        let outside = patch(add("t", "title", "title", ["text": .string("T")]))
        guard case let .refused(refusal, _) = try RoomPatcher.apply(
            outside,
            sentence: "Add a title",
            picked: "keystone",
            engine: engine
        )
        else {
            Issue.record("another place is refused while one is picked")
            return
        }
        #expect(refusal.line == "That changes more than the keystone. Say it again without picking?")
        let widget = patch(.init(op: "look", trait: "density", value: "airy"))
        #expect(RoomPatchValidator.touchesBeyond("keystone", patch: widget, document: RoomFixture.chart) != nil)
    }

    // MARK: History

    @Test func theRoomRemembersEverySentenceAndGoingBackIsOneUndoableGroup() throws {
        func say(_ sentence: String, _ steps: RoomPatch.Step...) throws -> OpRecord {
            engine.now = { Date(timeIntervalSince1970: 1_792_670_400 + Double(RoomHistory.entries(
                of: "Chart room",
                engine: engine
            ).count) * 60) }
            return try engine.perform(PatchRoom(patch: RoomPatch(room: "Chart room", say: "ok", ops: steps),
                                                sentence: sentence), by: .tess)
                .record
        }
        _ = try say("Make this my plant room", add("title", "title", "title", ["text": .string("Plants")]))
        let second = try say("Add a line", add("line", "line", "caption", ["text": .string("hello")]))
        _ = try say("Make it calmer", .init(op: "look", trait: "motion", value: "calm"))
        let entries = RoomHistory.entries(of: "Chart room", engine: engine)
        #expect(entries.map(\.note) == ["Make it calmer", "Add a line", "Make this my plant room"])
        let room = try #require(book.room(named: "Chart room"))
        let nowDocument = book.document(of: room)
        let wanted = try #require(try RoomHistory.version(of: "Chart room", after: entries[1], engine: engine))
        #expect(wanted.parts.map(\.id) == ["title", "line"] && wanted.look.isEmpty)
        #expect(second.state == .committed)
        let back = try #require(try RoomHistory.goBack(room: "Chart room", to: entries[1], label: "Back to 1:18 pm",
                                                       engine: engine))
        #expect(book.document(of: room) == wanted)
        #expect(RoomHistory.entries(of: "Chart room", engine: engine).first?.note == "Back to 1:18 pm")
        // Going back is a change like any other, so Undo returns to now, and nothing was lost.
        engine.undo(back)
        #expect(book.document(of: room) == nowDocument)
    }

    // MARK: Taking a room down

    @Test func takingARoomDownKeepsHisThingsAndBringingItBackRestoresIt() throws {
        let steps = RoomFixture.chart.parts.map {
            RoomPatch.Step(op: "add", id: $0.id, kind: $0.kind, place: $0.place, props: $0.props, bind: $0.bind)
        }
        let made = try engine.perform(PatchRoom(patch: RoomPatch(room: "Chart room", say: "Plants, set", ops: steps),
                                                sentence: "Make this my plant room"), by: .tess, pending: true)
        let room = try #require(book.room(named: "Chart room"))
        // Waiting for Allow, the room stays up.
        #expect(throws: ActionError.self) { try engine.perform(TakeDownRoom(room: room.id), by: .user) }
        #expect(RoomReach.allow(made.record, in: engine))
        let plants = try #require(store.classDef(named: "Plant")).objects?.count ?? 0
        let down = try engine.perform(TakeDownRoom(room: room.id), by: .user)
        #expect(book.room(named: "Chart room") == nil && book.rooms().isEmpty)
        #expect(book.takenDownRoom(named: "Chart room")?.id == room.id)
        #expect(book.grants(of: room).isEmpty && RoomHistory.entries(of: "Chart room", engine: engine).isEmpty)
        #expect((store.classDef(named: "Plant")?.objects?.count ?? 0) == plants, "his plants are untouched")
        #expect(down.record.ops.allSatisfy {
            if case .setValue = $0 {
                true
            } else {
                false
            }
        })
        // Bring it back: the room, its history and its grants are as they were.
        try engine.perform(BringBackRoom(room: room.id), by: .user)
        #expect(book.room(named: "Chart room")?.id == room.id)
        #expect(book.grants(of: room) == ["write Plant.lastWatered"])
        #expect(RoomHistory.entries(of: "Chart room", engine: engine).map(\.note) == ["Make this my plant room"])
        // Undo of the take-down is the same thing.
        let again = try engine.perform(TakeDownRoom(room: room.id), by: .user)
        engine.undo(again.record)
        #expect(book.room(named: "Chart room") != nil)
    }
}
