import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Tess AI-first (docs/ai/harness/elements.md): the screen says what it shows and what can be done to it, "this" is
/// what he touched or what is in focus, a short command on the thing in focus runs with no model, money calls never
/// reach Claude, and Tess gets the screen's calls first.
@Suite(.oldWalls)
struct ElementsTests {
    let now = Date(timeIntervalSince1970: 1_793_000_000)

    func frame(_ room: String, place: ElementPlace = .widget, items: [ElementItem], focus: Int? = 0,
               window: String? = nil, touch: TessFrame.Touch? = nil) -> TessFrame
    {
        var elements = [ElementMeaning(place: place, items: items, focus: focus,
                                       calls: ElementCatalog.calls(room: room, place: place))]
        let action = ElementCatalog.calls(room: room, place: .actionWord)
        if place != .actionWord, !action.isEmpty {
            elements.append(ElementMeaning(place: .actionWord, calls: action))
        }
        return TessFrame(room: room, window: window, elements: elements, touch: touch, now: now)
    }

    // MARK: The catalog

    @MainActor
    @Test func everyCallIsARealToolAProposedOneOrTheShell() {
        let real = Set(TessTools.all.map(\.name)).union([TessOpenTool.name])
        for call in ElementCatalog.everyCall {
            switch call.kind {
            case .tool:
                #expect(real.contains(call.name) || ElementCatalog.proposed.contains(call.name), "\(call.name)")
            case .shell: #expect(ElementCatalog.shellCalls.contains(call.name), "\(call.name)")
            }
        }
        // A proposed tool is one Core hasn't added yet; once it lands, it leaves the list.
        #expect(ElementCatalog.proposed.isDisjoint(with: real))
    }

    @Test func moneyCallsRunOnThePhoneOnly() {
        let purse = ElementPlace.allCases.flatMap { ElementCatalog.calls(room: "purse", place: $0) }
        #expect(purse.filter { $0.kind == .tool && $0.name != "query" }.allSatisfy { $0.reach == .deviceOnly })
        let elsewhere = ["bridge", "log", "lookout", "deck", "galley", "watch"].flatMap { room in
            ElementPlace.allCases.flatMap { ElementCatalog.calls(room: room, place: $0) }
        }
        #expect(!elsewhere.contains { $0.name == "logSpend" })
    }

    // MARK: Binding a short command

    @Test func doneOnTheWidgetCompletesTheShownTaskWithNoModel() throws {
        let task = ElementItem(id: UUID(), kind: "task", name: "Call the bank")
        let pick = ToolPicker.pick("done", frame: frame("bridge", items: [task]))
        let bound = try #require(pick.bound)
        #expect(bound.call == "completeTask" && bound.object == task.id && bound.arguments["task"] == "Call the bank")
        #expect(bound.place == .widget && pick.tools == ["completeTask"])
    }

    @Test func doneOnAListItemChecksItInstead() throws {
        let item = ElementItem(id: UUID(), kind: "list item", name: "Passport")
        let bound = try #require(ToolPicker.pick("got it", frame: frame("log", items: [item])).bound)
        #expect(bound.call == "checkListItem" && bound.object == item.id)
        let done = try #require(ToolPicker.pick("done", frame: frame("log", items: [item])).bound)
        #expect(done.call == "checkListItem")
    }

    @Test func aTouchSaysWhatThisIsForThirtySeconds() throws {
        let shown = ElementItem(id: UUID(), kind: "task", name: "Call the bank")
        let touched = ElementItem(id: UUID(), kind: "task", name: "Book club")
        let fresh = TessFrame.Touch(place: .widget, item: touched, at: now.addingTimeInterval(-10))
        let touchedFrame = frame("bridge", items: [shown], touch: fresh)
        let bound = try #require(ToolPicker.pick("this is done", frame: touchedFrame).bound)
        #expect(bound.object == touched.id)
        let stale = TessFrame.Touch(place: .widget, item: touched, at: now.addingTimeInterval(-40))
        #expect(frame("bridge", items: [shown], touch: stale).referent()?.item == shown)
    }

    @Test func openThisOpensTheThingNotADoor() throws {
        let note = ElementItem(id: UUID(), kind: "note", name: "Trip packing")
        var log = frame("log", place: .keystone, items: [note])
        log.elements.append(ElementMeaning(place: .dial, items: [ElementItem(kind: "door", name: "Pinned")],
                                           focus: 0, calls: ElementCatalog.calls(room: "log", place: .dial)))
        let bound = try #require(ToolPicker.pick("open this", frame: log).bound)
        #expect(bound.call == "openItem" && bound.object == note.id)
    }

    @Test func nothingInFocusOrALongAskNeverBinds() {
        #expect(ToolPicker.pick("done", frame: frame("bridge", items: [], focus: nil)).bound == nil)
        let task = ElementItem(id: UUID(), kind: "task", name: "Call the bank")
        let long = "done with the call but remind me to send the form on Friday morning"
        #expect(ToolPicker.pick(long, frame: frame("bridge", items: [task])).bound == nil)
    }

    // MARK: Walls

    @Test func aPrivateThingIsReadByItsLabelAndActedOnByItsID() throws {
        let note = ElementItem(id: UUID(), kind: "list item", name: "Private item", isPrivate: true)
        let log = frame("log", items: [note])
        #expect(log.fragments().allSatisfy { !$0.text.contains("Lexapro") })
        #expect(log.fragments().contains { $0.text.contains("Private item") })
        let bound = try #require(ToolPicker.pick("done", frame: log).bound)
        #expect(bound.object == note.id)
    }

    @Test func moneyNeverReachesClaude() {
        let today = ElementItem(kind: "spend", name: "Today", taint: .deviceOnly,
                                facts: [ElementFact("86", taint: .deviceOnly)])
        let purse = frame("purse", items: [today])
        let spend = ToolPicker.pick("I spent 12 on lunch", frame: purse)
        #expect(spend.tools == ["logSpend"] && spend.plan.ladder == [.appleOnDevice] && spend.bound == nil)
        let look = ToolPicker.pick("how am I doing this month", frame: purse)
        #expect(!look.tools.contains("logSpend"))
        // The amounts ride as deviceOnly: strict keeps them off Claude.
        let amounts = purse.fragments().filter { $0.text.contains("86") }
        #expect(!amounts.isEmpty && amounts.allSatisfy { !DoorPolicy.strict.allows($0, onClaude: true) })
    }

    @Test func moneyPrivateAndPurseItemsAreDeviceOnlyWhateverTheNavigatorSet() {
        // None of these carries a taint of its own.
        let spend = ElementItem(kind: "Spend", name: "Lunch", facts: [ElementFact("12")])
        let hidden = ElementItem(id: UUID(), kind: "note", name: "Private note", isPrivate: true)
        let inPurse = ElementItem(kind: "door", name: "Month")
        let plain = ElementItem(kind: "task", name: "Call the bank")
        let log = frame("log", items: [spend, hidden, plain])
        let purse = frame("purse", items: [inPurse])
        for line in log.fragments().filter({ $0.text.contains("Lunch") || $0.text.contains("Private note") })
            + purse.fragments().filter({ $0.text.contains("Month") })
        {
            #expect(!DoorPolicy.strict.allows(line, onClaude: true), "\(line.text)")
        }
        #expect(log.fragments().contains { $0.text.contains("Call the bank") && DoorPolicy.strict.allows(
            $0,
            onClaude: true
        ) })
    }

    // MARK: Open asks

    @MainActor
    @Test func anOpenAskGetsTheScreensCallsFirstAndSonnet() {
        let push = ElementItem(id: UUID(), kind: "routine", name: "Push A", facts: [ElementFact("tonight 6:30 pm")])
        let deck = frame("deck", items: [push])
        let pick = ToolPicker.pick("why has my bench stalled and what should I change", frame: deck,
                                   agent: AgentSpec.training)
        #expect(pick.bound == nil && pick.plan == .open)
        #expect(pick.tools.first == "startWorkout" && pick.tools.contains("query"))
        #expect(pick.tools.count <= ToolPicker.maxTools)
        let fragments = frame("deck", items: [push], window: "This week").fragments()
        #expect(fragments.first?.text == "Where: Deck, the landing, This week")
        #expect(fragments.contains { $0.text == "This: routine Push A, tonight 6:30 pm (widget)" })
    }
}
