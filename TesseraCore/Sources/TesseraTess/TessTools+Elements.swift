import Foundation
import TesseraCore

/// The tools the screen's places offer (docs/ai/harness/elements.md): each wraps an engine action that exists. A bound
/// call names its object by id, so a private thing (shown as its label) is still the right row.
@MainActor
extension TessTools {
    static var checkListItem: Tool {
        Tool(name: "checkListItem", description: "Check off an item on a list",
             input: .object([("item", .string("The item, by name"))]))
        { args, call in
            let item = try call.listItem(named: args.string("item"))
            return try [call.perform(CheckListItem(item: item.id, time: call.now))]
        }
    }

    static var startWorkout: Tool {
        Tool(name: "startWorkout", description: "Start a workout from a routine",
             input: .object([("routine", .string("The routine, by name"))]))
        { args, call in
            let routine = try call.routine(named: args.string("routine"))
            return try [call.perform(StartRoutine(routine: routine.id, time: call.now))]
        }
    }

    static var startCooking: Tool {
        Tool(name: "startCooking", description: "Start cooking a saved recipe",
             input: .object([("recipe", .string("The recipe, by name")),
                             ("serves", .nullable(.integer("How many it serves, if said")))]))
        { args, call in
            let recipe = try call.recipe(named: args.string("recipe"))
            return try [call.perform(StartCooking(recipe: recipe.id, serves: args["serves"] as? Int, time: call.now))]
        }
    }

    /// Money, on the phone's own rungs only: Claude is never given this tool.
    static var logSpend: Tool {
        Tool(name: "logSpend", description: "Log a spend",
             input: .object([("amount", .number("The amount")),
                             ("note", .nullable(.string("What it was for")))]), deviceOnly: true)
        { args, call in
            let amount = try args.number("amount")
            guard amount > 0, amount.isFinite else { throw TessToolError("amount isn't a number") }
            return try [call.perform(LogSpend(amount: amount, note: args["note"] as? String, spentAt: call.now))]
        }
    }

    /// The sink (sheet 388): dishes from a meal not cooked here ("I used three more plates"). A cook adds its own
    /// load, so this is only for what he names; nothing is guessed.
    static var addDishes: Tool {
        Tool(name: "addDishes", description: "Put dishes in the sink that a cook here didn't, e.g. 3 more plates",
             input: .object([("count", .integer("How many dishes, as he said")),
                             ("label", .nullable(.string("What they were from, e.g. Lunch")))]))
        { args, call in
            let count = try Int(args.number("count"))
            guard (1 ... maxDishes).contains(count) else { throw TessToolError("count must be 1 to \(maxDishes)") }
            let label = (args["label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return try [call.perform(AddDishes(count: count, label: label?.isEmpty == false ? label : nil,
                                               at: call.now))]
        }
    }

    /// The most dishes one `addDishes` puts in: past it a misheard number would read as hours at the sink.
    static let maxDishes = 50

    /// "I did the dishes": every open load is washed at once, as one ghost with Undo.
    static var washDishes: Tool {
        Tool(name: "washDishes", description: "Mark every dish in the sink washed", input: .object([])) { _, call in
            guard !Sink.openLoads(in: call.store).isEmpty else {
                throw TessToolAnswer(line: "The sink is clear")
            }
            return try [call.perform(WashDishes(at: call.now))]
        }
    }
}

@MainActor
extension TessTools {
    static var pinNote: Tool {
        Tool(name: "pinNote", description: "Keep a note or a list at the top of the Log, or let it go",
             input: .object([("note", .string("The note or list, by name")),
                             (
                                 "pinned",
                                 .nullable(.boolean("Keep it up top or let it go; the opposite of now when left out"))
                             )])) { args, call in
            let target = try call.noteOrList(named: args.string("note"))
            return try [call.perform(SetPinned(object: target.id, pinned: args["pinned"] as? Bool))]
        }
    }

    static var rainAlert: Tool {
        Tool(name: "rainAlert", description: "Turn the rain alert on or off",
             input: .object([("on", .nullable(.boolean("On or off; on when left out"))),
                             ("leadMinutes", .nullable(.integer("Minutes before rain, 30 when left out")))]))
        { args, call in
            try [call.perform(SetRainAlert(on: args["on"] as? Bool, leadMinutes: args["leadMinutes"] as? Int))]
        }
    }

    static var restDay: Tool {
        Tool(name: "restDay", description: "Take today as a rest day", input: .object([])) { _, call in
            try [call.perform(TakeRest(scope: .training, from: call.now, until: call.now))]
        }
    }

    static var tendRoutine: Tool {
        Tool(name: "tendRoutine", description: "Mark a routine done for today without a workout",
             input: .object([("routine", .string("The routine, by name"))]))
        { args, call in
            let routine = try call.routine(named: args.string("routine"))
            return try [call.perform(TendRoutine(routine: routine.id, at: call.now))]
        }
    }

    static var plantRoutine: Tool {
        Tool(name: "plantRoutine", description: "Start a new routine, like a daily habit",
             input: .object([("name", .string("What it is, e.g. Journal")),
                             ("cadence", .nullable(.choice(["day", "week", "month"], "How often; day when left out"))),
                             ("weekdays", .nullable(.string("Days, 1 Sunday to 7 Saturday, comma separated")))]))
        { args, call in
            try [call.perform(PlantRoutine(name: args.string("name"), cadence: args["cadence"] as? String,
                                           weekdays: args["weekdays"] as? String))]
        }
    }

    static var pauseRoutine: Tool {
        Tool(name: "pauseRoutine", description: "Pause a routine, or resume one that is paused",
             input: .object([("routine", .string("The routine, by name")),
                             ("days", .nullable(.integer("How many days to pause; open when left out"))),
                             ("resume", .nullable(.boolean("True to resume it")))]))
        { args, call in
            let routine = try call.routine(named: args.string("routine"))
            if args["resume"] as? Bool == true {
                return try [call.perform(ResumeRoutine(routine: routine.id, at: call.now))]
            }
            // "For a week" is today plus 6: the pause holds that many days, today included.
            let until = (args["days"] as? Int).flatMap { $0 > 0 ? call.calendar.date(
                byAdding: .day,
                value: $0 - 1,
                to: call.now
            ) : nil }
            return try [call.perform(TakeRest(scope: .routine, routine: routine.id, from: call.now, until: until))]
        }
    }
}

@MainActor
extension TessTools.Call {
    /// A note or a list by id, else by title (exactly one match, never a private one by name).
    func noteOrList(named name: String) throws -> ObjectRecord {
        if let id = UUID(uuidString: name) {
            // An id of the wrong class is no note or list.
            if let note = object(id: name, of: .note) ?? object(id: name, of: .list) {
                return note
            }
            throw TessToolError("no note or list called \(name)")
        }
        let query = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let pool = [SystemCatalog.Key.note, .list].compactMap { engine.classes[$0] }.flatMap { store.objects(of: $0) }
            .filter { !$0.isDeleted && !TessTools.isPrivateForClaude($0, store: store, classes: engine.classes) }
        let exact = pool.filter { $0.title.lowercased() == query }
        if exact.count == 1, let match = exact.first {
            return match
        }
        let words = query.split(separator: " ")
        let loose = pool.filter { item in words.allSatisfy { item.title.lowercased().contains($0) } }
        guard loose.count == 1, let match = loose.first else {
            throw TessToolError(loose.isEmpty ? "no note or list called \(name)" : "more than one like \(name)")
        }
        return match
    }

    /// An object of a class by id, for a bound call. Nil when the text is not an id of a live object of that class.
    func object(id text: String, of key: SystemCatalog.Key) -> ObjectRecord? {
        guard let id = UUID(uuidString: text), let object = store.object(id: id), !object.isDeleted,
              let classDef = object.classDef, let wanted = engine.classes[key],
              ClassResolver.isSubclass(classDef, of: wanted) else { return nil }
        return object
    }

    /// An unchecked list item by id, else by title (exactly one match).
    func listItem(named name: String) throws -> ObjectRecord {
        if let byID = object(id: name, of: .listItem) {
            return byID
        }
        guard let itemClass = engine.classes[.listItem] else { throw TessToolError("no items") }
        let query = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let open = store.objects(of: itemClass).filter {
            !$0.isDeleted && store.value("isDone", of: $0) != .bool(true)
                && !TessTools.isPrivateForClaude($0, store: store, classes: engine.classes)
        }
        let exact = open.filter { $0.title.lowercased() == query }
        if exact.count == 1, let match = exact.first {
            return match
        }
        let words = query.split(separator: " ")
        let loose = open.filter { item in words.allSatisfy { item.title.lowercased().contains($0) } }
        guard loose.count == 1, let match = loose.first else {
            throw TessToolError(loose.isEmpty ? "no open item called \(name)" : "more than one item like \(name)")
        }
        return match
    }

    /// A routine by id, else by name (exactly one).
    func routine(named name: String) throws -> ObjectRecord {
        if let byID = object(id: name, of: .routine) {
            return byID
        }
        guard let routineClass = engine.classes[.routine] else { throw TessToolError("no routines") }
        let query = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let routines = store.objects(of: routineClass).filter {
            !$0.isDeleted && !TessTools.isPrivateForClaude($0, store: store, classes: engine.classes)
        }
        let exact = routines.filter { $0.title.lowercased() == query }
        if exact.count == 1, let match = exact.first {
            return match
        }
        let words = query.split(separator: " ")
        let loose = routines.filter { item in words.allSatisfy { item.title.lowercased().contains($0) } }
        guard loose.count == 1, let match = loose.first else {
            throw TessToolError(loose.isEmpty ? "no routine called \(name)" : "more than one routine like \(name)")
        }
        return match
    }

    /// A recipe by id, else by name.
    func recipe(named name: String) throws -> ObjectRecord {
        if let byID = object(id: name, of: .recipe) {
            return byID
        }
        guard let recipe = grammar.recipe(named: name),
              !TessTools.isPrivateForClaude(recipe, store: store, classes: engine.classes)
        else { throw TessToolError("no recipe called \(name)") }
        return recipe
    }
}
