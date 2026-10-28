import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The sink through Tess (sheet 388): "I used three more plates" puts a load in, "I did the dishes" washes every open
/// load as one ghost with Undo, and a clear sink is said, not written.
@MainActor
@Suite(.oldWalls)
struct SinkToolsTests {
    func engine() throws -> ActionEngine {
        let store = ObjectStore.open(inMemory: true)
        return try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    func call(_ name: String, _ json: String, _ engine: ActionEngine) throws -> [OpRecord] {
        try TessTools.run(name, arguments: Data(json.utf8), engine: engine)
    }

    @Test func dishesHeNamesGoInAsAPendingLoad() throws {
        let engine = try engine()
        let added = try call("addDishes", #"{"count":3,"label":"Breakfast"}"#, engine)
        #expect(added.count == 1 && added.first?.action == "addDishes" && added.first?.state == .pending)
        let unlabeled = try call("addDishes", #"{"count":2,"label":"  "}"#, engine)
        #expect(unlabeled.first?.action == "addDishes")
        for count in [0, 51] {
            #expect(throws: TessToolError.self) {
                try call("addDishes", "{\"count\":\(count),\"label\":null}", engine)
            }
        }
        #expect(try call("addDishes", #"{"count":50,"label":null}"#, engine).count == 1)
    }

    @Test func washingIsOneGhostAndAClearSinkIsSaid() throws {
        let engine = try engine()
        do {
            _ = try call("washDishes", "{}", engine)
            Issue.record("a clear sink wrote something")
        } catch let answer as TessToolAnswer {
            #expect(answer.line == "The sink is clear")
        }
        #expect(engine.history().isEmpty)
        _ = try Sink.seedSample(store: engine.store, classes: engine.classes, now: .now)
        let washed = try call("washDishes", "{}", engine)
        #expect(washed.count == 1 && washed.first?.action == "washDishes" && washed.first?.state == .pending)
    }

    @Test func theGalleyOffersThemAndTheRoomMayCallThem() {
        let words = ElementCatalog.calls(room: "galley", place: .actionWord).map(\.name)
        let rail = ElementCatalog.calls(room: "galley", place: .keystone).map(\.name)
        for name in ["washDishes", "addDishes"] {
            #expect(words.contains(name) && rail.contains(name))
            #expect(AgentSpec.kitchen.tools.contains(name) && TessTools.writeNames.contains(name))
            #expect(TessTools.tool(named: name)?.deviceOnly == false)
        }
        // Only the sink: "wash the rice", "I used the last eggs" and "put the pan in the sink" name neither.
        let phrases = ElementCatalog.calls(room: "galley", place: .actionWord)
            .filter { ["washDishes", "addDishes"].contains($0.name) }.flatMap(\.phrases)
        #expect(!phrases.contains { ["wash", "used", "dirty", "in the sink"].contains($0) })
    }
}
