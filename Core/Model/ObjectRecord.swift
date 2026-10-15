import Foundation
import SwiftData

/// An instance of a class: a logged set, a workout, a muscle, a note.
/// Objects compose through `parent`/`children` (Workout → exercise entries → sets).
@Model
final class ObjectRecord {
    var id: UUID = UUID()
    var title: String = ""
    var sortIndex: Int = 0
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    /// Soft delete; hidden from normal queries, recoverable.
    var deletedAt: Date?
    @Attribute(.externalStorage) var valuesData: Data?

    var classDef: ClassDef?
    var parent: ObjectRecord?

    @Relationship(deleteRule: .cascade, inverse: \ObjectRecord.parent)
    var children: [ObjectRecord]? = []

    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.from)
    var outgoingLinks: [ObjectLink]? = []

    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.toObject)
    var incomingLinks: [ObjectLink]? = []

    init(title: String = "", classDef: ClassDef?, parent: ObjectRecord? = nil) {
        self.title = title
        self.classDef = classDef
        self.parent = parent
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    /// Raw stored values; prefer `ObjectStore` accessors, which apply defaults and computed fields.
    var values: FieldValues {
        get { valuesData.flatMap { try? JSONDecoder().decode(FieldValues.self, from: $0) } ?? FieldValues() }
        set {
            valuesData = try? JSONEncoder().encode(newValue)
            updatedAt = .now
        }
    }

    /// Live children in order, excluding soft-deleted ones.
    var orderedChildren: [ObjectRecord] {
        (children ?? []).filter { !$0.isDeleted }.sorted { ($0.sortIndex, $0.createdAt) < ($1.sortIndex, $1.createdAt) }
    }
}
