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

    @Test func aRestoredRoomOwesAReplayOfHowItWasMadeThatWritesNothing() throws {
        func say(_ sentence: String, _ steps: RoomPatch.Step...) throws {
            engine.now = { Date(timeIntervalSince1970: 1_792_670_400 + Double(RoomHistory.entries(
                of: "Chart room",
                engine: engine
            ).count) * 60) }
            try engine.perform(PatchRoom(patch: RoomPatch(room: "Chart room", say: "ok", ops: steps),
                                         sentence: sentence), by: .tess)
        }
        try say("Make this my plant room", add("title", "title", "title", ["text": .string("Plants")]))
        try say("Put a line under it", add("line", "line", "caption", ["text": .string("hello")]))
        try say(
            "Same again",
            .init(op: "look", trait: "motion", value: "calm"),
            .init(op: "look", trait: "motion", value: "calm")
        )
        try say("Make it calmer", .init(op: "look", trait: "motion", value: "still"))
        let room = try #require(book.room(named: "Chart room"))
        try engine.perform(TakeDownRoom(room: room.id), by: .user)
        try engine.perform(BringBackRoom(room: room.id), by: .user)
        #expect(RoomReplay.isOwed(room, in: store))
        let before = store.context.all(OpRecord.self).count
        let steps = try RoomReplay.steps(of: "Chart room", engine: engine)
        #expect(steps.map(\.note) == ["Make this my plant room", "Put a line under it", "Same again", "Make it calmer"])
        #expect(steps.map(\.document.parts.count) == [1, 2, 2, 2])
        #expect(steps.last?.document == book.document(of: room))
        #expect(store.context.all(OpRecord.self).count == before, "the replay writes nothing")
        try engine.perform(MarkRoomOpened(room: room.id), by: .system)
        #expect(!RoomReplay.isOwed(room, in: store))
    }

    @Test func stoppingAChangeWhileItDriesThrowsItAwayAndLeavesNoTrace() throws {
        // A patch.
        let patch = try engine.perform(PatchRoom(patch: patch(add("t", "title", "title", ["text": .string("A")])),
                                                 sentence: "Add a title"), by: .tess, pending: true)
        #expect(RoomPatcher.stop([patch.record], in: engine) && patch.record.state == .undone)
        #expect(book.room(named: "Chart room") == nil && RoomHistory.entries(of: "Chart room", engine: engine).isEmpty)
        // A queued part, while it waits.
        guard case let .refused(_, queued) = try RoomPatcher.apply(self.patch(add("pots", "ring", "keystone")),
                                                                   sentence: "A ring of pots", engine: engine),
            let record = queued
        else {
            Issue.record("a ring is queued")
            return
        }
        #expect(RoomPatcher.stop([record], in: engine))
        #expect(book.room(named: "Chart room") == nil)
        // A take-down stopped halfway leaves the room up.
        try engine.perform(PatchRoom(patch: self.patch(add("t", "title", "title", ["text": .string("A")]))), by: .tess)
        let room = try #require(book.room(named: "Chart room"))
        let down = try engine.perform(TakeDownRoom(room: room.id), by: .user, pending: true)
        #expect(RoomPatcher.stop([down.record], in: engine) && book.room(named: "Chart room") != nil)
        // Once set, it cannot be stopped, only undone.
        let set = try engine.perform(TakeDownRoom(room: room.id), by: .user)
        #expect(!RoomPatcher.stop([set.record], in: engine))
    }

    // MARK: What Builder A's twelve sentences say

    @Test func actionWordIsAKindHoweverItIsCapitalised() throws {
        let patch = patch(.init(op: "grant", reach: "write Plant.lastWatered"),
                          .init(op: "add", id: "water", kind: "actionword", place: "actionWord",
                                props: ["verb": .string("Watered"), "does": .string("write Plant.lastWatered")],
                                bind: "Plant"))
        #expect(RoomRefusals.refusal(for: patch, against: RoomDocument(name: "Chart room"), store: store,
                                     classes: classes) == nil)
        guard case let .ok(document, _) = RoomPatchValidator(store: store, classes: classes)
            .validate(patch, against: RoomDocument(name: "Chart room"))
        else {
            Issue.record("a differently capitalised kind is the kind")
            return
        }
        #expect(document.part("water")?.kind == "actionWord", "stored under its own name")
        let exact = self.patch(.init(op: "grant", reach: "write Plant.lastWatered"),
                               add("water", "actionWord", "actionWord", ["verb": .string("Watered")], bind: "Plant"))
        #expect(RoomRefusals.refusal(for: exact, against: RoomDocument(name: "Chart room"), store: store,
                                     classes: classes) == nil)
        guard case .applied = try RoomPatcher.apply(exact, sentence: "Let me mark one watered", engine: engine) else {
            Issue.record("an action word goes through the real patcher")
            return
        }
    }

    @Test func staticWordsWindowsCardsAndLongerDoorRecordsAreInTheKit() {
        let steps: [RoomPatch.Step] = [
            add("line", "line", "switcher", ["words": .array(["Thirsty", "This week", "Light"].map { .string($0) })]),
            add("need", "lines", "needs", ["windows": .array([.string("Orchid, 6 days|Monstera, 4 days")])]),
            add("next", "list", "widget", ["cards": .array([
                .string("Thirstiest|Orchid|Last watered Wednesday|Ice cubes, not a pour|wine"),
            ])]),
            add("doors", "doors", "dial", ["doors": .array([
                .string(
                    "Basil|Last watered yesterday|Water every 2 days|On the kitchen sill|Pinch the flowers off|wine"
                ),
            ])]),
            .init(op: "look", trait: "glyph", value: "can"),
            .init(op: "look", trait: "say", value: "kept"),
        ]
        let result = RoomPatchValidator(store: store, classes: classes)
            .validate(RoomPatch(room: "Chart room", say: "x", ops: steps), against: RoomDocument(name: "Chart room"))
        guard case .ok = result else {
            Issue.record("Builder A's sentences are in the kit: \(result)")
            return
        }
        let tooLong = String(repeating: "x", count: 121)
        let long = patch(add("need", "lines", "needs", ["windows": .array([.string(tooLong)])]))
        #expect(RoomRefusals.refusal(for: long, against: RoomDocument(name: "Chart room"), store: store,
                                     classes: classes)?.line.contains("A record holds") == true)
    }

    @Test func theSamplePlantsCarryAMistedLinkToARoutineStepThatCanBeCheckedOff() throws {
        let orchid = try #require(store.classDef(named: "Plant")).objects?.first { $0.title == "Orchid" }
        let step = try #require(orchid.flatMap { store.linkedObjects("misted", of: $0).first })
        #expect(step.title == "Mist the orchid" && step.parent?.title == "Water houseplants")
        let book = RestBook(store: store, classes: classes)
        #expect(book.lastDone(ofStep: step.id) == nil)
        try engine.perform(TendRoutineStep(step: step.id, at: now), by: .user)
        #expect(book.lastDone(ofStep: step.id) == now)
        let fern = try #require(store.classDef(named: "Plant")).objects?.first { $0.title == "Fern" }
        #expect(fern.flatMap { store.linkedObjects("misted", of: $0).first } == nil, "only the orchid is misted")
    }
}
