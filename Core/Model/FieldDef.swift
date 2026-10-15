import Foundation
import SwiftData

/// A property declared by a class. Values are stored by `id`, never by name.
@Model
final class FieldDef {
    var id: UUID = UUID()
    /// Display name, freely renamable.
    var name: String = ""
    /// Stable identifier used by computed expressions (e.g. "weight").
    var key: String = ""
    var kindRaw: String = FieldKind.text.rawValue
    var sortIndex: Int = 0
    var isRequired: Bool = false
    var unit: String?
    var enumOptions: [String] = []
    /// For `.ref`, `.refList`, `.classRef`: the target class (subclasses are accepted too).
    var targetClassID: UUID?
    /// For `.computed`: arithmetic over other field keys, e.g. `weight * (1 + reps / 30)`.
    var expression: String?
    var defaultValueData: Data?
    /// When set, this field doesn't add a new property: it overrides the default of an inherited field.
    var overridesFieldID: UUID?

    var owner: ClassDef?

    init(
        name: String,
        key: String,
        kind: FieldKind,
        sortIndex: Int = 0,
        unit: String? = nil,
        defaultValue: FieldValue? = nil
    ) {
        self.name = name
        self.key = key
        kindRaw = kind.rawValue
        self.sortIndex = sortIndex
        self.unit = unit
        self.defaultValue = defaultValue
    }

    var kind: FieldKind {
        get { FieldKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    var defaultValue: FieldValue? {
        get { defaultValueData.flatMap { try? JSONDecoder().decode(FieldValue.self, from: $0) } }
        set { defaultValueData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }
}
