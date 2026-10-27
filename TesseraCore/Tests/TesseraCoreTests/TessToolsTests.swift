import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Tess model layer T2: the shared, name-resolving tools.
@MainActor
@Suite(.oldWalls)
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
                                              "createRecipe", "query", "startShop", "cookTogether",
                                              "setServeTime", "checkListItem", "startWorkout", "startCooking",
                                              "logSpend", "pinNote", "rainAlert", "restDay", "tendRoutine",
                                              "plantRoutine",
                                              "pauseRoutine", "rehearse"])

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
            _ = try call(
                "query",
                #"{"from":["notes"],"during":{"range":"thisWeek","field":null},"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#,
                engine
            )
            Issue.record("query should answer, not log")
        } catch let answer as TessToolAnswer {
            #expect(answer.line == "1 note this week.")
        }
        // CA6 (Research 145): only allow-listed classes count; his own classes (a spend, his weight) and Tess's never.
        store.createClass(name: "Spend", parent: nil)
        for from in ["spend", "settings", "tess memory", "tess call"] {
            #expect(throws: TessToolError.self, "\(from)") {
                try call(
                    "query",
                    #"{"from":["\#(from)"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#,
                    engine
                )
            }
        }
        #expect(throws: TessToolError.self) {
            try call("logSet", #"{"exercise":"underwater basket weaving","weight":1,"reps":1,"sets":1,"unit":"kg"}"#,
                     engine)
        }
    }

    @Test func queryCountSkipsPrivateObjects() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        try engine.perform(CreateNote(body: "the wifi password is hunter2zebra"), by: .user)
        try engine.perform(CreateTask(title: "Buy lemons"), by: .user)
        try engine.perform(CreateTask(title: "Weigh in 82.4 kg"), by: .user)
        try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\n1. Fry."), by: .user)
        try engine.perform(CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\n1. Bake."), by: .user)
        for (from, line) in [("notes", "1 note."), ("tasks", "1 task."), ("recipes", "1 recipe.")] {
            do {
                _ = try call(
                    "query",
                    #"{"from":["\#(from)"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#,
                    engine
                )
                Issue.record("query should answer, not log")
            } catch let answer as TessToolAnswer {
                #expect(answer.line == line, "\(from): \(answer.line)")
            }
        }
    }

    @Test func queryCountSkipsPrivateListsItemsRoutinesAndCooks() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        func count(_ from: String) throws -> Int {
            do {
                _ = try call(
                    "query",
                    #"{"from":["\#(from)"],"during":null,"where":[],"group":null,"agg":{"kind":"count","field":null},"sort":null,"limit":null}"#,
                    engine
                )
            } catch let answer as TessToolAnswer {
                return Int(answer.line.prefix { $0.isNumber }) ?? -1
            }
            return -1
        }
        let before = try (count("lists"), count("list items"), count("routines"), count("cooks"))
        // Lists and items: one plain and one private of each.
        let plainList = try engine.perform(CreateList(name: "Errands"), by: .user).output
        let secretList = try engine.perform(CreateList(name: "Lexapro refills"), by: .user).output
        try engine.perform(AddListItem(list: plainList.id, text: "Pasta night"), by: .user)
        try engine.perform(AddListItem(list: plainList.id, text: "take melatonin"), by: .user)
        try engine.perform(AddListItem(list: secretList.id, text: "Walk"), by: .user)
        // Routines.
        try engine.perform(CreateRoutine(title: "Push Day Z"), by: .user)
        try engine.perform(CreateRoutine(title: "Knee rehab day"), by: .user)
        // A finished cook of a plain recipe and a running cook of a private one.
        let tacos = try engine.perform(CreateRecipe(text: "Tacos\nIngredients\n2 onions\nMethod\n1. Fry."), by: .user)
            .output
        let secret = try engine.perform(
            CreateRecipe(text: "Melatonin lasagna\nIngredients\n2 onions\nMethod\n1. Bake."), by: .user
        ).output
        let plainCook = try engine.perform(StartCooking(recipe: tacos.id), by: .user).output
        try engine.perform(FinishCooking(cook: plainCook.id), by: .user)
        try engine.perform(StartCooking(recipe: secret.id), by: .user)
        try #expect(count("lists") == before.0 + 1)
        try #expect(count("list items") == before.1 + 1)
        try #expect(count("routines") == before.2 + 1)
        try #expect(count("cooks") == before.3 + 1)
    }

    @Test func aTimeWithNoZoneIsReadInHisZone() throws {
        // QA T1: "15:00" from a model with no offset is 3 pm where he is, not 3 pm UTC (8 am in Los Angeles).
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let local = try TessTools.run(
            "createTask",
            arguments: Data(#"{"title":"Call the bank","startsAt":"2026-10-21T15:00:00"}"#.utf8),
            engine: engine,
            calendar: calendar
        )
        let taskID = try #require(local.first?.objectIDs.first)
        let task = try #require(store.object(id: taskID))
        let expected = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 15)))
        #expect(store.value("startsAt", of: task) == .date(expected))
        // With an offset it reads as written.
        let utc = try TessTools.run(
            "createTask",
            arguments: Data(#"{"title":"Call mom","startsAt":"2026-10-21T15:00:00Z"}"#.utf8),
            engine: engine,
            calendar: calendar
        )
        let momID = try #require(utc.first?.objectIDs.first)
        let mom = try #require(store.object(id: momID))
        #expect(store.value("startsAt", of: mom) == .date(Date(timeIntervalSince1970: 1_792_594_800)))
    }

    @Test func claudeGetsStrictSchemas() throws {
        let data = try TessTools.definitionsJSON()
        let tools = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        // Claude's list: every tool but the device-only ones (logSpend is money).
        #expect(tools.count == 22 && !tools.contains { $0["name"] as? String == "logSpend" }
            && !tools.contains { $0["name"] as? String == "rehearse" })
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
            for branch in schema["anyOf"] as? [[String: Any]] ?? [] {
                check(branch, path: path + "|")
            }
            // The API refuses a schema whose enum holds a value the declared type doesn't allow (a nullable choice is
            // an anyOf of the choice and null, never a type union).
            if let values = schema["enum"] as? [Any] {
                let declared = (schema["type"] as? [String]) ?? [schema["type"] as? String ?? "string"]
                for value in values {
                    let kind = value is NSNull ? "null" : value is String ? "string" : "other"
                    #expect(declared.contains(kind), "\(path) enum value \(value) does not fit \(declared)")
                }
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

extension TessToolsTests {
    /// The API's strict-tool limits (live run, Oct 27): at most 20 strict tools, 16 union parameters, and a grammar
    /// that
    /// stays small enough. The request keeps the first tools that fit under a safe budget strict and sends the rest
    /// plain.
    @Test func strictToolsStayUnderTheApiBudget() throws {
        let tools = try TessTools.claudeTools.map {
            try ToolSpec(name: $0.name, description: $0.description,
                         schema: JSONSerialization.data(withJSONObject: $0.input.json), strict: true)
        }
        let request = BrainRequest(messages: [BrainMessage(.user, text: "hi")], tools: tools)
        let data = try ClaudeBrain.body(for: request, model: .haiku, stream: false)
        let body = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let sent = try #require(body["tools"] as? [[String: Any]])
        let strict = sent.filter { $0["strict"] as? Bool == true }
        #expect(strict.count <= ClaudeBrain.maxStrictTools && !strict.isEmpty)
        let unions = strict.reduce(0) { $0 + ClaudeBrain.unionCount(in: $1["input_schema"] as Any) }
        #expect(unions <= ClaudeBrain.maxStrictUnions)
        #expect(sent.count == tools.count)
    }
}
