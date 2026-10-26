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
}

@MainActor
extension TessTools.Call {
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
