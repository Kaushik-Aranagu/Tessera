import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The strict `patchRoom` tool: the model's output is shape-checked, runs through the patcher, and a refusal goes back
/// to it as a plain line.
@MainActor
struct RoomToolTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        try RoomSample.seedPlants(store: store, classes: classes)
    }

    func call(_ json: String) throws -> [OpRecord] {
        try TessTools.run("patchRoom", arguments: Data(json.utf8), engine: engine)
    }

    func step(_ op: String, id: String = "", kind: String = "", place: String = "", props: String = "",
              bind: String = "", trait: String = "", value: String = "", reach: String = "", index: Int = -1) -> String
    {
        let fields: [String: Any] = ["op": op, "id": id, "kind": kind, "place": place, "props": props, "bind": bind,
                                     "trait": trait, "value": value, "reach": reach, "index": index]
        let data = (try? JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    func args(_ say: String, _ steps: [String]) -> String {
        #"{"room":"Chart room","say":"\#(say)","ops":[\#(steps.joined(separator: ","))]}"#
    }

    @Test func theSchemaIsStrictClosedAndSmallEnoughToStayStrict() throws {
        let tool = try #require(TessTools.tool(named: "patchRoom"))
        let json = tool.input.json
        #expect(json["additionalProperties"] as? Bool == false)
        #expect(ClaudeBrain.unionCount(in: json) == 0, "no unions: a strict schema it can afford")
        let items = ((json["properties"] as? [String: Any])?["ops"] as? [String: Any])?["items"] as? [String: Any]
        let required = Set(items?["required"] as? [String] ?? [])
        #expect(required == Set((items?["properties"] as? [String: Any])?.keys.map(\.self) ?? []))
        #expect(!TessTools.claudeTools.filter { $0.name == "patchRoom" }.isEmpty, "Claude is given it")
    }

    @Test func aSentenceBecomesOnePendingGhostAsTess() throws {
        let records = try call(args("Plants, set", [
            step("add", id: "title", kind: "title", place: "title", props: #"{"text":"Plants"}"#),
            step("add", id: "line", kind: "line", place: "switcher", props: #"{"text":"{count} plants"}"#,
                 bind: "Plant"),
            step("look", trait: "motion", value: "calm"),
        ]))
        #expect(records.count == 1 && records[0].state == .pending && records[0].action == "patchRoom")
        let room = try #require(RoomBook(store: store, classes: classes).room(named: "Chart room"))
        #expect(RoomBook(store: store, classes: classes).document(of: room).parts.map(\.id) == ["title", "line"])
    }

    @Test func aRefusalGoesBackToTheModelAsAPlainLine() throws {
        do {
            _ = try call(args("Box", [step("add", id: "b", kind: "box", place: "widget")]))
            Issue.record("a box is refused")
        } catch let error as TessToolError {
            #expect(error.description == "No boxes in this house. Bigger numbers instead?")
        }
        #expect(RoomBook(store: store, classes: classes).room(named: "Chart room") == nil)
    }

    @Test func aKitMissIsQueuedNotRefusedAndMoneyIsNeverGranted() throws {
        let queued = try call(args("Ring", [step("add", id: "r", kind: "ring", place: "keystone")]))
        #expect(queued.first?.action == "queueRoomPart")
        do {
            _ = try call(args("Money", [step("grant", reach: "write Pool.name")]))
            Issue.record("money is refused")
        } catch let error as TessToolError {
            #expect(error.description == RoomPatchValidator.moneyLine)
        }
    }

    @Test func badPropsAreReadAsAnErrorLine() throws {
        #expect(throws: TessToolError.self) {
            try call(args("x", [step("add", id: "t", kind: "title", place: "title", props: "{not json")]))
        }
        #expect(throws: TessToolError.self) { try call(args("x", [])) }
    }
}
