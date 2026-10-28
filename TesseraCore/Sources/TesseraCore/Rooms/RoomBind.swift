import Foundation

/// Resolves a room part's bind against the store at render time (R1 spec section 1): the document never holds a copy
/// of his data, so the room stays live. A bind names a class ("Plant"), including classes he made himself; the part's
/// props say how to rank and what to read from each object. A private object is shown by its label, as everywhere.
@MainActor
public struct RoomBind {
    public struct Row: Equatable, Sendable {
        public let id: UUID
        /// The title as any surface shows it (a private thing reads as its label).
        public let title: String
        /// Field values by field key, as the store holds them.
        public let values: [String: FieldValue]

        public func number(_ key: String) -> Double? {
            if case let .number(value)? = values[key] {
                value
            } else {
                nil
            }
        }

        public func date(_ key: String) -> Date? {
            values[key]?.dateValue
        }
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]
    public var now: () -> Date = { .now }
    public var calendar: Calendar = .current

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// "Plant" or "Plant where ..." is the class Plant: system classes and ones he made, by name.
    public func classDef(for bind: String) -> ClassDef? {
        let name = RoomDocument.className(of: bind).trimmingCharacters(in: .whitespaces)
        return store.classDef(named: name)
            ?? store.allClasses().first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Every live object of the bound class, ranked by the part's `sort` and cut to its `max`.
    public func rows(for part: RoomPart) -> [Row] {
        guard let bind = part.bind, let classDef = classDef(for: bind) else { return [] }
        let labelClasses = PrivateWords.systemClasses(in: store.context)
        var rows = store.objects(of: classDef).map { object -> Row in
            var values: [String: FieldValue] = [:]
            for field in ClassResolver.effectiveFields(of: classDef) {
                if let value = store.value(field.key, of: object) {
                    values[field.key] = value
                }
            }
            let shown = ObjectPrivacy.shownLabel(of: object, in: store, classes: labelClasses) ?? object.title
            return Row(id: object.id, title: shown, values: values)
        }
        if let sort = part.text("sort") {
            rows = ranked(rows, by: sort)
        }
        if case let .number(limit)? = part.props["max"], limit >= 1 {
            rows = Array(rows.prefix(Int(limit)))
        }
        return rows
    }

    /// "-daysSince(lastWatered)" is the longest since first; "waterEvery" is the smallest first.
    func ranked(_ rows: [Row], by sort: String) -> [Row] {
        let descending = sort.hasPrefix("-")
        var text = descending ? String(sort.dropFirst()) : sort
        var daysSince = false
        if let open = text.firstIndex(of: "("), text.hasSuffix(")") {
            daysSince = text[..<open] == "daysSince"
            text = String(text[text.index(after: open) ..< text.index(before: text.endIndex)])
        }
        let key = text
        func rank(_ row: Row) -> Double {
            if key == "title" {
                return 0
            }
            if daysSince {
                // A date never set is the longest since there is.
                guard let date = row.date(key) else { return .greatestFiniteMagnitude }
                return Double(calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                                      to: calendar.startOfDay(for: now())).day ?? 0)
            }
            return row.number(key) ?? row.date(key)?.timeIntervalSince1970 ?? 0
        }
        return rows.sorted { left, right in
            let (a, b) = (rank(left), rank(right))
            if a != b {
                return descending ? a > b : a < b
            }
            return left.title.localizedCaseInsensitiveCompare(right.title) == .orderedAscending
        }
    }

    /// The single number a `number` part shows: count, sum, avg, min, max or latest of its field.
    public func number(for part: RoomPart) -> Double? {
        guard part.kind == "number" else { return nil }
        let rows = rows(for: RoomPart(id: part.id, kind: "row", place: part.place, props: [:], bind: part.bind))
        let agg = part.text("agg") ?? "count"
        if agg == "count" {
            return Double(rows.count)
        }
        guard let field = part.text("field") else { return nil }
        let values = rows.compactMap { $0.number(field) }
        switch agg {
        case "sum": return values.isEmpty ? nil : values.reduce(0, +)
        case "avg": return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
        case "min": return values.min()
        case "max": return values.max()
        case "latest":
            return rows.compactMap { row in row.date(field).map { ($0, row.number(field)) } }
                .max { $0.0 < $1.0 }?.1
        default: return nil
        }
    }

    /// A line with its tokens filled: {count}, {top} (the first ranked title) and {fieldKey} (the top row's field).
    /// A part with no sort of its own ranks like the first sorted part of its room that binds the same class, so
    /// "the {top} is thirsty" names the one the row ranks first.
    public func fill(_ text: String, for part: RoomPart, in document: RoomDocument? = nil) -> String {
        var props = part.props.filter { $0.key == "sort" }
        if props.isEmpty,
           let sibling = document?.parts.first(where: { $0.bind == part.bind && $0.props["sort"] != nil })
        {
            props["sort"] = sibling.props["sort"]
        }
        let rows = rows(for: RoomPart(id: part.id, kind: "row", place: part.place, props: props, bind: part.bind))
        var out = text
        out = out.replacingOccurrences(of: "{count}", with: String(rows.count))
        out = out.replacingOccurrences(of: "{top}", with: rows.first?.title ?? "")
        for (key, value) in rows.first?.values ?? [:] {
            let shown: String = switch value {
            case let .number(number): number.rounded() == number ? String(Int(number)) : String(number)
            case let .text(text): text
            case let .choice(text): text
            default: ""
            }
            out = out.replacingOccurrences(of: "{\(key)}", with: shown)
        }
        return out
    }
}
