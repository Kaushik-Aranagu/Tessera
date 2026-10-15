import Foundation

/// A field as seen by a concrete class after inheritance and overrides are applied.
struct ResolvedField: Identifiable {
    /// The id of the field that *declares* the property; values are stored under it.
    let id: UUID
    let key: String
    let name: String
    let kind: FieldKind
    let unit: String?
    let enumOptions: [String]
    let targetClassID: UUID?
    let expression: String?
    let defaultValue: FieldValue?
    let isRequired: Bool
    /// The class that declared the property (not the one that overrode its default).
    let declaringClassID: UUID?
}

/// Resolves inheritance: ancestry, traits and effective fields.
enum ClassResolver {
    /// Root first, `classDef` last. Stops at cycles instead of looping forever.
    static func lineage(of classDef: ClassDef) -> [ClassDef] {
        var chain: [ClassDef] = []
        var seen = Set<UUID>()
        var current: ClassDef? = classDef
        while let node = current, seen.insert(node.id).inserted {
            chain.append(node)
            current = node.parent
        }
        return chain.reversed()
    }

    static func isSubclass(_ classDef: ClassDef, of ancestor: ClassDef) -> Bool {
        lineage(of: classDef).contains { $0.id == ancestor.id }
    }

    static func isSubclass(_ classDef: ClassDef, ofClassID ancestorID: UUID) -> Bool {
        lineage(of: classDef).contains { $0.id == ancestorID }
    }

    /// Traits are inherited like interfaces.
    static func traits(of classDef: ClassDef) -> Set<ClassTrait> {
        lineage(of: classDef).reduce(into: Set<ClassTrait>()) { $0.formUnion($1.ownTraits) }
    }

    /// Inherited fields first (root → leaf), each class's own fields in `sortIndex` order.
    /// A field with `overridesFieldID` replaces the default of the inherited field it points at.
    static func effectiveFields(of classDef: ClassDef) -> [ResolvedField] {
        var fields: [ResolvedField] = []
        for node in lineage(of: classDef) {
            let own = (node.ownFields ?? []).sorted { ($0.sortIndex, $0.name) < ($1.sortIndex, $1.name) }
            for field in own {
                if let overriddenID = field.overridesFieldID,
                   let index = fields.firstIndex(where: { $0.id == overriddenID })
                {
                    let base = fields[index]
                    fields[index] = ResolvedField(
                        id: base.id,
                        key: base.key,
                        name: base.name,
                        kind: base.kind,
                        unit: field.unit ?? base.unit,
                        enumOptions: base.enumOptions,
                        targetClassID: base.targetClassID,
                        expression: base.expression,
                        defaultValue: field.defaultValue ?? base.defaultValue,
                        isRequired: base.isRequired,
                        declaringClassID: base.declaringClassID
                    )
                } else if field.overridesFieldID == nil {
                    fields.append(ResolvedField(
                        id: field.id,
                        key: field.key,
                        name: field.name,
                        kind: field.kind,
                        unit: field.unit,
                        enumOptions: field.enumOptions,
                        targetClassID: field.targetClassID,
                        expression: field.expression,
                        defaultValue: field.defaultValue,
                        isRequired: field.isRequired,
                        declaringClassID: node.id
                    ))
                }
            }
        }
        return fields
    }

    static func field(_ key: String, of classDef: ClassDef) -> ResolvedField? {
        effectiveFields(of: classDef).first { $0.key == key }
    }
}
