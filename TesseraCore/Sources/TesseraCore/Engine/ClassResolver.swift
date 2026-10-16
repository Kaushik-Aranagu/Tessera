import Foundation

/// A field as seen by a concrete class after inheritance and overrides are applied.
public struct ResolvedField: Identifiable, Hashable, Sendable {
    /// The id of the field that *declares* the property; values are stored under it.
    public let id: UUID
    public let key: String
    public let name: String
    public let kind: FieldKind
    public let unit: String?
    public let enumOptions: [String]
    public let targetClassID: UUID?
    public let expression: String?
    public let defaultValue: FieldValue?
    public let isRequired: Bool
    /// The class that declared the property (not the one that overrode its default).
    public let declaringClassID: UUID?
}

/// Resolves inheritance: ancestry, traits, effective fields and paths.
@MainActor
public enum ClassResolver {
    /// Root first, `classDef` last. Stops at cycles instead of looping forever.
    public static func lineage(of classDef: ClassDef) -> [ClassDef] {
        var chain: [ClassDef] = []
        var seen = Set<UUID>()
        var current: ClassDef? = classDef
        while let node = current, seen.insert(node.id).inserted {
            chain.append(node)
            current = node.parent
        }
        return chain.reversed()
    }

    public static func isSubclass(_ classDef: ClassDef, of ancestor: ClassDef) -> Bool {
        isSubclass(classDef, ofClassID: ancestor.id)
    }

    public static func isSubclass(_ classDef: ClassDef, ofClassID ancestorID: UUID) -> Bool {
        lineage(of: classDef).contains { $0.id == ancestorID }
    }

    /// `classDef` and every class below it, parents before children. Safe against cycles.
    public static func descendants(of classDef: ClassDef) -> [ClassDef] {
        var result: [ClassDef] = []
        var queue = [classDef]
        var seen = Set<UUID>()
        while !queue.isEmpty {
            let node = queue.removeFirst()
            guard seen.insert(node.id).inserted else { continue }
            result.append(node)
            queue += (node.subclasses ?? []).sorted { ($0.sortIndex, $0.name) < ($1.sortIndex, $1.name) }
        }
        return result
    }

    /// Traits are inherited like interfaces.
    public static func traits(of classDef: ClassDef) -> Set<ClassTrait> {
        lineage(of: classDef).reduce(into: Set<ClassTrait>()) { $0.formUnion($1.ownTraits) }
    }

    /// Inherited fields first (root → leaf), each class's own fields in `sortIndex` order.
    /// A field with `overridesFieldID` replaces the default of the inherited field it points at.
    public static func effectiveFields(of classDef: ClassDef) -> [ResolvedField] {
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

    public static func field(_ key: String, of classDef: ClassDef) -> ResolvedField? {
        effectiveFields(of: classDef).first { $0.key == key }
    }

    /// Where a class lives in the object graph, e.g. `/activity/exercise/strength-exercise/barbell-lift/bench-press`.
    /// The root class (Thing) is the implicit `/`.
    public static func path(of classDef: ClassDef) -> ObjectPath {
        let chain = lineage(of: classDef)
        let visible = chain.count > 1 ? Array(chain.dropFirst()) : chain
        return ObjectPath(segments: visible.map { .init(target: .classDef($0.id), title: $0.name) })
    }
}
