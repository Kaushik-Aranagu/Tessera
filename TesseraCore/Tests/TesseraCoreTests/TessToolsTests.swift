import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Tess model layer T2: the shared, name-resolving tools.
@MainActor
struct TessToolsTests {
    func call(_ name: String, _ json: String, _ engine: ActionEngine) throws -> [OpRecord] {
        try TessTools.run(name, arguments: Data(json.utf8), engine: engine)
    }

    @Test func eachToolPerformsItsSampleAsAPendingGhost() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        #expect(TessTools.all.map(\.name) == ["logSet", "createTask", "completeTask", "rescheduleTask",
                                              "addGroceries", "addToList", "createList", "createNote",
                                              "createRecipe", "answerQuery", "startShop"])

        let set = try call("logSet", #"{"exercise":"bench","weight":80,"reps":8,"sets":1,"unit":"kg"}"#, engine)
        #expect(set.first?.action == "logExercise" && set.first?.state == .pending)

        let recipe = try call("createRecipe", #"""
        {"title":"Carbonara","serves":2,"totalMinutes":25,
         "ingredients":[{"amount":"200","unit":"g","name":"spaghetti"},{"amount":"3","unit":null,"name":"eggs"}],
         "steps":["Boil the spaghetti for 10 minutes.","Toss with the eggs."]}
        """#, engine)
        let recipeObject = try #require(RecipeBook(store: store, classes: classes).recipes().first)
        #expect(recipe.count == 1 && recipeObject.title == "Carbonara")
        #expect(RecipeBook(store: store, classes: classes).lines(of: recipeObject).count == 2)

        let task = try call("createTask",
                            #"{"title":"Cook carbonara","startsAt":"2026-10-16T18:00:00Z","about":["carbonara"]}"#,
                            engine)
        let taskObject = try #require(store.object(id: task.first?.objectIDs.first ?? UUID()))
        #expect(store.linkedObjects("about", of: taskObject).map(\.id) == [recipeObject.id])
        _ = try call("createTask", #"{"title":"Call the dentist","startsAt":null,"about":[]}"#, engine)
        // Pending ghosts aren't committed yet; commit them so later tools see them.
        for record in engine.history() where record.state == .pending {
            try engine.commit(record)
        }

        let moved = try call("rescheduleTask", #"{"task":"dentist","startsAt":"2026-10-17T09:00:00Z"}"#, engine)
        #expect(moved.first?.action == "moveTask")
        let done = try call("completeTask", #"{"task":"call the dentist"}"#, engine)
        #expect(done.first?.action == "setTaskDone")
        #expect(throws: TessToolError.self) { try call("completeTask", #"{"task":"nothing like this"}"#, engine) }

        let groceries = try call("addGroceries", #"{"lines":["milk","2 lemons"]}"#, engine)
        #expect(groceries.first?.action == "addGroceries")

        let created = try call("createList", #"""
        {"name":"Packing","items":[{"text":"Socks","section":"Clothes","done":false},
                                   {"text":"Charger","section":null,"done":true}]}
        """#, engine)
        #expect(created.map(\.action) == ["createList", "addListItem", "addListItem", "checkListItem"])
        for record in engine.history() where record.state == .pending {
            try engine.commit(record)
        }
        let added = try call("addToList", #"{"list":"packing","items":[{"text":"Book","section":null,"done":false}]}"#,
                             engine)
        #expect(added.count == 1)
        let packing = try #require(ListContents(store: store, classes: classes).lists().first { $0.title == "Packing" })
        #expect(ListContents(store: store, classes: classes).items(of: packing).map(\.text) == ["Socks", "Charger",
                                                                                                "Book"])

        let note = try call("createNote", #"{"body":"@Carbonara needed more pepper"}"#, engine)
        #expect(note.first?.action == "createNote")

        // Read-only: an answer, no ops.
        do {
            _ = try call("answerQuery", #"{"from":"notes","during":"this week"}"#, engine)
            Issue.record("answerQuery should answer, not log")
        } catch let answer as TessToolAnswer {
            #expect(answer.line == "1 note.")
        }
        // CA6 (Research 145): only allow-listed classes count; his own classes (a spend, his weight) and Tess's never.
        store.createClass(name: "Spend", parent: nil)
        for from in ["spend", "settings", "tess memory", "tess call"] {
            #expect(throws: TessToolError.self, "\(from)") {
                try call("answerQuery", #"{"from":"\#(from)","during":null}"#, engine)
            }
        }
        #expect(throws: TessToolError.self) {
            try call("logSet", #"{"exercise":"underwater basket weaving","weight":1,"reps":1,"sets":1,"unit":"kg"}"#,
                     engine)
        }
    }

    @Test func claudeGetsStrictSchemas() throws {
        let data = try TessTools.definitionsJSON()
        let tools = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        #expect(tools.count == 11)
        func check(_ schema: [String: Any], path: String) {
            if schema["type"] as? String == "object" {
                #expect(schema["additionalProperties"] as? Bool == false, "\(path) must be closed")
                let properties = schema["properties"] as? [String: [String: Any]] ?? [:]
                #expect(Set(schema["required"] as? [String] ?? []) == Set(properties.keys), "\(path) all required")
                for (key, value) in properties {
                    check(value, path: path + "." + key)
                }
            }
            if let items = schema["items"] as? [String: Any] {
                check(items, path: path + "[]")
            }
        }
        for tool in tools {
            #expect(tool["strict"] as? Bool == true)
            check(tool["input_schema"] as? [String: Any] ?? [:], path: tool["name"] as? String ?? "")
        }
        let createTask = try #require(tools.first { $0["name"] as? String == "createTask" })
        let startsAt = (createTask["input_schema"] as? [String: Any])
            .flatMap { $0["properties"] as? [String: [String: Any]] }?["startsAt"]
        #expect(startsAt?["type"] as? [String] == ["string", "null"])
    }

    @Test func theOnDeviceModelGetsTheSameTools() throws {
        for tool in TessTools.all {
            _ = try GenerationSchemaCheck.make(tool)
        }
    }

    @Test func aListWithNoItemsAndAFailedCallLeaveNoGhost() throws {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        // T2-1: the most common list call has no items.
        let records = try call("createList", #"{"name":"Packing","items":[]}"#, engine)
        #expect(records.map(\.action) == ["createList"])
        // A call that fails part-way takes back what it did: the list is made, then an item can't be.
        let before = engine.history().count
        #expect(throws: TessToolError.self) {
            try call("createList", #"{"name":"Films","items":[{"text":"","section":null,"done":false}]}"#, engine)
        }
        #expect(!ListContents(store: store, classes: classes).lists().contains { $0.title == "Films" })
        #expect(engine.history().filter { $0.state == .pending }.count == 1) // only Packing's
        _ = before
        let shop = try call("startShop", "{}", engine)
        #expect(shop.first?.action == "startShop")
    }
}
