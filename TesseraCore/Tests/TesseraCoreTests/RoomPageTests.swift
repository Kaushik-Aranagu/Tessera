import Foundation
@testable import TesseraCore
import Testing

/// Design sheets 375 to 378: each plant gets a door, a plant's plain page is its class's generated page, a change said
/// on it reaches every plant (or just one), and a write from the page needs no room grant.
@MainActor
struct RoomPageTests {
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

    var pages: PageBook {
        PageBook(store: store, classes: classes)
    }

    func plant(_ name: String) throws -> ObjectRecord {
        let plantClass = try #require(store.classDef(named: "Plant"))
        return try #require(store.objects(of: plantClass).first { $0.title == name })
    }

    func line(_ id: String, _ text: String) -> RoomPatch.Step {
        RoomPatch.Step(op: "add", id: id, kind: "line", place: "page", props: ["text": .string(text)])
    }

    // MARK: 375

    @Test func theDoorsPartIsBoundToTheRoomsListAndReordersWithIt() throws {
        var bind = RoomBind(store: store, classes: classes)
        bind.calendar = calendar
        let doors = try #require(RoomFixture.chart.part("doors"))
        let list = pages.doors(for: doors, rows: bind)
        #expect(list.map(\.title).sorted() == ["Basil", "Fern", "Monstera", "Orchid"])
        // Each door's destination is the plant itself.
        let orchid = try plant("Orchid")
        #expect(list.first { $0.title == "Orchid" }?.object == orchid.id)
        #expect(list.first { $0.title == "Orchid" }?.summary == "Oct 16", "the summary is the field the part names")
    }

    @Test func aPlantsPlainPageIsGeneratedNotStoredAndTheWriteNeedsNoGrant() throws {
        let orchid = try plant("Orchid")
        let before = store.context.all(OpRecord.self).count
        let page = pages.page(for: orchid)
        #expect(page.map(\.id) == ["title", "line", "number", "notes"], "title, one line, the number, notes")
        #expect(pages.layers().isEmpty && store.context.all(OpRecord.self).count == before, "nothing is stored")
        #expect(pages.text("{title}", for: orchid) == "Orchid")
        // Marking his own plant on its own page goes through no room grant and needs no Allow.
        let book = RoomBook(store: store, classes: classes)
        #expect(RoomReach.permits("write Plant.lastWatered", from: .objectPage, book: book))
        #expect(!RoomReach.permits("write Plant.lastWatered", from: .room("Chart room"), book: book))
        try store.set("lastWatered", to: .date(now), on: orchid)
        #expect(pages.text("{lastWatered}", for: orchid, calendar: calendar) == "Oct 22")
    }

    // MARK: 376

    @Test func aChangeOnOnePlantsPageReachesEveryPlantsPageAndUndoTakesItBack() throws {
        let monstera = try plant("Monstera")
        let fern = try plant("Fern")
        let patch = RoomPatch(room: "Plant page", say: "Dates, set", ops: [
            line("recent", "Last three times: {recent(lastWatered,3)}"),
        ])
        // The dates the plants were watered, in the op log: three waterings of the fern.
        for days in [6.0, 3, 1] {
            engine.now = { now.addingTimeInterval(-days * 86400) }
            try engine.perform(SetFieldForTest(object: fern.id, date: now.addingTimeInterval(-days * 86400)), by: .user)
        }
        let result = try engine.perform(
            PatchPage(object: monstera.id, patch: patch, sentence: "Show when I watered it"),
            by: .tess,
            pending: true
        )
        #expect(result.output.scope == .klass(name: "Plant", count: 4))
        #expect(result.output.receipt == "Every plant's page, set")
        #expect(result.output.line == "Every plant's page has it now, not just the monstera's")
        for name in ["Monstera", "Fern", "Orchid", "Basil"] {
            #expect(try pages.page(for: plant(name)).map(\.id).contains("recent"), "\(name) has it")
        }
        let fernText = try #require(pages.page(for: fern).first { $0.id == "recent" }?.text("text"))
        #expect(pages
            .text(fernText, for: fern, engine: engine, calendar: calendar) ==
            "Last three times: Oct 21, Oct 19 and Oct 16")
        // The generated page became a stored one at its first change, with the generated parts in it.
        #expect(pages.layers().count == 1 && pages.page(for: monstera).map(\.id).prefix(4) == [
            "title",
            "line",
            "number",
            "notes",
        ])
        engine.undo(result.record)
        #expect(!pages.page(for: fern).map(\.id).contains("recent") && pages.layers().isEmpty)
    }

    // MARK: 378

    @Test func justForTheOrchidWritesAnObjectLayerBoundThroughALinkAndAnEmptyOneIsDeleted() throws {
        // Plant.step -> a routine step; the page part reads the step and its routine through the link.
        let plantClass = try #require(store.classDef(named: "Plant"))
        let thing = try #require(classes[.thing])
        let field = FieldDef(name: "Misting", key: "misting", kind: .ref, sortIndex: 5)
        field.targetClassID = thing.id
        field.owner = plantClass
        store.context.insert(field)
        store.invalidateCaches()
        let routine = try store.create(#require(classes[.routine]), title: "Water houseplants")
        let step = store.create(thing, title: "Mist the orchid", parent: routine)
        let orchid = try plant("Orchid")
        try store.setLinks("misting", on: orchid, to: [step])
        let patch = RoomPatch(room: "Orchid page", say: "Misting, set", ops: [
            line("misting", "Last misted: {@misting.title}, in {@misting.parent.title}"),
        ])
        let result = try engine.perform(
            PatchPage(object: orchid.id, patch: patch, only: true, sentence: "Just the orchid"),
            by: .tess,
            pending: true
        )
        #expect(result.output.scope == .object(id: orchid.id, title: "Orchid"))
        #expect(result.output.receipt == "The orchid's page, set")
        #expect(result.output.line == "Only the orchid's page, the others don't get it")
        let own = try #require(pages.page(for: orchid).first { $0.id == "misting" })
        #expect(pages.text(own.text("text") ?? "", for: orchid) == "Last misted: Mist the orchid, in Water houseplants")
        #expect(pages.isOwn(own, of: orchid))
        #expect(try !pages.page(for: plant("Fern")).map(\.id).contains("misting"), "the fern's page is unchanged")
        #expect(pages.layers().count == 1 && pages.layer(forObject: orchid.id) != nil)
        // Taking the part off leaves an override with no parts: it is deleted and the orchid falls back to the class.
        let off = try engine.perform(PatchPage(object: orchid.id,
                                               patch: RoomPatch(
                                                   room: "x",
                                                   say: "Gone",
                                                   ops: [.init(op: "remove", id: "misting")]
                                               ),
                                               only: true), by: .tess)
        _ = off
        #expect(pages.layer(forObject: orchid.id) == nil)
        #expect(pages.page(for: orchid).map(\.id) == ["title", "line", "number", "notes"])
        // Undo removes the override, as it removes any change.
        engine.undo(result.record)
        #expect(pages.layers().isEmpty)
    }
}

/// A plain date write on a plant, so the test has a history to read.
struct SetFieldForTest: EngineAction {
    static let descriptor = ActionDescriptor(name: "setFieldForTest", summary: "Test", parameters: [],
                                             isOfferedToModel: false)
    var object: UUID
    var date: Date

    func apply(_ transaction: inout Transaction) throws {
        try transaction.set("lastWatered", to: .date(date), on: transaction.object(object))
    }

    func summary(in _: ObjectStore) -> String {
        "Watered"
    }

    func receipt(in _: ObjectStore) -> String? {
        nil
    }
}
