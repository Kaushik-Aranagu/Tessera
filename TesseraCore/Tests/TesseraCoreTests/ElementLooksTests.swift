import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Living looks (Design sheet 286, docs/ai/harness/element-looks.md): a look is a setting per room and place, the
/// frame is the same in every look, a keystone only has Quiet, a short ask naming one look on the place he means runs
/// with no model, and only a place he can see is "this".
@MainActor
struct ElementLooksTests {
    let now = Date(timeIntervalSince1970: 1_793_000_000)

    // MARK: Kept looks

    @Test func theRoomsLookWinsThenEveryRoomsThenTheDefault() throws {
        var looks = RoomLooks()
        #expect(looks.look(room: "deck", place: "dial") == "reel")
        looks = try #require(looks.setting("column", place: "dial", scope: .everywhere))
        looks = try #require(looks.setting("sentence", place: "dial", scope: .room("deck")))
        #expect(looks.look(room: "deck", place: "dial") == "sentence")
        #expect(looks.look(room: "galley", place: "dial") == "column")
        // The default everywhere clears every room's entry rather than storing it.
        looks = try #require(looks.setting("reel", place: "dial", scope: .everywhere))
        #expect(looks.everywhere["dial"] == nil && looks.look(room: "galley", place: "dial") == "reel")
        #expect(RoomLooks(encoded: looks.encoded) == looks)
    }

    @Test func onlyTheSheetsLooksAndOnlyWhereTheyFit() throws {
        let looks = RoomLooks()
        #expect(looks.setting("card", place: "dial", scope: .everywhere) == nil)
        #expect(looks.setting("column", place: "widget", scope: .room("deck")) == nil)
        // By time needs rows with times: the Deck has them, the Log doesn't, and so not every room.
        #expect(looks.setting("byTime", place: "page", scope: .room("deck")) != nil)
        #expect(looks.setting("byTime", place: "page", scope: .room("log")) == nil)
        #expect(looks.setting("byTime", place: "page", scope: .everywhere) == nil)
        // A kept look a room can't show falls through to the default.
        let stale = RoomLooks(rooms: ["log": ["page": "byTime", "dial": "gone"]])
        #expect(stale.look(room: "log", place: "page") == "ranked" && stale.look(room: "log", place: "dial") == "reel")
        // A keystone is its room's identity: as drawn, or Quiet.
        #expect(LookCatalog.looks(for: "keystone").map(\.id) == ["drawn", "quiet"])
    }

    @Test func looksAreASettingThatSurvivesARestore() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let settings = SettingsStore(engine: engine)
        let looks = try #require(RoomLooks().setting("column", place: "dial", scope: .room("deck")))
        _ = try settings.update { $0.placeLooks = looks.encoded }
        #expect(settings.read().looks.look(room: "deck", place: "dial") == "column")
        // Only what the catalog reads lands.
        _ = try settings.update { $0.placeLooks = "not json" }
        #expect(settings.read().placeLooks == nil)
    }

    // MARK: The frame

    func deckFrame(touch: TessFrame.Touch? = nil, keystoneShown: Bool = true, room: String = "deck") -> TessFrame {
        let push = ElementItem(id: UUID(), kind: "routine", name: "Push A")
        func meaning(_ place: ElementPlace, _ items: [ElementItem] = [], shown: Bool = true) -> ElementMeaning {
            ElementMeaning(place: place, items: items, focus: items.isEmpty ? nil : 0,
                           calls: ElementCatalog.calls(room: room, place: place), isShown: shown)
        }
        return TessFrame(room: room, elements: [
            meaning(.widget, [push]),
            meaning(.keystone, shown: keystoneShown),
            meaning(.dial, [ElementItem(kind: "door", name: "Plans")]),
            meaning(.doorSummary),
        ], touch: touch, now: now)
    }

    @Test func theSameScreenInTwoLooksGivesTheSameFrame() {
        // Sheet 286: a look keeps the place's frame, items, focus and calls, so nothing Tess reads moves with it.
        let reel = RoomLooks()
        let column = RoomLooks(rooms: ["deck": ["dial": "column", "widget": "oneAndNext"]])
        #expect(reel.look(room: "deck", place: "dial") != column.look(room: "deck", place: "dial"))
        let first = deckFrame(), second = deckFrame()
        #expect(first.room == second.room && first.elements.map(\.calls) == second.elements.map(\.calls))
        #expect(first.fragments().map(\.text) == second.fragments().map(\.text))
        #expect(ToolPicker.pick("start", frame: first).tools == ToolPicker.pick("start", frame: second).tools)
        // Only an ask about looks reads them, from settings.
        #expect(first.lookLines(reel) != first.lookLines(column))
    }

    // MARK: Tess

    @Test func aShortAskNamingOneLookRunsWithNoModel() throws {
        let column = try #require(ToolPicker.pick("show the doors as a column", frame: deckFrame()).bound)
        #expect(column.call == "setLook" && column.place == .dial && column.arguments["look"] == "column")
        #expect(column.arguments["scope"] == "room" && column.arguments["room"] == "deck")
        let every = try #require(ToolPicker.pick("every dial as a list", frame: deckFrame()).bound)
        #expect(every.arguments["look"] == "column" && every.arguments["scope"] == "everywhere")
        let one = try #require(ToolPicker.pick("the summary as one sentence", frame: deckFrame()).bound)
        #expect(one.arguments["look"] == "oneSentence")
        let sky = try #require(ToolPicker.pick("quieter sky", frame: deckFrame(room: "lookout")).bound)
        #expect(sky.place == .keystone && sky.arguments["look"] == "quiet")
        // No place named: the one he touched.
        let touch = TessFrame.Touch(place: .dial, item: ElementItem(kind: "door", name: "Plans"),
                                    at: now.addingTimeInterval(-5))
        let back = try #require(ToolPicker.pick("as drawn", frame: deckFrame(touch: touch)).bound)
        #expect(back.place == .dial && back.arguments["look"] == "reel")
        let browse = try #require(ToolPicker.pick("what looks can the doors have", frame: deckFrame()).bound)
        #expect(browse.call == "showLooks" && browse.place == .dial)
        #expect(TessRun.lookLine(column.arguments) == "The dial, as column.")
    }

    @Test func anAskThatNamesNoLookOrAPlaceHeCantSeeNeverBinds() {
        #expect(ToolPicker.pick("add milk to the list", frame: deckFrame()).bound?.call != "setLook")
        #expect(ToolPicker.pick("make the board quieter", frame: deckFrame(keystoneShown: false)).bound == nil)
        // The Log's rows have no times.
        #expect(ToolPicker.pick("the rows by time", frame: deckFrame(room: "log")).bound == nil)
        // Open: the model gets the look calls first, and the look lines from settings.
        let open = ToolPicker.pick("I don't like this dial, what would be better here", frame: deckFrame())
        #expect(open.bound == nil && open.looks && open.tools.prefix(2) == ["setLook", "showLooks"])
        let lines = deckFrame().lookLines(RoomLooks()).map(\.text)
        #expect(lines.contains("Look of dial: Reel; could be Column (column), Sentence (sentence)."))
    }

    // MARK: Shown

    @Test func onlyAShownPlaceIsThisAndAnUnseenOneSkipsItsMove() throws {
        let board = ElementItem(id: UUID(), kind: "lift", name: "Bench")
        var frame = deckFrame(touch: TessFrame.Touch(place: .keystone, item: board, at: now.addingTimeInterval(-5)),
                              keystoneShown: false)
        #expect(frame.referent()?.place == .widget)
        let setLook = try #require(frame.element(.keystone)?.calls.first { $0.name == "setLook" })
        #expect(frame.reaction(of: setLook, on: .keystone) == nil)
        #expect(frame.reaction(of: setLook, on: .dial) == .reshape)
        frame.elements[1].isShown = true
        #expect(frame.referent()?.place == .keystone)
    }
}
