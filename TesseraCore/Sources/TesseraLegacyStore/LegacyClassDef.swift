import Foundation
import SwiftData
import TesseraCore

// CloudKit-compatible SwiftData models: every stored property is optional or defaulted,
// no unique constraints, and all relationships are optional with inverses.

// Interface-like mixins a class can adopt. Features key off these
// (e.g. anything `schedulable` can sit in Now / Next / Later or a plan).

/// A user-definable kind of object ("Exercise", "Bench Press", "Workout", "Book").
/// Single inheritance through `parent`; fields are inherited down the chain.
@Model
final class ClassDef {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "circle"
    /// Semantic color role resolved by the design system (e.g. "training", "planning"), never a raw color.
    var colorRole: String = "neutral"
    var traitsRaw: [String] = []
    /// Stable key for built-in classes (e.g. "system.benchPress"); nil for user classes.
    var systemKey: String?
    var sortIndex: Int = 0
    var createdAt: Date = Date.now
    /// The package that ships this class ("system" for built-ins), and the package version last applied.
    var packageID: String?
    var packageVersion: Int = 0
    /// Set when the person edits a shipped class; package upgrades then leave its name, symbol and traits alone.
    var isUserModified: Bool = false

    var parent: ClassDef?

    @Relationship(deleteRule: .nullify, inverse: \ClassDef.parent)
    var subclasses: [ClassDef]? = []

    @Relationship(deleteRule: .cascade, inverse: \FieldDef.owner)
    var ownFields: [FieldDef]? = []

    @Relationship(deleteRule: .nullify, inverse: \ObjectRecord.classDef)
    var objects: [ObjectRecord]? = []

    /// Links that point at this class (classRef fields), e.g. every logged entry of Bench Press.
    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.toClass)
    var incomingLinks: [ObjectLink]? = []

    @Relationship(deleteRule: .cascade, inverse: \ViewDef.classDef)
    var views: [ViewDef]? = []

    init(
        name: String,
        parent: ClassDef? = nil,
        symbolName: String = "circle",
        colorRole: String = "neutral",
        traits: [ClassTrait] = [],
        systemKey: String? = nil
    ) {
        id = .v7()
        self.name = name
        self.parent = parent
        self.symbolName = symbolName
        self.colorRole = colorRole
        traitsRaw = traits.map(\.rawValue)
        self.systemKey = systemKey
    }

    /// Own traits only. Use `ClassResolver.traits(of:)` for the inherited set.
    var ownTraits: Set<ClassTrait> {
        Set(traitsRaw.compactMap(ClassTrait.init(rawValue:)))
    }
}
