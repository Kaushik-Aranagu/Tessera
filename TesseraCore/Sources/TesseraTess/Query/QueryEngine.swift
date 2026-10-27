import Foundation
import TesseraCore

/// Runs a `Query` against the store and says the answer in one line. Read only: it never writes, and it sees only
/// the classes `answerQuery` always saw (`TessTools.countable`), minus anything private for Claude. A linked object
/// that is private reads as no value at all. Numbers come from the data: a count is a count, a best is a max.
@MainActor
public enum QueryEngine {
    static let maxRows = 50
    static let defaultListRows = 20
    static let shownRows = 6

    /// A value on the way through a path: a number, text, date, bool, an object or a class.
    enum Value {
        case number(Double)
        case text(String)
        case date(Date)
        case bool(Bool)
        case object(ObjectRecord)
        case classDef(ClassDef)
    }

    // MARK: Run

    public static func run(_ query: Query, engine: ActionEngine, now: Date = .now,
                           calendar: Calendar = .current) throws -> QueryResult
    {
        try validate(query)
        let store = engine.store, classes = engine.classes
        let wanted = try resolveClasses(query.from, engine: engine)
        var seen = Set<UUID>()
        var objects: [ObjectRecord] = []
        for classDef in wanted {
            for object in store.objects(of: classDef) where seen.insert(object.id).inserted
                && !TessTools.isPrivateForClaude(object, store: store, classes: classes)
            {
                objects.append(object)
            }
        }
        var context = Context(engine: engine, now: now, calendar: calendar)
        for predicate in query.predicates {
            let kept = try objects.filter { try matches($0, predicate, &context) }
            objects = kept
        }
        if let during = query.during {
            let window = try interval(during.range, now: now, calendar: calendar)
            objects = try objects.filter { object in
                let path = during.field ?? defaultDateField(of: object, classes: classes)
                return try values(path, of: object, &context).contains { value in
                    if case let .date(date) = value {
                        window.contains(date)
                    } else {
                        false
                    }
                }
            }
        }
        return try answer(query, objects, &context)
    }

    // MARK: Validation

    static func validate(_ query: Query) throws {
        guard !query.from.isEmpty else { throw QueryError("from needs at least one class") }
        guard Query.aggs.contains(query.agg.kind) else {
            throw QueryError("agg must be one of \(Query.aggs.sorted().joined(separator: ", "))")
        }
        if ["sum", "avg", "min", "max", "latest"].contains(query.agg.kind), query.agg.field == nil,
           query.agg.kind != "latest"
        {
            throw QueryError("\(query.agg.kind) needs a field")
        }
        for predicate in query.predicates where !Query.ops.contains(predicate.op) {
            throw QueryError("\(predicate.op) is not an operator I know")
        }
        if let limit = query.limit, !(1 ... maxRows).contains(limit) {
            throw QueryError("limit must be 1 to \(maxRows)")
        }
        if let range = query.during?.range, !isKnownRange(range) {
            throw QueryError("\(range) is not a range I know")
        }
    }

    static func isKnownRange(_ range: String) -> Bool {
        Query.ranges.contains(range) || range.hasPrefix("date:") || range.hasPrefix("month:")
    }

    // MARK: Classes

    /// The classes a `from` names. Only the allow-list: money, body, health and his own kinds are not here.
    static func resolveClasses(_ names: [String], engine: ActionEngine) throws -> [ClassDef] {
        let allowed = TessTools.countable.compactMap { engine.classes[$0] }
        let synonyms: [String: SystemCatalog.Key] = ["item": .listItem, "entry": .exerciseEntry,
                                                     "exercise entry": .exerciseEntry, "dinner": .cook]
        var found: [ClassDef] = []
        for name in names {
            let key = singular(IngredientLine.key(for: name))
            let hit = synonyms[key].flatMap { engine.classes[$0] }
                ?? allowed.first { singular(IngredientLine.key(for: $0.name)) == key }
                ?? allowed.first { closeEnough(singular(IngredientLine.key(for: $0.name)), key) }
            guard let hit, allowed.contains(where: { $0.id == hit.id }) else {
                throw QueryError("nothing called \(name) that I can look up")
            }
            if !found.contains(where: { $0.id == hit.id }) {
                found.append(hit)
            }
        }
        return found
    }

    static func singular(_ key: String) -> String {
        key.hasSuffix("ies") ? String(key.dropLast(3)) + "y"
            : key.hasSuffix("s") && !key.hasSuffix("ss") ? String(key.dropLast()) : key
    }

    /// One letter off, for names of five letters or more ("chili" and "chilli").
    static func closeEnough(_ a: String, _ b: String) -> Bool {
        guard a.count >= 5, b.count >= 5, abs(a.count - b.count) <= 1 else { return false }
        return editDistance(Array(a), Array(b)) <= 1
    }

    static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        var row = Array(0 ... b.count)
        for (i, left) in a.enumerated() {
            var next = [i + 1]
            for (j, right) in b.enumerated() {
                next.append(min(row[j + 1] + 1, next[j] + 1, row[j] + (left == right ? 0 : 1)))
            }
            row = next
        }
        return row[b.count]
    }

    // MARK: Paths and values

    @MainActor struct Context {
        let engine: ActionEngine
        let now: Date
        let calendar: Calendar

        var store: ObjectStore {
            engine.store
        }

        var classes: [SystemCatalog.Key: ClassDef] {
            engine.classes
        }
    }

    static func defaultDateField(of object: ObjectRecord, classes: [SystemCatalog.Key: ClassDef]) -> String {
        guard let classDef = object.classDef else { return "createdAt" }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
        if isA(.set) {
            return "loggedAt"
        }
        if isA(.workout) {
            return "endedAt"
        }
        if isA(.cook) {
            return "cookedAt"
        }
        if isA(.task) {
            return "due"
        }
        if isA(.listItem) {
            return "checkedAt"
        }
        return "createdAt"
    }

    /// Every value a path reaches from an object (a path through a list of links reaches several).
    static func values(_ path: String, of object: ObjectRecord, _ context: inout Context) throws -> [Value] {
        var current: [Value] = [.object(object)]
        for segment in path.split(separator: ".").map(String.init) {
            current = try current.flatMap { try step(segment, from: $0, &context) }
        }
        return current
    }

    private static func step(_ segment: String, from value: Value, _ context: inout Context) throws -> [Value] {
        let store = context.store, classes = context.classes
        switch value {
        case let .object(object):
            switch segment {
            case "title": return [.text(object.title)]
            case "createdAt": return [.date(object.createdAt)]
            case "class": return object.classDef.map { [.text($0.name)] } ?? []
            case "parent": return object.parent.map { visible([.object($0)], context) } ?? []
            case "children": return visible(object.orderedChildren.map(Value.object), context)
            case "entries":
                guard let entry = classes[.exerciseEntry] else { return [] }
                return visible(object.orderedChildren.filter {
                    $0.classDef.map { ClassResolver.isSubclass($0, of: entry) } ?? false
                }.map(Value.object), context)
            case "sets":
                guard let set = classes[.set] else { return [] }
                return visible(descendants(of: object).filter {
                    $0.classDef.map { ClassResolver.isSubclass($0, of: set) } ?? false
                }.map(Value.object), context)
            case "workout":
                guard let workout = classes[.workout] else { return [] }
                if let own = object.classDef, ClassResolver.isSubclass(own, of: workout) {
                    return [.object(object)]
                }
                return store.ancestor(of: object, ofClass: workout).map { visible([.object($0)], context) } ?? []
            case "exercise":
                let entry = object.classDef.flatMap { classDef in
                    classes[.exerciseEntry].map { ClassResolver.isSubclass(classDef, of: $0) } == true ? object : nil
                } ?? object.parent
                return visible(classDef: entry.flatMap { store.linkedClass("exercise", of: $0) }, context)
            default:
                guard let classDef = object.classDef, let field = ClassResolver.field(segment, of: classDef) else {
                    throw QueryError("no field called \(segment)")
                }
                if field.kind == .richText || segment == "body" {
                    throw QueryError("\(segment) is not a field I read")
                }
                switch field.kind {
                case .ref, .refList:
                    return visible(store.linkedObjects(segment, of: object).map(Value.object), context)
                case .classRef:
                    return visible(classDef: store.linkedClass(segment, of: object), context)
                default:
                    return store.value(segment, of: object).map(convert).map { [$0] } ?? []
                }
            }
        case let .classDef(classDef):
            switch segment {
            case "name", "title": return [.text(classDef.name)]
            case "primaryMuscles", "secondaryMuscles":
                return store.linkedObjects(segment, ofClass: classDef).map { .object($0) }
            default:
                return store.classValue(segment, of: classDef).map(convert).map { [$0] } ?? []
            }
        default:
            return []
        }
    }

    private static func descendants(of object: ObjectRecord) -> [ObjectRecord] {
        object.orderedChildren.flatMap { [$0] + descendants(of: $0) }
    }

    /// What a row is called in an answer: its title, else what it is ("Bench Press 92.5 x 5" for a set).
    static func label(of object: ObjectRecord, _ context: Context) -> String {
        if !object.title.isEmpty {
            return object.title
        }
        let store = context.store
        if let set = context.classes[.set], let classDef = object.classDef,
           ClassResolver.isSubclass(classDef, of: set)
        {
            let name = object.parent.flatMap { store.linkedClass("exercise", of: $0) }?.name ?? "Set"
            let weight = store.number("weight", of: object).map { MeasureFormat.number($0, unit: "kg") } ?? "0"
            let reps = store.number("reps", of: object).map { MeasureFormat.number($0, unit: "") } ?? "?"
            return "\(name) \(weight) kg x \(reps)"
        }
        return object.classDef?.name ?? "an item"
    }

    /// A linked object reads as no value unless it is a kind the allow-list names and is not private. `about` links
    /// can point at any class, so a note about a Spend or a sleep night must not reach its values.
    private static func visible(_ values: [Value], _ context: Context) -> [Value] {
        let allowed = TessTools.countable.compactMap { context.classes[$0] }
        return values.filter { value in
            guard case let .object(object) = value else { return true }
            guard let classDef = object.classDef,
                  allowed.contains(where: { ClassResolver.isSubclass(classDef, of: $0) }),
                  !TessAskRouter.isUnnameable(object, classes: context.classes)
            else { return false }
            return !TessTools.isPrivateForClaude(object, store: context.store, classes: context.classes)
        }
    }

    /// A class reached by a classRef step reads as no value when its name is private.
    private static func visible(classDef: ClassDef?, _ context: Context) -> [Value] {
        guard let classDef else { return [] }
        let last = BodyWeight.lastKg(in: context.store)
        return ObjectPrivacy.isPrivateTitle(classDef.name, lastWeightKg: last) ? [] : [.classDef(classDef)]
    }

    private static func convert(_ field: FieldValue) -> Value {
        switch field {
        case let .number(number), let .duration(number), let .mass(number): .number(number)
        case let .bool(flag): .bool(flag)
        case let .date(date): .date(date)
        case let .text(text), let .choice(text), let .richText(text): .text(text)
        }
    }

    // MARK: Predicates

    static func matches(_ object: ObjectRecord, _ predicate: Query.Pred, _ context: inout Context) throws -> Bool {
        let reached = try values(predicate.field, of: object, &context)
        let wanted = predicate.value ?? ""
        switch predicate.op {
        case "none": return reached.isEmpty
        case "has": return !reached
            .isEmpty && (predicate.value == nil || reached.contains { equals($0, wanted, context) })
        case "=": return wanted == "nil" ? reached.isEmpty : reached.contains { equals($0, wanted, context) }
        case "!=": return wanted == "nil" ? !reached.isEmpty : !reached.contains { equals($0, wanted, context) }
        case "~": return reached.contains { text(of: $0).lowercased().contains(wanted.lowercased()) }
        case "isa": return try reached.contains { try isA($0, wanted, context) }
        default: return reached.contains { compare($0, predicate.op, wanted, context) }
        }
    }

    private static func text(of value: Value) -> String {
        switch value {
        case let .text(text): text
        case let .object(object): object.title
        case let .classDef(classDef): classDef.name
        case let .number(number): String(number)
        case let .bool(flag): flag ? "true" : "false"
        case .date: ""
        }
    }

    private static func equals(_ value: Value, _ wanted: String, _ context: Context) -> Bool {
        switch value {
        case let .number(number): return Double(wanted).map { abs($0 - number) < 1e-9 } ?? false
        case let .bool(flag): return wanted.lowercased() == (flag ? "true" : "false")
        case let .date(date):
            return parseDate(wanted, context).map { context.calendar.isDate(date, inSameDayAs: $0) } ?? false
        default:
            let a = IngredientLine.key(for: text(of: value)), b = IngredientLine.key(for: wanted)
            return a == b || singular(a) == singular(b) || closeEnough(singular(a), singular(b))
        }
    }

    private static func compare(_ value: Value, _ op: String, _ wanted: String, _ context: Context) -> Bool {
        func order<T: Comparable>(_ a: T, _ b: T) -> Bool {
            switch op {
            case "<": a < b
            case "<=": a <= b
            case ">": a > b
            default: a >= b
            }
        }
        switch value {
        case let .number(number): return Double(wanted).map { order(number, $0) } ?? false
        case let .date(date): return parseDate(wanted, context).map { order(date, $0) } ?? false
        default: return false
        }
    }

    private static func parseDate(_ text: String, _ context: Context) -> Date? {
        if text == "today" {
            return context.calendar.startOfDay(for: context.now)
        }
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return context.calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private static func isA(_ value: Value, _ name: String, _ context: Context) throws -> Bool {
        let key = IngredientLine.key(for: name)
        guard let target = context.store.allClasses().first(where: {
            IngredientLine.key(for: $0.name) == key || singular(IngredientLine.key(for: $0.name)) == singular(key)
        }) else { return false }
        switch value {
        case let .object(object): return object.classDef.map { ClassResolver.isSubclass($0, of: target) } ?? false
        case let .classDef(classDef): return ClassResolver.isSubclass(classDef, of: target)
        default: return false
        }
    }

    // MARK: Ranges

    static func interval(_ range: String, now: Date, calendar: Calendar) throws -> DateInterval {
        let day = TesseraDay(calendar: calendar)
        switch range {
        case "today": return day.interval(of: now)
        case "tomorrow":
            return day.interval(of: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        case "thisWeek": return day.week(containing: now)
        case "lastWeek": return day.week(containing: calendar.date(byAdding: .day, value: -7, to: now) ?? now)
        case "thisMonth": return day.month(containing: now)
        case "lastMonth":
            let start = day.month(containing: now).start
            return day.month(containing: calendar.date(byAdding: .day, value: -1, to: start) ?? start)
        case "thisYear":
            return calendar.dateInterval(of: .year, for: day.day(of: now)) ?? day.interval(of: now)
        case "last7d", "last30d", "last90d":
            let days = Int(range.dropFirst(4).dropLast()) ?? 30
            return DateInterval(start: now.addingTimeInterval(-Double(days) * 86400), end: now.addingTimeInterval(1))
        default:
            if range.hasPrefix("date:") {
                let parts = range.dropFirst(5).split(separator: "-").compactMap { Int($0) }
                if parts.count == 3, let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1],
                                                                                   day: parts[2], hour: 12))
                {
                    return day.interval(of: date)
                }
            }
            if range.hasPrefix("month:") {
                let parts = range.dropFirst(6).split(separator: "-").compactMap { Int($0) }
                if parts.count == 2, let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1],
                                                                                   day: 15, hour: 12))
                {
                    return day.month(containing: date)
                }
            }
            throw QueryError("\(range) is not a range I know")
        }
    }

    // MARK: Answer

    private static func answer(_ query: Query, _ found: [ObjectRecord],
                               _ context: inout Context) throws -> QueryResult
    {
        var objects = found
        if let sort = query.sort {
            let keyed = try objects.map { try (object: $0, key: sortKey(sort.field, of: $0, &context)) }
            objects = keyed.enumerated().sorted { left, right in
                let order = compareKeys(left.element.key, right.element.key)
                if order == 0 {
                    return left.offset < right.offset
                }
                return sort.descending ? order > 0 : order < 0
            }.map(\.element.object)
        }
        let noun = nounPhrase(query, objects.count)
        let whenWords = rangeWords(query.during?.range)
        let matched = Array(objects.prefix(maxRows)).map(\.id)
        if let group = query.group {
            return try grouped(query, objects, group, noun, whenWords, &context, matched)
        }
        switch query.agg.kind {
        case "count":
            return QueryResult(line: "\(objects.count) \(noun)\(whenWords).", matched: matched,
                               value: Double(objects.count))
        case "list":
            let limit = query.limit ?? defaultListRows
            let shown = Array(objects.prefix(limit))
            guard !shown.isEmpty else { return QueryResult(
                line: "No \(pluralNoun(query))\(whenWords).",
                matched: [],
                value: 0
            ) }
            let titles = shown.prefix(shownRows).map { label(of: $0, context) }
            let more = shown.count > shownRows ? ", and \(shown.count - shownRows) more" : ""
            return QueryResult(line: "\(objects.count) \(noun)\(whenWords): \(titles.joined(separator: ", "))\(more)",
                               matched: shown.map(\.id), value: Double(objects.count))
        case "latest":
            var best: (ObjectRecord, Date)?
            for object in objects {
                let path = query.agg.field ?? defaultDateField(of: object, classes: context.classes)
                for case let .date(date) in try values(path, of: object, &context)
                    where date > (best?.1 ?? .distantPast)
                {
                    best = (object, date)
                }
            }
            guard let best else { return QueryResult(
                line: "Nothing \(pluralNoun(query)) with a date.",
                matched: [],
                value: nil
            ) }
            return QueryResult(
                line: "\(label(of: best.0, context)), \(dayWords(best.1, context))",
                matched: [best.0.id],
                value: best.1.timeIntervalSince1970
            )
        default:
            return try numeric(query, objects, noun, whenWords, &context)
        }
    }

    private static func numeric(_ query: Query, _ objects: [ObjectRecord], _: String, _ whenWords: String,
                                _ context: inout Context) throws -> QueryResult
    {
        let field = query.agg.field ?? ""
        var pairs: [(ObjectRecord, Double)] = []
        for object in objects {
            for case let .number(number) in try values(field, of: object, &context) where number.isFinite {
                pairs.append((object, number))
            }
        }
        guard !pairs.isEmpty else {
            return QueryResult(line: "No \(pluralNoun(query)) with a \(field)\(whenWords).", matched: [], value: nil)
        }
        let unit = unitFor(field)
        let total = pairs.reduce(0) { $0 + $1.1 }
        let result: Double
        var behind: ObjectRecord?
        switch query.agg.kind {
        case "sum": result = total
        case "avg": result = total / Double(pairs.count)
        case "min":
            let low = pairs.min { $0.1 < $1.1 }
            result = low?.1 ?? 0
            behind = low?.0
        default:
            let high = pairs.max { $0.1 < $1.1 }
            result = high?.1 ?? 0
            behind = high?.0
        }
        let shown = MeasureFormat.number(result, unit: unit.isEmpty ? "" : unit)
        var line = "\(label(query.agg.kind)) \(field): \(shown)\(unit.isEmpty ? "" : " \(unit)")"
        if query.agg.kind == "avg" {
            line += " over \(pairs.count)"
        }
        if let behind {
            let path = defaultDateField(of: behind, classes: context.classes)
            if let date = try values(path, of: behind, &context).compactMap({ value -> Date? in
                if case let .date(date) = value {
                    date
                } else {
                    nil
                }
            }).first {
                line += ", \(dayWords(date, context))"
            }
        }
        line += whenWords
        return QueryResult(line: line, matched: behind.map { [$0.id] } ?? [], value: result)
    }

    private static func grouped(_ query: Query, _ objects: [ObjectRecord], _ group: String, _ noun: String,
                                _ whenWords: String, _ context: inout Context, _ matched: [UUID]) throws -> QueryResult
    {
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        var order: [String] = []
        for object in objects {
            let names = try values(group, of: object, &context).map { text(of: $0) }.filter { !$0.isEmpty }
            for name in Set(names) {
                if counts[name] == nil {
                    order.append(name)
                }
                counts[name, default: 0] += 1
                if query.agg.kind != "count", query.agg.kind != "list", let field = query.agg.field {
                    for case let .number(number) in try values(field, of: object, &context) {
                        totals[name, default: 0] += number
                    }
                }
            }
        }
        let useTotals = query.agg.kind == "sum"
        var ranked: [(name: String, value: Double)] = []
        for name in order {
            let value: Double = useTotals ? (totals[name] ?? 0) : Double(counts[name] ?? 0)
            ranked.append((name: name, value: value))
        }
        ranked.sort { left, right in
            left.value == right.value ? left.name < right.name : left.value > right.value
        }
        let limited = Array(ranked.prefix(query.limit ?? shownRows))
        guard !limited.isEmpty else { return QueryResult(line: "Nothing\(whenWords).", matched: [], value: 0) }
        let unit = useTotals ? unitFor(query.agg.field ?? "") : ""
        let parts = limited.map { "\($0.name) \(MeasureFormat.number($0.value, unit: unit))" }
        let more = ranked.count > limited.count ? ", and \(ranked.count - limited.count) more" : ""
        return QueryResult(line: "\(objects.count) \(noun)\(whenWords): \(parts.joined(separator: ", "))\(more)",
                           matched: matched, value: Double(objects.count),
                           groups: limited)
    }

    // MARK: Words

    private static func sortKey(_ path: String, of object: ObjectRecord, _ context: inout Context) throws -> Value? {
        try values(path, of: object, &context).first
    }

    /// -1, 0 or 1; a missing value sorts last either way it is read.
    private static func compareKeys(_ a: Value?, _ b: Value?) -> Int {
        guard let a else { return b == nil ? 0 : 1 }
        guard let b else { return -1 }
        if case let .number(x) = a, case let .number(y) = b {
            return x < y ? -1 : (x > y ? 1 : 0)
        }
        if case let .date(x) = a, case let .date(y) = b {
            return x < y ? -1 : (x > y ? 1 : 0)
        }
        let left = text(of: a).lowercased(), right = text(of: b).lowercased()
        return left < right ? -1 : (left > right ? 1 : 0)
    }

    private static func pluralNoun(_ query: Query) -> String {
        let name = (query.from.first ?? "things").lowercased()
        return name.hasSuffix("s") ? name : name + "s"
    }

    private static func nounPhrase(_ query: Query, _ count: Int) -> String {
        let plural = pluralNoun(query)
        return count == 1 && plural.hasSuffix("s") ? String(plural.dropLast()) : plural
    }

    private static func rangeWords(_ range: String?) -> String {
        switch range {
        case "today": " today"
        case "tomorrow": " tomorrow"
        case "thisWeek": " this week"
        case "lastWeek": " last week"
        case "thisMonth": " this month"
        case "lastMonth": " last month"
        case "thisYear": " this year"
        case "last7d": " in the last 7 days"
        case "last30d": " in the last 30 days"
        case "last90d": " in the last 90 days"
        case let range? where range.hasPrefix("date:"): " on \(range.dropFirst(5))"
        case let range? where range.hasPrefix("month:"): " in \(range.dropFirst(6))"
        default: ""
        }
    }

    private static func dayWords(_ date: Date, _ context: Context) -> String {
        let formatter = DateFormatter()
        formatter.calendar = context.calendar
        formatter.timeZone = context.calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private static func label(_ kind: String) -> String {
        switch kind {
        case "sum": "total"
        case "avg": "average"
        case "min": "lowest"
        default: "highest"
        }
    }

    private static func unitFor(_ field: String) -> String {
        let last = field.split(separator: ".").last.map(String.init) ?? field
        return ["weight", "e1rm", "volume", "targetWeight"].contains(last) ? "kg" : ""
    }
}
