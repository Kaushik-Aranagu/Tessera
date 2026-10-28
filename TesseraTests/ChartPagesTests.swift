import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Sheets 375 to 378: a door for each plant, the plain page every plant gets, a change on one page reaching every page,
/// and the link to a routine. Real store, Core's `PageBook` and `PatchPage`.
@MainActor
struct ChartPagesTests {
    let app: AppModel
    let plants: ClassDef

    init() throws {
        let container = TesseraSchema.makeContainer(inMemory: true)
        app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        plants = try RoomSample.seedPlants(store: app.store, classes: app.classes, now: AppClock.now)
    }

    private var book: PageBook {
        PageBook(store: app.store, classes: app.classes)
    }

    private func plant(_ name: String) throws -> ObjectRecord {
        try #require(app.store.objects(of: plants).first { $0.title == name })
    }

    private func doorsRoom() -> ChartRoomModel {
        let room = ChartRoomModel(data: DemoRoomData(), defaults: nil) { _, _ in }
        room.attach(app.engine)
        var doc = ChartDoc(name: "Chart room", color: "olive")
        doc.parts = [
            ChartPart(id: "title", kind: .title, place: "title", props: ["text": .text("Plants")]),
            ChartPart(id: "row", kind: .row, place: "keystone",
                      props: ["big": .text("lastWatered"), "sort": .text("-daysSince(lastWatered)")], bind: "Plant"),
            ChartPart(
                id: "glow",
                kind: .top,
                place: "keystone",
                props: ["on": .text("row"), "field": .text("lastWatered")]
            ),
            ChartPart(id: "doors", kind: .doors, place: "dial",
                      props: ["summary": .text("waterEvery"), "sort": .text("-daysSince(lastWatered)")], bind: "Plant"),
        ]
        room.load(doc)
        return room
    }

    // MARK: 375, the doors

    @Test func eachPlantGetsADoorRankedLikeTheKeystoneAndOpensItsObject() throws {
        let room = doorsRoom()
        guard case let .doors(_, records)? = room.nodes[.dial]?.first else {
            Issue.record("no doors")
            return
        }
        #expect(records.count == 4)
        #expect(records.map { $0.split(separator: "|", omittingEmptySubsequences: false)[0] }
            == ["Orchid", "Monstera", "Fern", "Basil"], "in keystone order")
        #expect(records[0] == "Orchid|7|wine", "the thirsty plant carries the wine, with its steady fact")
        #expect(records[1].hasSuffix("|"), "the others have none")
        let orchid = try #require(room.doorObject(at: 0))
        #expect(app.store.object(id: orchid)?.title == "Orchid")
        let screen = DocumentRoom(nodes: room.nodes).screen(for: .landing("chart"), state: RoomState())
        guard case let .dial(doors)? = screen[.dial]?.payload else {
            Issue.record("no dial")
            return
        }
        #expect(doors.map(\.name) == ["Orchid", "Monstera", "Fern", "Basil"])
        #expect(doors[0].label == "7")
        #expect(screen[.doorSummary] != nil, "the summary sits on the left")
        #expect(ChartDoors.stop("chart.door.0", room)?.id == orchid)
        #expect(ChartDoors.stop("chart.door.9", room) == nil)
    }

    // MARK: 375, the plain page: override, then class, then generated

    private static func lines(_ id: String, _ text: String) -> RoomPatch {
        RoomPatch(room: "Plant page", say: "Dates", ops: [
            .init(op: "add", id: id, kind: "lines", place: "page", props: ["lines": .array([.string(text)])]),
        ])
    }

    @Test func thePlainPageIsGeneratedUntilHeSaysHowItShouldLook() throws {
        let orchid = try plant("Orchid")
        let ids = book.page(for: orchid).map(\.id)
        #expect(ids == ["title", "line", "number", "notes"])
        let nodes = PlainPage.nodes(parts: book.page(for: orchid), object: orchid, book: book, engine: app.engine)
        #expect(nodes[.title]?.first?.words == ["Orchid"])
        #expect(nodes[.keystone]?.first?.words.contains("7") == true, "the one number, in the keystone slot")
        #expect(ChartPlainPage.applies(to: orchid))
    }

    @Test func theObjectsOwnLayerWinsOverTheClassPageWhichWinsOverTheGeneratedOne() throws {
        let orchid = try plant("Orchid"), monstera = try plant("Monstera")
        try app.engine.perform(
            PatchPage(object: orchid.id, patch: Self.lines("watered", "Every plant's dates")),
            by: .user
        )
        func words(_ plant: ObjectRecord) -> String {
            let part = book.page(for: plant).first { $0.id == "watered" }
            if case let .array(items)? = part?.props["lines"], case let .string(text)? = items.first {
                return text
            }
            return ""
        }
        #expect(words(orchid) == "Every plant's dates" && words(monstera) == "Every plant's dates", "the class page")
        #expect(book.page(for: monstera).map(\.id).prefix(2) == ["title", "line"], "the generated parts are kept")
        try app.engine.perform(
            PatchPage(object: orchid.id, patch: Self.lines("watered", "Only the orchid"), only: true),
            by: .user
        )
        #expect(words(orchid) == "Only the orchid", "the object's own layer wins")
        #expect(words(monstera) == "Every plant's dates", "the other plants are untouched")
        let own = try #require(book.page(for: orchid).first { $0.id == "watered" })
        #expect(book.isOwn(own, of: orchid))
    }

    // MARK: 376, the scope speaks

    @Test func receiptAndTessLineComeFromTheScope() throws {
        let orchid = try plant("Orchid")
        let every = try app.engine.perform(PatchPage(object: orchid.id, patch: Self.lines("a", "x")), by: .user).output
        #expect(every.scope == .klass(name: "Plant", count: 4))
        #expect(every.receipt == "Every plant's page, set")
        #expect(every.line == "Every plant's page has it now, not just the orchid's")
        let only = try app.engine.perform(
            PatchPage(object: orchid.id, patch: Self.lines("b", "y"), only: true),
            by: .user
        )
        .output
        #expect(only.scope == .object(id: orchid.id, title: "Orchid"))
        #expect(only.receipt == "The orchid's page, set")
        #expect(only.line == "Only the orchid's page, the others don't get it")
    }

    @Test func aChangeSaidOnOnePageSetsAfterTheDryingAndUndoTakesItBackFromEveryPage() async throws {
        let orchid = try plant("Orchid"), monstera = try plant("Monstera")
        let pages = ChartPageModel(engine: app.engine, object: orchid.id, drying: .milliseconds(50))
        pages.say(ChartPageModel.showWatered(), only: false, sentence: "Show when I watered it")
        #expect(pages.pending != nil && pages.done == nil, "a ghost while it dries")
        try await Task.sleep(for: .milliseconds(400))
        #expect(pages.pending == nil)
        #expect(pages.done?.receipt == "Every plant's page, set")
        #expect(pages.done?.line == "Every plant's page has it now, not just the orchid's")
        #expect(book.page(for: monstera).contains { $0.id == "watered" })
        pages.undo()
        #expect(!book.page(for: monstera).contains { $0.id == "watered" }, "Undo reaches every page")
        #expect(pages.done == nil)
    }

    // MARK: 378, the routine link

    @Test func aLineNamesItsRoutineThroughALinkField() {
        #expect(PlainPage.routineLink(in: "Last misted Thursday, in {@step.parent.title}") == "step")
        #expect(PlainPage.routineLink(in: "Watered {recent(lastWatered,3)}") == nil)
        #expect(PlainPage.routineLink(in: "In {@step.title}") == nil)
    }
}
