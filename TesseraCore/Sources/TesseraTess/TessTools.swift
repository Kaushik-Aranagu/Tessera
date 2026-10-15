import Foundation
import TesseraCore

/// The tools Tess's model routes may call (Tess model layer T2): one list for the on-device model and Claude.
/// Models can't know ids, so every tool takes names ("Bench Press", "Groceries", "dentist") and resolves them here.
/// Each call performs real typed actions as Tess, pending by default, so it lands as a ghost row with undo.
/// Nothing destructive is here, and nothing a system clock should drive.
@MainActor
public enum TessTools {
    /// One tool: its name, what it's for, its input schema, and what it does.
    public struct Tool {
        public let name: String
        public let description: String
        public let input: TessSchema
        let run: @MainActor (_ arguments: [String: Any], _ call: Call) throws -> [OpRecord]
    }

    /// What a tool call runs against.
    @MainActor
    struct Call {
        let engine: ActionEngine
        let grammar: TessGrammar
        let pending: Bool
        let now: Date

        var store: ObjectStore {
            engine.store
        }

        func perform(_ action: some EngineAction) throws -> OpRecord {
            try engine.perform(action, by: .tess, pending: pending).record
        }
    }

    public static var all: [Tool] {
        [logSet, createTask, completeTask, rescheduleTask, addGroceries, addToList, createList, createNote,
         createRecipe, answerQuery, startShop]
    }

    public static func tool(named name: String) -> Tool? {
        all.first { $0.name == name }
    }

    /// Runs a tool call from its JSON arguments. Returns what was logged; throws `TessToolError` with a line the
    /// model can read and correct.
    public static func run(_ name: String, arguments: Data, engine: ActionEngine, pending: Bool = true,
                           now: Date = .now) throws -> [OpRecord]
    {
        guard let tool = tool(named: name) else { throw TessToolError("no tool called \(name)") }
        guard let object = try? JSONSerialization.jsonObject(with: arguments) as? [String: Any] else {
            throw TessToolError("unreadable arguments")
        }
        let call = Call(engine: engine, grammar: TessGrammar(store: engine.store, classes: engine.classes),
                        pending: pending, now: now)
        // A tool that fails part-way takes back what it already did, so no half-done ghost is left behind.
        let mark = engine.history(limit: 1).first?.id
        do {
            return try tool.run(object, call)
        } catch let answer as TessToolAnswer {
            throw answer
        } catch {
            for record in engine.history(limit: 50) {
                if record.id == mark { break }
                if record.state == .pending {
                    _ = try? engine.discard(record)
                } else if record.state != .undone {
                    engine.undo(record)
                }
            }
            throw (error as? TessToolError) ?? TessToolError("\(error)")
        }
    }

    /// Claude's tool definitions, strict: every object closed, every field required (optional ones nullable).
    public static func definitionsJSON() throws -> Data {
        let tools: [[String: Any]] = all.map { tool in
            ["name": tool.name, "description": tool.description, "strict": true, "input_schema": tool.input.json]
        }
        return try JSONSerialization.data(withJSONObject: tools, options: [.sortedKeys])
    }

    // MARK: The tools

    static let unit = TessSchema.choice(["kg", "lb"], "Weight unit")

    static var logSet: Tool {
        Tool(name: "logSet", description: "Log sets of an exercise into today's workout",
             input: .object([
                 ("exercise", .string("The exercise, e.g. Bench Press")),
                 ("weight", .number("Weight per rep")),
                 ("reps", .integer("Reps per set")),
                 ("sets", .integer("How many sets, usually 1")),
                 ("unit", unit),
             ])) { args, call in
            let name = try args.string("exercise")
            guard let exercise = call.grammar.resolveExercise(name) else {
                throw TessToolError("no exercise called \(name)")
            }
            let unit = MassUnit(parsing: args["unit"] as? String ?? "kg") ?? .kilograms
            return try [call.perform(LogExercise(exercise: exercise.id, weight: args.number("weight"),
                                                 reps: args.number("reps"), sets: Int(args.number("sets")),
                                                 unit: unit))]
        }
    }

    static var createTask: Tool {
        Tool(name: "createTask", description: "Add a task, optionally at a time and about things (e.g. a recipe)",
             input: .object([
                 ("title", .string("What to do, verb first")),
                 ("startsAt", .nullable(.string("When, ISO 8601 date-time"))),
                 ("about", .array(.string("A thing it's about, by name"))),
             ])) { args, call in
            let about = (args["about"] as? [String] ?? []).compactMap { call.object(named: $0) }
            return try [call.perform(CreateTask(title: args.string("title"), startsAt: args.date("startsAt"),
                                                about: about.map(\.id)))]
        }
    }

    static var completeTask: Tool {
        Tool(name: "completeTask", description: "Mark a task done",
             input: .object([("task", .string("The task, by name"))]))
        { args, call in
            let task = try call.task(named: args.string("task"))
            return try [call.perform(SetTaskDone(task: task.id))]
        }
    }

    static var rescheduleTask: Tool {
        Tool(name: "rescheduleTask", description: "Move a task to another time",
             input: .object([
                 ("task", .string("The task, by name")),
                 ("startsAt", .string("When, ISO 8601 date-time")),
             ])) { args, call in
            let task = try call.task(named: args.string("task"))
            guard let date = args.date("startsAt") else { throw TessToolError("startsAt isn't a date") }
            return try [call.perform(MoveTask(task: task.id, to: date))]
        }
    }

    static var addGroceries: Tool {
        Tool(name: "addGroceries", description: "Put things on the groceries list",
             input: .object([("lines", .array(.string("One thing, with its amount if said, e.g. 2 lemons")))]))
        {
            args, call in
            let lines = args["lines"] as? [String] ?? []
            guard !lines.isEmpty else { throw TessToolError("nothing to add") }
            return try [call.perform(AddGroceries(lines: lines))]
        }
    }

    static let item = TessSchema.object([
        ("text", .string("The item")),
        ("section", .nullable(.string("A section, if said"))),
        ("done", .boolean("Already done")),
    ])

    static var addToList: Tool {
        Tool(name: "addToList", description: "Add items to a list by its name",
             input: .object([("list", .string("The list, e.g. Packing")), ("items", .array(item))]))
        { args, call in
            let list = try call.list(named: args.string("list"))
            return try call.addItems(args["items"] as? [[String: Any]] ?? [], to: list)
        }
    }

    static var createList: Tool {
        Tool(name: "createList", description: "Make a new list, with items if given",
             input: .object([("name", .string("What the list is")), ("items", .array(item))]))
        { args, call in
            let record = try call.perform(CreateList(name: args.string("name")))
            guard let list = call.store.object(id: record.objectIDs.first ?? UUID()) else { return [record] }
            let items = args["items"] as? [[String: Any]] ?? []
            // "new list packing" with nothing in it yet is fine.
            return items.isEmpty ? [record] : try [record] + call.addItems(items, to: list)
        }
    }

    static var createNote: Tool {
        Tool(name: "createNote", description: "Write a note; @Name links it to a thing",
             input: .object([("body", .string("The note"))]))
        { args, call in
            try [call.perform(CreateNote(body: args.string("body")))]
        }
    }

    static var createRecipe: Tool {
        Tool(name: "createRecipe", description: "Save a recipe",
             input: .object([
                 ("title", .string("The recipe's name")),
                 ("serves", .nullable(.integer("How many it serves"))),
                 ("totalMinutes", .nullable(.integer("Total time in minutes"))),
                 ("ingredients", .array(.object([
                     ("amount", .nullable(.string("e.g. 200, 1/2, 2-3"))),
                     ("unit", .nullable(.string("e.g. g, tbsp, cloves"))),
                     ("name", .string("The ingredient, with prep after a comma")),
                 ]))),
                 ("steps", .array(.string("One step"))),
             ])) { args, call in
            try [call.perform(CreateRecipe(text: TessTools.recipeText(args)))]
        }
    }

    /// The structured recipe written out as text, so the same parser (and its kept source text) reads it.
    static func recipeText(_ args: [String: Any]) throws -> String {
        var lines = try [args.string("title")]
        if let serves = args["serves"] as? Int {
            lines.append("Serves \(serves)")
        }
        if let total = args["totalMinutes"] as? Int {
            lines.append("Total time: \(total) min")
        }
        lines.append("Ingredients")
        for ingredient in args["ingredients"] as? [[String: Any]] ?? [] {
            let parts = [ingredient["amount"] as? String, ingredient["unit"] as? String, ingredient["name"] as? String]
            lines.append(parts.compactMap(\.self).joined(separator: " "))
        }
        lines.append("Method")
        lines += args["steps"] as? [String] ?? []
        return lines.joined(separator: "\n")
    }

    static var startShop: Tool {
        Tool(name: "startShop", description: "Start shopping the groceries list", input: .object([])) { _, call in
            try [call.perform(StartShop(time: call.now))]
        }
    }

    /// Read-only: counts of things over a span, answered on the phone. (The full query AST is M3 slice 4; this is
    /// the first slice of it: count, from one class, during today / this week / this month.)
    static var answerQuery: Tool {
        Tool(name: "answerQuery", description: "Count things in the log; read-only",
             input: .object([
                 ("from", .string("What to count, e.g. workouts, tasks, notes")),
                 ("during", .nullable(.choice(["today", "this week", "this month"], "When"))),
             ])) { args, call in
            let from = try args.string("from")
            guard let classDef = call.store.allClasses().first(where: {
                IngredientLine.key(for: $0.name) == IngredientLine.key(for: from)
            }) else { throw TessToolError("nothing called \(from)") }
            let objects = call.store.objects(of: classDef)
            let calendar = Calendar.current
            let span: Calendar.Component? = switch args["during"] as? String {
            case "today": .day
            case "this week": .weekOfYear
            case "this month": .month
            default: nil
            }
            let count = span.map { span in
                objects.count { calendar.isDate($0.createdAt, equalTo: call.now, toGranularity: span) }
            } ?? objects.count
            throw TessToolAnswer(line: "\(count) \(count == 1 ? classDef.name.lowercased() : from.lowercased()).")
        }
    }
}

// MARK: - Resolving names

@MainActor
extension TessTools.Call {
    /// An open task whose title matches: exactly, else the one containing every word said.
    func task(named name: String) throws -> ObjectRecord {
        let tasks = TaskList(store: store, classes: engine.classes).all().filter { !$0.isDone }
        let query = name.lowercased()
        if let exact = tasks.first(where: { $0.title.lowercased() == query }) {
            return exact.task
        }
        let words = query.split(separator: " ")
        let matches = tasks.filter { item in words.allSatisfy { item.title.lowercased().contains($0) } }
        guard matches.count == 1, let match = matches.first else {
            throw TessToolError(matches.isEmpty ? "no open task called \(name)" : "more than one task like \(name)")
        }
        return match.task
    }

    /// A list by name ("groceries" is the groceries list).
    func list(named name: String) throws -> ObjectRecord {
        let query = name.lowercased().trimmingCharacters(in: .whitespaces)
        let lists = ListContents(store: store, classes: engine.classes).lists()
        guard let list = lists.first(where: { $0.title.lowercased() == query })
            ?? lists.first(where: { $0.title.lowercased().hasPrefix(query) })
        else { throw TessToolError("no list called \(name)") }
        return list
    }

    /// Any thing by name, recipes first ("about" links).
    func object(named name: String) -> ObjectRecord? {
        if let recipe = grammar.recipe(named: name) {
            return recipe
        }
        let query = name.lowercased()
        return store.context.objects.values
            .first { !$0.isDeleted && !$0.isClassObject && $0.title.lowercased() == query }
    }

    func addItems(_ items: [[String: Any]], to list: ObjectRecord) throws -> [OpRecord] {
        var records: [OpRecord] = []
        for item in items {
            guard let text = item["text"] as? String, !text.isEmpty else { continue }
            let record = try perform(AddListItem(list: list.id, text: text, section: item["section"] as? String))
            records.append(record)
            if item["done"] as? Bool == true, let id = record.objectIDs.first {
                try records.append(perform(CheckListItem(item: id)))
            }
        }
        guard !records.isEmpty else { throw TessToolError("no items to add") }
        return records
    }
}

/// A line a model can read and act on ("no task called dentist").
public struct TessToolError: Error, CustomStringConvertible {
    public let description: String

    init(_ description: String) {
        self.description = description
    }
}

/// A read-only tool's answer (no ops): the line to show.
public struct TessToolAnswer: Error {
    public let line: String
}

extension [String: Any] {
    func string(_ key: String) throws -> String {
        guard let value = self[key] as? String, !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TessToolError("\(key) is missing")
        }
        return value
    }

    func number(_ key: String) throws -> Double {
        if let value = self[key] as? Double {
            return value
        }
        if let value = self[key] as? Int {
            return Double(value)
        }
        throw TessToolError("\(key) isn't a number")
    }

    func date(_ key: String) -> Date? {
        guard let text = self[key] as? String else { return nil }
        return (try? Date(text, strategy: .iso8601))
            ?? (try? Date(text, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: false)
                    .timeSeparator(.colon)))
    }
}

// MARK: - Schema

/// A small JSON-schema shape that emits Claude's strict schema and converts to the on-device model's schema, so
/// one definition feeds both routes.
public indirect enum TessSchema: Sendable {
    case string(String)
    case number(String)
    case integer(String)
    case boolean(String)
    case choice([String], String)
    case array(TessSchema)
    case object([(String, TessSchema)])
    case nullable(TessSchema)

    var summary: String {
        switch self {
        case let .string(text), let .number(text), let .integer(text), let .boolean(text), let .choice(_, text): text
        case let .array(item): item.summary
        case .object: ""
        case let .nullable(inner): inner.summary
        }
    }

    /// Strict JSON schema: objects closed, every property required, optional ones as a type union with null.
    public var json: [String: Any] {
        switch self {
        case let .string(text): ["type": "string", "description": text]
        case let .number(text): ["type": "number", "description": text]
        case let .integer(text): ["type": "integer", "description": text]
        case let .boolean(text): ["type": "boolean", "description": text]
        case let .choice(options, text): ["type": "string", "enum": options, "description": text]
        case let .array(item): ["type": "array", "items": item.json]
        case let .object(properties):
            [
                "type": "object", "additionalProperties": false,
                "properties": Dictionary(uniqueKeysWithValues: properties.map { ($0.0, $0.1.json) }),
                "required": properties.map(\.0),
            ]
        case let .nullable(inner):
            inner.json.merging(["type": [inner.json["type"] as? String ?? "string", "null"]]) { _, new in new }
        }
    }
}
