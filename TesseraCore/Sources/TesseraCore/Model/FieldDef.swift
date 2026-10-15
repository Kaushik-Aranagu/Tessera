import Foundation
import SwiftData

/// A property declared by a class. Values are stored by `id`, never by name.
@Model
public final class FieldDef {
    public var id: UUID = UUID()
    /// Display name, freely renamable.
    public var name: String = ""
    /// Identifier used by formulas and code (e.g. "weight"). Values are still stored by `id`.
    public var key: String = ""
    public var kindRaw: String = FieldKind.text.rawValue
    public var sortIndex: Int = 0
    public var isRequired: Bool = false
    public var unit: String?
    public var enumOptions: [String] = []
    /// For `.ref`, `.refList`, `.classRef`: the target class (subclasses are accepted too).
    public var targetClassID: UUID?
    /// For `.computed`: a `Formula` over other field keys, e.g. `weight * (1 + reps / 30)`.
    public var expression: String?
    public var defaultValueData: Data?
    /// When set, this field doesn't add a new property: it overrides the default of an inherited field.
    public var overridesFieldID: UUID?
    /// Set when the person edits a shipped field (the user overlay); package upgrades then leave it alone.
    public var isUserModified: Bool = false

    public var owner: ClassDef?

    public init(
        name: String,
        key: String,
        kind: FieldKind,
        sortIndex: Int = 0,
        unit: String? = nil,
        defaultValue: FieldValue? = nil
    ) {
        id = .v7()
        self.name = name
        self.key = key
        kindRaw = kind.rawValue
        self.sortIndex = sortIndex
        self.unit = unit
        self.defaultValue = defaultValue
    }

    public var kind: FieldKind {
        get { FieldKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    public var defaultValue: FieldValue? {
        get { defaultValueData.flatMap { try? JSONDecoder().decode(FieldValue.self, from: $0) } }
        set { defaultValueData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }
}
