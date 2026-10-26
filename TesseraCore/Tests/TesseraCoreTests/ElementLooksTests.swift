import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Living looks (Design sheets 286 and 287, docs/ai/harness/element-looks.md): a look is a form plus traits, kept as a
/// setting per room and place with each field inherited; the frame is the same in every look; a keystone keeps its
/// material; a short ask naming one change on the place he means runs with no model; a form Tess picks is staged off
/// screen first; and only a place he can see is "this".
/// What the stage was asked, from inside its closure.
@MainActor
final class StageLog {
    var changes: [LookChange] = []
}

@MainActor
struct ElementLooksTests {
    let now = Date(timeIntervalSince1970: 1_793_000_000)

    // MARK: Kept looks

    @Test func eachFieldInheritsFromEveryRoomThenTheStudio() throws {
        var looks = RoomLooks()
        #expect(looks.look(room: "deck", place: "dial") == PlaceLook(form: "reel", traits: ["density": "designed"]))
        looks = try #require(looks.applying(.form("index"), place: "dial", scope: .everywhere))
        looks = try #require(looks.applying(.trait("density", "dense"), place: "dial", scope: .room("deck")))
        // The Deck names only its density; its form comes from every room.
        #expect(looks.look(room: "deck", place: "dial") == PlaceLook(form: "index", traits: ["density": "dense"]))
        #expect(looks.look(room: "galley", place: "dial") == PlaceLook(form: "index", traits: ["density": "designed"]))
        #expect(looks.rooms["deck"]?["dial"] == PlaceLook(traits: ["density": "dense"]))
        looks = try #require(looks.applying(.form("sentence"), place: "dial", scope: .room("deck")))
        #expect(looks.look(room: "deck", place: "dial").form == "sentence")
        // As drawn in one room holds against every room's; as drawn everywhere clears the place in every room.
        looks = try #require(looks.applying(.designed, place: "dial", scope: .room("deck")))
        #expect(looks.look(room: "deck", place: "dial").form == "reel")
        #expect(looks.look(room: "galley", place: "dial").form == "index")
        looks = try #require(looks.applying(.designed, place: "dial", scope: .everywhere))
        #expect(looks == RoomLooks() && looks.encoded == nil)
        #expect(RoomLooks(encoded: looks.encoded) == looks)
    }

    @Test func onlyTheSheetsFormsAndOnlyWhereTheyFit() throws {
        let looks = RoomLooks()
        #expect(looks.applying(.form("card"), place: "dial", scope: .everywhere) == nil)
        #expect(looks.applying(.form("index"), place: "widget", scope: .room("deck")) == nil)
        #expect(looks.applying(.trait("density", "huge"), place: "dial", scope: .everywhere) == nil)
        #expect(looks.applying(.trait("colour", "red"), place: "dial", scope: .everywhere) == nil)
        // The ledger widget is the Purse's; a trace is the Lookout's and the Purse's.
        #expect(looks.applying(.form("ledger"), place: "widget", scope: .room("purse")) != nil)
        #expect(looks.applying(.form("ledger"), place: "widget", scope: .room("deck")) == nil)
        #expect(looks.applying(.form("trace"), place: "widget", scope: .everywhere) == nil)
        // Sheet 287's new forms: roll on the switcher, sentence on the doors and summary, columns on the page.
        #expect(LookCatalog.forms(for: "switcher").map(\.name) == ["type", "roll"])
        #expect(LookCatalog.forms(for: "dial").map(\.name) == ["reel", "index", "sentence"])
        #expect(LookCatalog.forms(for: "doorSummary").map(\.name) == ["type", "sentence"])
        #expect(LookCatalog.forms(for: "page").map(\.name).contains("columns"))
        // A keystone keeps its room's material: one form per room, none for every room, and motion to tune.
        #expect(LookCatalog.forms(for: "keystone", room: "deck").map(\.name) == ["chalk"])
        #expect(looks.applying(.form("chalk"), place: "keystone", scope: .room("log")) == nil)
        #expect(LookCatalog.traits(for: "keystone", form: "chalk").map(\.name) == ["motion", "shows"])
        #expect(looks.applying(.trait("shows", "bests"), place: "keystone", scope: .room("deck")) != nil)
        #expect(looks.applying(.trait("shows", "bests"), place: "keystone", scope: .everywhere) == nil)
        // A kept form or value that no longer exists falls through.
        let stale = RoomLooks(rooms: ["log": ["widget": PlaceLook(form: "ledger", traits: ["size": "huge"])]])
        let drawn = PlaceLook(form: "rise", traits: ["facts": "designed", "size": "designed"])
        #expect(stale.look(room: "log", place: "widget") == drawn)
        // No colour trait anywhere.
        let names = LookCatalog.places.keys.flatMap { place in
            LookCatalog.places[place]?.forms.flatMap { LookCatalog.traits(for: place, form: $0.form) } ?? []
        }.map(\.name)
        #expect(!names.contains { $0.contains("colo") })
    }

    @Test func looksAreASettingThatSurvivesARestore() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let settings = SettingsStore(engine: engine)
        let looks = try #require(RoomLooks().applying(.form("index"), place: "dial", scope: .room("deck")))
        _ = try settings.update { $0.placeLooks = looks.encoded }
        #expect(settings.read().looks.look(room: "deck", place: "dial").form == "index")
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
        let index = RoomLooks(rooms: ["deck": ["dial": PlaceLook(form: "index"), "widget": PlaceLook(form: "stack")]])
        #expect(reel.look(room: "deck", place: "dial") != index.look(room: "deck", place: "dial"))
        let first = deckFrame(), second = deckFrame()
        #expect(first.room == second.room && first.elements.map(\.calls) == second.elements.map(\.calls))
        #expect(first.fragments().map(\.text) == second.fragments().map(\.text))
        #expect(ToolPicker.pick("start", frame: first, looks: reel).tools
            == ToolPicker.pick("start", frame: second, looks: index).tools)
        // Only an ask about looks reads them, from settings.
        #expect(first.lookLines(reel) != first.lookLines(index))
    }

    // MARK: Tess

    @Test func aShortAskNamingOneChangeRunsWithNoModel() throws {
        let index = try #require(ToolPicker.pick("show the doors as an index", frame: deckFrame()).bound)
        #expect(index.call == "setLook" && index.place == .dial && index.arguments["form"] == "index")
        #expect(index.arguments["scope"] == "room" && index.arguments["room"] == "deck")
        let every = try #require(ToolPicker.pick("every dial as a list", frame: deckFrame()).bound)
        #expect(every.arguments["form"] == "index" && every.arguments["scope"] == "everywhere")
        let one = try #require(ToolPicker.pick("the summary as one sentence", frame: deckFrame()).bound)
        #expect(one.arguments["form"] == "sentence")
        let sky = try #require(ToolPicker.pick("calmer sky", frame: deckFrame(room: "lookout")).bound)
        #expect(sky.place == .keystone && sky.arguments["trait"] == "motion" && sky.arguments["value"] == "calm")
        // No place named: the one he touched. A trait word steps from his kept value.
        let touch = TessFrame.Touch(place: .dial, item: ElementItem(kind: "door", name: "Plans"),
                                    at: now.addingTimeInterval(-5))
        let denser = try #require(ToolPicker.pick("denser", frame: deckFrame(touch: touch)).bound)
        #expect(denser.arguments["trait"] == "density" && denser.arguments["value"] == "dense")
        let airy = RoomLooks(rooms: ["deck": ["dial": PlaceLook(traits: ["density": "airy"])]])
        let bit = ToolPicker.pick("make it a bit denser", frame: deckFrame(touch: touch), looks: airy)
        let up = try #require(bit.bound)
        #expect(up.arguments["value"] == "designed")
        let back = try #require(ToolPicker.pick("as drawn", frame: deckFrame(touch: touch)).bound)
        #expect(back.place == .dial && LookWords.change(back.arguments) == .designed)
        let browse = try #require(ToolPicker.pick("what looks can the doors have", frame: deckFrame()).bound)
        #expect(browse.call == "showLooks" && browse.place == .dial)
        #expect(TessRun.lookLine(index.arguments) == "The dial, as index.")
        #expect(ShellIntent(call: "setLook", arguments: sky.arguments).change == .motion)
        #expect(ShellIntent(call: "setLook", arguments: index.arguments).change == .form)
    }

    @Test func anAskThatNamesNoChangeOrAPlaceHeCantSeeNeverBinds() {
        #expect(ToolPicker.pick("add milk to the list", frame: deckFrame()).bound?.call != "setLook")
        // A trait word in a longer ask about something else is not a look.
        let touch = TessFrame.Touch(place: .widget, item: ElementItem(kind: "routine", name: "Push A"),
                                    at: now.addingTimeInterval(-5))
        #expect(ToolPicker.pick("add bigger plates", frame: deckFrame(touch: touch)).bound?.call != "setLook")
        #expect(ToolPicker.pick("make the board calmer", frame: deckFrame(keystoneShown: false)).bound == nil)
        // A step past the end needs the model: the doors can't get denser than dense.
        let dense = RoomLooks(rooms: ["deck": ["dial": PlaceLook(traits: ["density": "dense"])]])
        #expect(ToolPicker.pick("denser doors", frame: deckFrame(), looks: dense).bound == nil)
        // Open: the model gets the look calls first, and the look lines from settings.
        let open = ToolPicker.pick("I don't like this dial, what would be better here", frame: deckFrame())
        #expect(open.bound == nil && open.looks && open.tools.prefix(2) == ["setLook", "showLooks"])
        let lines = deckFrame().lookLines(RoomLooks()).map(\.text)
        #expect(lines.contains(
            "Look of dial: reel; other forms index, sentence; traits density designed of airy/designed/dense."
        ))
    }

    // MARK: The quiet stage

    @Test func aFormTessPicksIsStagedAndAppliedOnlyIfItPasses() async throws {
        let helper = TessRunTests()
        let ask = "I don't like this dial, what would be better here"
        let sentence = #"{"place":"dial","form":"sentence","trait":null,"value":null,"scope":null}"#
        for passes in [false, true] {
            let haiku = ScriptedBrain(.haiku, rounds: [[helper.use("t1", "setLook", sentence)], [.text("Done.")]])
            let r = try helper.rig([.haiku: haiku])
            let log = StageLog()
            r.run.stage = { place, change in
                log.changes.append(change)
                return StageReport(places: [StageFlags(place: place, fits: passes, touch: passes)])
            }
            let events = await helper.collect(r.run.ask(ask, frame: deckFrame()))
            let shells = events.compactMap { event -> ShellIntent? in
                if case let .shell(intent) = event {
                    intent
                } else {
                    nil
                }
            }
            #expect(log.changes == [.form("sentence")])
            #expect(shells.count == (passes ? 1 : 0))
            if !passes {
                let second = try #require(haiku.requestsSeen.last)
                let said = second.messages.last?.content.compactMap { piece -> String? in
                    if case let .toolResult(_, content, _) = piece { content } else { nil }
                } ?? []
                #expect(said.first?.contains("The dial fails fits, touch.") == true)
            }
        }
        // A form no place has never reaches the stage or the shell.
        #expect(LookWords.isKnown(.form("card"), place: "dial") == false)
        #expect(StageReport(places: [StageFlags(place: .dial)]).line == "It passes every check.")
    }

    @Test func aReshapeTravelsWhatBothFormsShowAndCollapsesOnlyWhenNothingIsShared() {
        let a = UUID(), b = UUID(), c = UUID()
        #expect(ReshapeMove(before: [a, b], after: [b, c]) == .travel(shared: [b]))
        #expect(ReshapeMove(before: [a], after: [c]) == .collapse)
        #expect(Reaction.reshape.change == .form && Reaction.tessLine.change == nil)
        #expect(!Control.stage.isShown && Control.tess.isShown)
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
