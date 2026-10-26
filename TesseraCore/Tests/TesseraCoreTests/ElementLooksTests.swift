import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Living elements (docs/ai/harness/element-looks.md): a place's look is an object with a scope, the most specific
/// row wins, only the studio's forms and words are taken, a short nudge on the place he means runs with no model,
/// and only a place he can see is "this".
@MainActor
struct ElementLooksTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let now = Date(timeIntervalSince1970: 1_793_000_000)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    func look(_ scope: LookScope, _ shape: ContentShape, designed: String) -> ResolvedLook? {
        ElementLooks.look(scope, shape: shape, designed: designed, store: store, classes: classes)
    }

    func set(_ scope: LookScope, form: String = "", _ traits: [String: String] = [:]) throws -> OpRecord {
        try engine.perform(SetElementLook(scope: scope, form: form, traits: traits), by: .user).record
    }

    // MARK: Kept looks

    @Test func theMostSpecificLookWinsAndTheStudiosIsTheBase() throws {
        let deckDial = LookScope(room: "deck", place: "dial", level: "landing")
        #expect(look(deckDial, .doors, designed: "reel")?.isChanged == false)
        // Every dial as an index, then the Deck's landing dial calmer: both apply there, only the first elsewhere.
        _ = try set(LookScope(place: "dial"), form: "index")
        _ = try set(deckDial, ["motion": "calm"])
        let deck = try #require(look(deckDial, .doors, designed: "reel"))
        #expect(deck.form.name == "index" && deck.traits["motion"] == "calm" && deck.isChanged)
        let galley = try #require(look(LookScope(room: "galley", place: "dial"), .doors, designed: "reel"))
        #expect(galley.form.name == "index" && galley.traits["motion"] == "designed")
        // On the Deck's door pages, the room's landing-only row doesn't reach.
        let door = try #require(look(LookScope(room: "deck", place: "dial", level: "door"), .doors, designed: "reel"))
        #expect(door.traits["motion"] == "designed")
    }

    @Test func aFormThatCantDrawTodaysContentIsPassedOver() throws {
        _ = try set(LookScope(room: "log", place: "page"), form: "ledger")
        #expect(look(LookScope(room: "log", place: "page"), .many, designed: "rows")?.form.name == "ledger")
        // Words on the page today: a ledger can't draw them, so the studio's form stays.
        #expect(look(LookScope(room: "log", place: "page"), .words, designed: "wall")?.form.name == "wall")
    }

    @Test func onlyTheStudiosFormsAndWordsAreTaken() throws {
        let deck = LookScope(room: "deck", place: "keystone")
        #expect(throws: ActionError.self) { try set(LookScope(room: "galley", place: "keystone"), form: "chalk") }
        #expect(throws: ActionError.self) { try set(LookScope(place: "keystone"), form: "chalk") }
        #expect(throws: ActionError.self) { try set(deck, form: "card") }
        #expect(throws: ActionError.self) { try set(deck, form: "reel") }
        #expect(throws: ActionError.self) { try set(deck, form: "chalk", ["colour": "red"]) }
        #expect(throws: ActionError.self) { try set(deck, form: "chalk", ["motion": "wild"]) }
        _ = try set(deck, form: "chalk", ["shows": "bests"])
        #expect(look(deck, .few, designed: "chalk")?.traits["shows"] == "bests")
    }

    @Test func undoAndRestoreGiveTheOldLookBack() throws {
        let page = LookScope(room: "bridge", place: "page")
        let record = try set(page, form: "ledger", ["density": "dense"])
        #expect(look(page, .many, designed: "rows")?.form.name == "ledger")
        _ = engine.undo(record)
        #expect(look(page, .many, designed: "rows")?.isChanged == false)
        _ = try set(page, ["density": "airy"])
        _ = try engine.perform(RestoreElementLook(scope: page), by: .user)
        #expect(look(page, .many, designed: "rows")?.isChanged == false)
        // The row stays: the look is history, nothing is deleted.
        #expect(ElementLooks.row(page, store: store, classes: classes) != nil)
    }

    // MARK: Tess

    func meaning(_ place: ElementPlace, _ scope: LookScope, _ shape: ContentShape, designed: String,
                 room: String, shown: Bool = true, items: [ElementItem] = []) -> ElementMeaning
    {
        ElementMeaning(place: place, items: items, focus: items.isEmpty ? nil : 0,
                       calls: ElementCatalog.calls(room: room, place: place), isShown: shown,
                       look: LookInfo.make(scope, shape: shape, designed: designed, store: store, classes: classes))
    }

    func deckFrame(touch: TessFrame.Touch? = nil, keystoneShown: Bool = true) -> TessFrame {
        let push = ElementItem(id: UUID(), kind: "routine", name: "Push A")
        return TessFrame(room: "deck", elements: [
            meaning(.widget, LookScope(room: "deck", place: "widget"), .few, designed: "rise", room: "deck",
                    items: [push]),
            meaning(.keystone, LookScope(room: "deck", place: "keystone"), .few, designed: "chalk", room: "deck",
                    shown: keystoneShown),
            meaning(.dial, LookScope(room: "deck", place: "dial"), .doors, designed: "reel", room: "deck",
                    items: [ElementItem(kind: "door", name: "Plans")]),
        ], touch: touch, now: now)
    }

    @Test func aShortNudgeOnThePlaceHeMeansRunsWithNoModel() throws {
        let dial = try #require(ToolPicker.pick("the dial as an index", frame: deckFrame()).bound)
        #expect(dial.call == "reshape" && dial.place == .dial && dial.arguments["form"] == "index")
        #expect(dial.arguments["room"] == "deck")
        let calmer = try #require(ToolPicker.pick("make the dial calmer", frame: deckFrame()).bound)
        #expect(calmer.arguments["trait"] == "motion" && calmer.arguments["value"] == "calm")
        let every = try #require(ToolPicker.pick("every dial as an index", frame: deckFrame()).bound)
        #expect(every.arguments["room"] == "")
        // "This" with no place named: the widget is in focus.
        let bigger = try #require(ToolPicker.pick("bigger", frame: deckFrame()).bound)
        #expect(bigger.place == .widget && bigger.arguments["value"] == "bigger")
        let back = try #require(ToolPicker.pick("as it was", frame: deckFrame()).bound)
        #expect(back.call == "restoreLook")
    }

    @Test func aNudgeThatIsntAboutALookOrCantLandNeverBinds() {
        #expect(ToolPicker.pick("log a bigger set on bench", frame: deckFrame()).bound?.call != "reshape")
        // A dial can't be rows; a chalkboard can't go past its own words.
        #expect(ToolPicker.pick("the dial as a list", frame: deckFrame()).bound == nil)
        #expect(ToolPicker.pick("the board as tickets", frame: deckFrame()).bound == nil)
        // The keystone behind a sheet isn't "the board" he can see.
        #expect(ToolPicker.pick("make the board bigger", frame: deckFrame(keystoneShown: false)).bound == nil)
        // "I don't like this dial" is open: the model gets the look tools first and the look lines.
        let open = ToolPicker.pick("I don't like this dial, what else is there", frame: deckFrame())
        #expect(open.bound == nil && open.looks && open.tools.prefix(2) == ["reshape", "restoreLook"])
        let lines = deckFrame().fragments(looks: open.looks).map(\.text)
        #expect(lines.contains("Look of dial: drawn as reel; could be index; motion designed, size designed."))
    }

    @Test func thePursesLooksStayOnThePhone() throws {
        let purse = TessFrame(room: "purse", elements: [
            meaning(.dial, LookScope(room: "purse", place: "dial"), .doors, designed: "reel", room: "purse"),
        ], now: now)
        let calls = ElementCatalog.calls(room: "purse", place: .dial).filter { LookWords.calls.contains($0.name) }
        #expect(calls.count == 2 && calls.allSatisfy { $0.reach == .deviceOnly })
        let open = ToolPicker.pick("I don't like how this dial looks, try something else", frame: purse)
        #expect(!open.tools.contains("reshape") || open.plan.ladder == [.appleOnDevice])
        let bound = try #require(ToolPicker.pick("the dial as an index", frame: purse).bound)
        #expect(bound.call == "reshape" && ToolPicker.pick("the dial as an index", frame: purse).plan.ladder
            == [.appleOnDevice])
    }

    @Test func theToolKeepsHisOtherTraitsAndSaysWhenNothingChanges() throws {
        func run(_ json: String) throws -> [OpRecord] {
            try TessTools.run("reshape", arguments: Data(json.utf8), engine: engine, pending: false, now: now)
        }
        let dense = #"[{"name":"density","value":"dense"}]"#
        _ = try run(#"{"place":"page","room":"log","level":null,"form":null,"traits":"# + dense + "}")
        let made = try run(#"{"place":"page","room":"log","level":null,"form":null,"trait":"facts","value":"none"}"#)
        #expect(made.first?.receipt == "Log page, reshaped.")
        let kept = ElementLooks.stored(LookScope(room: "log", place: "page"), store: store, classes: classes)
        #expect(kept.traits == ["density": "dense", "facts": "none"])
        #expect(throws: TessToolAnswer.self) {
            try run(#"{"place":"page","room":"log","level":null,"form":null,"traits":[]}"#)
        }
    }

    // MARK: Shown

    @Test func onlyAShownPlaceIsThisAndAnUnseenOneSkipsItsMove() throws {
        let board = ElementItem(id: UUID(), kind: "lift", name: "Bench")
        var frame = deckFrame(touch: TessFrame.Touch(place: .keystone, item: board, at: now.addingTimeInterval(-5)),
                              keystoneShown: false)
        #expect(frame.referent()?.place == .widget)
        let reshape = try #require(frame.element(.keystone)?.calls.first { $0.name == "reshape" })
        #expect(frame.reaction(of: reshape, on: .keystone) == nil)
        #expect(frame.reaction(of: reshape, on: .dial) == .reshape)
        frame.elements[1].isShown = true
        #expect(frame.referent()?.place == .keystone)
    }
}
