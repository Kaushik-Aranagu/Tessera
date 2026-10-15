import Foundation

/// The kinds of property a class can declare.
enum FieldKind: String, Codable, CaseIterable, Sendable {
    case text
    case number
    case bool
    case date
    /// Seconds.
    case duration
    /// Stored in kilograms; `FieldDef.unit` is the preferred display unit.
    case mass
    /// One of `FieldDef.enumOptions`.
    case choice
    /// A link to one object whose class is `targetClass` or a subclass. Stored as an `ObjectLink`.
    case ref
    /// Links to many objects. Stored as `ObjectLink`s.
    case refList
    /// A link to a class itself (e.g. a logged entry points at the `BenchPress` class). Stored as an `ObjectLink`.
    case classRef
    /// Derived from other fields via `FieldDef.expression`; never stored.
    case computed
    case richText
}

/// A stored scalar value. References live in `ObjectLink`, not here.
enum FieldValue: Codable, Hashable, Sendable {
    case text(String)
    case number(Double)
    case bool(Bool)
    case date(Date)
    case duration(TimeInterval)
    case mass(Double)
    case choice(String)
    case richText(String)

    /// Numeric view used by computed expressions.
    var numericValue: Double? {
        switch self {
        case let .number(value), let .duration(value), let .mass(value): value
        case let .bool(value): value ? 1 : 0
        case .text, .date, .choice, .richText: nil
        }
    }

    var stringValue: String? {
        switch self {
        case let .text(value), let .choice(value), let .richText(value): value
        default: nil
        }
    }
}

/// Values of one object, keyed by `FieldDef.id`. Field ids are stable, so renaming a field never loses data.
struct FieldValues: Codable, Sendable, Equatable {
    var storage: [UUID: FieldValue] = [:]

    subscript(fieldID: UUID) -> FieldValue? {
        get { storage[fieldID] }
        set { storage[fieldID] = newValue }
    }
}
