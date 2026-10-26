import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// `TessRun.ask(_:frame:)`: the frame's fragments instead of "On screen", the picker's tools and rung, a bound short
/// command with no model at all, a shell call handed to the host, and the new tools over their engine actions.
@MainActor
struct TessRunElementsTests {
    let helper = TessRunTests()

    func frame(_ room: String, items: [ElementItem], place: ElementPlace = .widget, focus: Int? = 0,
               now: Date = .now) -> TessFrame
    {
        var elements = [ElementMeaning(place: place, items: items, focus: focus,
                                       calls: ElementCatalog.calls(room: room, place: place))]
        elements.append(ElementMeaning(place: .actionWord, calls: ElementCatalog.calls(room: room, place: .actionWord)))
        return TessFrame(room: room, elements: elements, now: now)
    }

    func makeTask(_ r: TessRunTests.Rig, _ title: String) throws -> ObjectRecord {
        try r.engine.perform(CreateTask(title: title), by: .user).output
    }

    // MARK: Bound, no model

    @Test func doneOnTheWidgetRunsWithNoModelAndLeavesAGhost() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [])
        let r = try helper.rig([.haiku: haiku])
        let task = try makeTask(r, "Call the bank")
        let item = ElementItem(id: task.id, kind: "task", name: "Call the bank")
        let events = await helper.collect(r.run.ask("done", frame: frame("bridge", items: [item])))
        #expect(haiku.streamCount == 0, "no model ran")
        #expect(events.first == .waiting)
        let ghosts = events.compactMap { event -> UUID? in
            if case let .ghost(id) = event {
                id
            } else {
                nil
            }
        }
        #expect(ghosts.count == 1)
        guard case let .finished(line)? = events.last else {
            Issue.record("no reply: \(events)")
            return
        }
        #expect(line.lowercased().contains("call the bank"))
        // The task is done as a pending row (Undo within the window), by its id.
        #expect(r.engine.store.value("isDone", of: task) == .bool(true))
        let record = try #require(r.engine.history(limit: 1).first)
        #expect(record.state == .pending && record.id == ghosts.first)
    }

    @Test func aPrivateThingIsDoneByItsIDAndNeverNamed() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [])
        let r = try helper.rig([.haiku: haiku])
        let task = try makeTask(r, "Call the bank")
        // The screen shows a label; the call carries the id.
        let item = ElementItem(id: task.id, kind: "task", name: "Private task", isPrivate: true)
        let events = await helper.collect(r.run.ask("done", frame: frame("bridge", items: [item])))
        #expect(r.engine.store.value("isDone", of: task) == .bool(true))
        #expect(haiku.streamCount == 0)
        guard case let .finished(line)? = events.last else {
            Issue.record("no reply: \(events)")
            return
        }
        #expect(!line.lowercased().contains("bank"))
    }

    @Test func openThisIsHandedToTheHostAndWritesNothing() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [])
        let r = try helper.rig([.haiku: haiku])
        let task = try makeTask(r, "Pack the charger")
        let before = r.engine.history(limit: 100).count
        let item = ElementItem(id: task.id, kind: "task", name: "Pack the charger")
        let events = await helper.collect(r.run.ask("open this", frame: frame("bridge", items: [item])))
        let shells = events.compactMap { event -> ShellIntent? in
            if case let .shell(intent) = event {
                intent
            } else {
                nil
            }
        }
        #expect(shells.count == 1 && shells.first?.call == "openItem" && shells.first?.object == task.id)
        #expect(events.last == .finished("Opening Pack the charger."))
        #expect(r.engine.history(limit: 100).count == before && haiku.streamCount == 0)
        let back = await helper.collect(r.run.ask("go back", frame: frame("bridge", items: [item])))
        #expect(back.contains(.shell(ShellIntent(call: "goBack"))))
    }

    // MARK: Through the model

    @Test func anOpenAskGetsTheFramesFragmentsAndOnlyTheScreensTools() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Two tasks.")]])
        let sonnet = ScriptedBrain(.sonnet, rounds: [[.text("Two tasks.")]])
        let r = try helper.rig([.haiku: haiku, .sonnet: sonnet])
        let task = try makeTask(r, "Call the bank")
        let item = ElementItem(id: task.id, kind: "task", name: "Call the bank",
                               facts: [ElementFact("due Thursday")])
        let events = await helper.collect(r.run.ask(
            "what is next for this and what else is on",
            frame: frame("bridge", items: [item])
        ))
        #expect(events.last == .finished("Two tasks."))
        let seen = try #require((haiku.requestsSeen + sonnet.requestsSeen).first)
        let text = seen.messages.flatMap(\.content).compactMap { piece -> String? in
            if case let .text(text) = piece {
                text
            } else {
                nil
            }
        }.joined(separator: " ")
        #expect(text.contains("Where: Bridge") && text.contains("Call the bank") && !text.contains("On screen"))
        let names = Set(seen.tools.map(\.name))
        #expect(names.contains("completeTask") && names.contains("query") && names.contains(TessOpenTool.name))
        // Only what fits the screen: no cooking, no workout, and never money.
        #expect(!names.contains("startCooking") && !names.contains("startWorkout") && !names.contains("logSpend"))
        #expect(names.count <= ToolPicker.maxTools)
    }

    @Test func aShellCallFromTheModelIsHandedToTheHost() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [
            [helper.use("t1", "openItem", #"{"item":"o1"}"#)], [.text("Opened.")],
        ])
        let r = try helper.rig([.haiku: haiku])
        let task = try makeTask(r, "Pack the charger")
        let item = ElementItem(id: task.id, kind: "task", name: "Pack the charger")
        let events = await helper.collect(r.run.ask("could you bring up the thing I mean please now",
                                                    frame: frame("bridge", items: [item])))
        let shells = events.compactMap { event -> ShellIntent? in
            if case let .shell(intent) = event {
                intent
            } else {
                nil
            }
        }
        #expect(shells.first?.call == "openItem" && shells.first?.object == task.id)
        #expect(events.last == .finished("Opened."))
    }

    // MARK: The new tools

    @Test func theNewToolsWrapEngineActionsByIDOrName() throws {
        let r = try helper.rig([:])
        let engine = r.engine
        // checkListItem by name and by id
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        let first = try engine.perform(AddListItem(list: list.id, text: "Passport"), by: .user).output
        let second = try engine.perform(AddListItem(list: list.id, text: "Charger"), by: .user).output
        _ = try TessTools.run("checkListItem", arguments: Data(#"{"item":"passport"}"#.utf8), engine: engine)
        #expect(engine.store.value("isDone", of: first) == .bool(true))
        _ = try TessTools.run(
            "checkListItem",
            arguments: Data(#"{"item":"\#(second.id.uuidString)"}"#.utf8),
            engine: engine
        )
        #expect(engine.store.value("isDone", of: second) == .bool(true))
        // logSpend works on the phone's tool list and is not in Claude's.
        _ = try TessTools.run("logSpend", arguments: Data(#"{"amount":12.5,"note":"lunch"}"#.utf8), engine: engine)
        let names = try #require(JSONSerialization.jsonObject(with: TessTools.definitionsJSON()) as? [[String: Any]])
            .compactMap { $0["name"] as? String }
        #expect(!names.contains("logSpend") && names.contains("checkListItem") && names.contains("startWorkout"))
        #expect(TessTools.tool(named: "logSpend")?.deviceOnly == true)
        #expect(TessTools.claudeTools.allSatisfy { !$0.deviceOnly })
        #expect(throws: TessToolError.self) {
            try TessTools.run("startWorkout", arguments: Data(#"{"routine":"nothing like it"}"#.utf8), engine: engine)
        }
    }

    @Test func theProposedListShrinksToWhatStillHasNoAction() {
        let real = Set(TessTools.all.map(\.name)).union([TessOpenTool.name])
        #expect(ElementCatalog.proposed.isDisjoint(with: real))
        #expect(ElementCatalog.proposed == [
            "pinNote",
            "rainAlert",
            "restDay",
            "tendRoutine",
            "plantRoutine",
            "pauseRoutine",
        ])
    }
}
