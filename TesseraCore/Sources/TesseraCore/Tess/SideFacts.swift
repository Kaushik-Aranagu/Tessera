import Foundation

/// What a side may show (board 0ak must-fixes; Research screens-inventory-check.md PL1 to PL3, Product 2:44 and 2:45
/// PM PT Oct 16): a side never shows a private fact its front hides, and nothing on a side goes to Claude. The
/// SideHost reads these; it never reads raw notes, fields or class members itself.
@MainActor
public enum SideFacts {
    /// An exercise's setup notes, line by line, with every line holding a secret word, money, a body or health fact
    /// or a key taken out and counted (PL1): "left knee sore, locker code 4471" is never shown, never the glance's
    /// big fact, never in "Ask about this".
    public struct Lines: Equatable, Sendable {
        public let shown: [String]
        public let keptPrivate: Int

        /// "1 line kept private", or nil when none were.
        public var keptLine: String? {
            keptPrivate == 0 ? nil : "\(keptPrivate) \(keptPrivate == 1 ? "line" : "lines") kept private"
        }
    }

    public static func setupLines(_ notes: String?, store: ObjectStore) -> Lines {
        let lastKg = BodyWeight.lastKg(in: store)
        let lines = (notes ?? "").components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let shown = lines.filter { isShowable($0, lastWeightKg: lastKg) }
        return Lines(shown: shown, keptPrivate: lines.count - shown.count)
    }

    /// A value a side may print: no secret word, no money, no body or health fact, no key.
    public static func isShowable(_ text: String, lastWeightKg: Double?) -> Bool {
        !SecretWords.mentions(text) && !looksLikeClaudeKey(text) && !PrivateFacts.isWalled(
            text,
            lastWeightKg: lastWeightKg
        )
    }

    /// A training load ("Weight: 60 kg" on a set, a target weight, a bar) is the bar's, not his body (QA on #785):
    /// checked for secrets, keys and money, never read as a weigh-in. Every other field is read whole.
    public static func isShowable(_ field: ResolvedField, _ text: String, of classDef: ClassDef,
                                  classes: [SystemCatalog.Key: ClassDef], lastWeightKg: Double?) -> Bool
    {
        let line = "\(field.name): \(text)"
        let load = field.kind == .mass && [SystemCatalog.Key.set, .exerciseEntry, .equipment].contains { key in
            classes[key].map { ClassResolver.isSubclass(classDef, of: $0) } == true
        }
        guard load else { return isShowable(line, lastWeightKg: lastWeightKg) }
        return !SecretWords.mentions(line) && !looksLikeClaudeKey(line) && !PrivateFacts.isMoneyShaped(line)
    }

    /// The default side's fields (PL2): nil for a private object, which shows its count only; otherwise every field
    /// with a value, minus `hidden` (what the front already shows) and any field a side may not print. A field is
    /// judged as "<name>: <value>", so a number in a field named "Door code" or "Rent" is held back like the words are.
    public static func defaultFields(of object: ObjectRecord, in store: ObjectStore,
                                     classes: [SystemCatalog.Key: ClassDef],
                                     except hidden: Set<String> = []) -> [(key: String, name: String, value: String)]?
    {
        guard let classDef = object.classDef,
              ObjectPrivacy.label(of: object, in: store, classes: classes) == nil,
              object.title != SecretWords.title,
              store.value("isPrivate", of: object) != .bool(true) else { return nil }
        let lastKg = BodyWeight.lastKg(in: store)
        return ClassResolver.effectiveFields(of: classDef).compactMap { field in
            guard !hidden.contains(field.key), field.key != "notes", field.key != "isPrivate",
                  let value = store.value(field.key, of: object), let text = describe(value),
                  isShowable(field, text, of: classDef, classes: classes, lastWeightKg: lastKg) else { return nil }
            return (field.key, field.name, text)
        }
    }

    /// A class page's glance (PL3): how many objects, how many private, the newest by its label when private, and
    /// the most used (most edited in 30 days) among objects that aren't private.
    public struct ClassGlance: Equatable, Sendable {
        public let count: Int
        public let privateCount: Int
        /// The newest object's line: its title, or its private label ("Private note"), never a private title.
        public let newest: String?
        public let newestID: UUID?
        public let mostUsedID: UUID?

        /// "38 objects", then "5 private" when any are.
        public var countLine: String {
            "\(count) \(count == 1 ? "object" : "objects")"
        }

        public var privateLine: String? {
            privateCount == 0 ? nil : "\(privateCount) private"
        }
    }

    public static func classGlance(_ classDef: ClassDef, engine: ActionEngine, now: Date = .now) -> ClassGlance {
        let store = engine.store, classes = engine.classes
        let objects = store.objects(of: classDef).filter { !$0.isDeleted }
        func label(_ object: ObjectRecord) -> String? {
            ObjectPrivacy.label(of: object, in: store, classes: classes)
                ?? (store.value("isPrivate", of: object) == .bool(true) ? SecretWords.title : nil)
        }
        let open = objects.filter { label($0) == nil }
        let newest = objects.max { $0.createdAt < $1.createdAt }
        let ids = Set(open.map(\.id))
        var edits: [UUID: Int] = [:]
        for record in engine.history(from: now.addingTimeInterval(-30 * 86400), to: now) where record.state != .undone {
            for id in record.objectIDs where ids.contains(id) {
                edits[id, default: 0] += 1
            }
        }
        let mostUsed = edits.max { $0.value == $1.value ? $0.key.uuidString > $1.key.uuidString : $0.value < $1.value }
        return ClassGlance(count: objects.count, privateCount: objects.count - open.count,
                           newest: newest.map { label($0) ?? $0.title }, newestID: newest?.id,
                           mostUsedID: mostUsed?.key)
    }

    /// A value as a side prints it, in house words: a date with its day and clock ("Oct 17, 6:30 pm"), a duration in
    /// minutes or, under a minute, seconds, a mass in kg. Nil for an empty value or a zero duration.
    static func describe(_ value: FieldValue, calendar: Calendar = .current, unit: MassUnit = .kilograms) -> String? {
        switch value {
        case let .text(text), let .choice(text), let .richText(text): text.isEmpty ? nil : text
        case let .number(number): String(format: "%g", number)
        case let .mass(number): String(format: "%g \(unit.symbol)", unit.shown(kilograms: number))
        case let .bool(flag): flag ? "Yes" : "No"
        case let .date(date): "\(day(of: date, calendar: calendar)), \(HouseTime.clock(date, calendar: calendar))"
        case let .duration(seconds):
            if seconds < 1 {
                nil
            } else if seconds < 60 {
                "\(Int(seconds)) sec"
            } else {
                "\(Int(seconds / 60)) min"
            }
        }
    }

    private static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    /// "Oct 17": US-English, whatever the phone's language.
    private static func day(of date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.month, .day], from: date)
        return "\(months[((parts.month ?? 1) - 1) % 12]) \(parts.day ?? 1)"
    }
}
