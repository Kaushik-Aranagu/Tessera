import Foundation
import SwiftData

/// An instance of a class: a logged set, a workout, a muscle, a note.
/// Objects compose through `parent`/`children` (Workout → exercise entries → sets).
@Model
public final class ObjectRecord {
    public var id: UUID = UUID()
    public var title: String = ""
    public var sortIndex: Int = 0
    public var createdAt: Date = Date.now
    public var updatedAt: Date = Date.now
    /// Soft delete; hidden from normal queries, recoverable.
    public var deletedAt: Date?
    @Attribute(.externalStorage) public var valuesData: Data?
    /// The class's own object (like a metaclass instance): holds class-level values such as
    /// Bench Press's muscles or cues, which every object of the class and its subclasses inherits.
    public var isClassObject: Bool = false

    public var classDef: ClassDef?
    public var parent: ObjectRecord?

    @Relationship(deleteRule: .cascade, inverse: \ObjectRecord.parent)
    public var children: [ObjectRecord]? = []

    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.from)
    public var outgoingLinks: [ObjectLink]? = []

    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.toObject)
    public var incomingLinks: [ObjectLink]? = []

    public init(title: String = "", classDef: ClassDef?, parent: ObjectRecord? = nil) {
        self.title = title
        self.classDef = classDef
        self.parent = parent
    }

    public var isDeleted: Bool {
        deletedAt != nil
    }

    /// Raw stored values; prefer `ObjectStore` accessors, which apply defaults and computed fields.
    public var values: FieldValues {
        get { valuesData.flatMap { try? JSONDecoder().decode(FieldValues.self, from: $0) } ?? FieldValues() }
        set {
            // No-op writes don't dirty the record (and don't create sync traffic).
            guard newValue != values, let data = try? Self.encoder.encode(newValue) else { return }
            valuesData = data
            updatedAt = .now
        }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    /// Live children in order, excluding soft-deleted ones.
    public var orderedChildren: [ObjectRecord] {
        (children ?? []).filter { !$0.isDeleted }.sorted { ($0.sortIndex, $0.createdAt) < ($1.sortIndex, $1.createdAt) }
    }
}
