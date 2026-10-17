import Foundation

/// The kinds of property a class can declare.
public enum FieldKind: String, Codable, CaseIterable, Sendable {
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

    /// Kinds whose values live in `ObjectLink` rows rather than in `FieldValues`.
    public var isLink: Bool {
        self == .ref || self == .refList || self == .classRef
    }
}

/// A stored scalar value. References live in `ObjectLink`, not here.
public enum FieldValue: Codable, Hashable, Sendable {
    case text(String)
    case number(Double)
    case bool(Bool)
    case date(Date)
    case duration(TimeInterval)
    case mass(Double)
    case choice(String)
    case richText(String)

    /// The field kind this value can be stored in.
    public var kind: FieldKind {
        switch self {
        case .text: .text
        case .number: .number
        case .bool: .bool
        case .date: .date
        case .duration: .duration
        case .mass: .mass
        case .choice: .choice
        case .richText: .richText
        }
    }

    /// Numeric view used by formulas. A NaN, an infinity or a value past 1e15 reads as no value, so no caller's
    /// `Int(...)` or `addTimeInterval` can trap on a number that came in through a restore, a file or a model.
    public var numericValue: Double? {
        let value: Double? = switch self {
        case let .number(value), let .duration(value), let .mass(value): value
        case let .bool(value): value ? 1 : 0
        case .text, .date, .choice, .richText: nil
        }
        guard let value, value.isFinite, abs(value) < 1e15 else { return nil }
        return value
    }

    public var stringValue: String? {
        switch self {
        case let .text(value), let .choice(value), let .richText(value): value
        default: nil
        }
    }

    public var dateValue: Date? {
        if case let .date(value) = self {
            value
        } else {
            nil
        }
    }
}

/// Values of one object, keyed by `FieldDef.id`. Field ids are stable, so renaming a field never loses data.
///
/// Encoded as a JSON object keyed by UUID string. Decoding is per entry: a value this version can't read
/// (written by a newer app on another device) is kept verbatim and written back untouched, so one unknown
/// value can never wipe the rest of the object.
public struct FieldValues: Codable, Sendable, Equatable {
    public var storage: [UUID: FieldValue] = [:]
    /// Entries this version couldn't decode, preserved as raw JSON.
    public private(set) var unreadable: [String: RawJSON] = [:]

    public init(storage: [UUID: FieldValue] = [:]) {
        self.storage = storage
    }

    public subscript(fieldID: UUID) -> FieldValue? {
        get { storage[fieldID] }
        set {
            storage[fieldID] = newValue
            unreadable[fieldID.uuidString] = nil
        }
    }

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int?
        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    public init(from decoder: any Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: Key.self) {
            for key in keyed.allKeys {
                if let id = UUID(uuidString: key.stringValue),
                   let value = try? keyed.decode(FieldValue.self, forKey: key)
                {
                    storage[id] = value
                } else if let raw = try? keyed.decode(RawJSON.self, forKey: key) {
                    unreadable[key.stringValue] = raw
                }
            }
            return
        }
        // Earlier builds encoded `[UUID: FieldValue]` as a flat [key, value, key, value] array.
        var flat = try decoder.unkeyedContainer()
        while !flat.isAtEnd {
            let id = try flat.decode(UUID.self)
            if let value = try? flat.decode(FieldValue.self) {
                storage[id] = value
            } else {
                unreadable[id.uuidString] = try flat.decode(RawJSON.self)
            }
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var keyed = encoder.container(keyedBy: Key.self)
        for (key, raw) in unreadable {
            try keyed.encode(raw, forKey: Key(stringValue: key))
        }
        for (id, value) in storage {
            try keyed.encode(value, forKey: Key(stringValue: id.uuidString))
        }
    }
}

/// Any JSON value, kept as-is so it survives a round trip through a version that doesn't understand it.
public indirect enum RawJSON: Codable, Sendable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([RawJSON])
    case object([String: RawJSON])

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([RawJSON].self) {
            self = .array(value)
        } else {
            self = try .object(container.decode([String: RawJSON].self))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case let .bool(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .string(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        }
    }
}
