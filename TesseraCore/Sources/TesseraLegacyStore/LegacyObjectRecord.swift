import Foundation
import SwiftData
import TesseraCore

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
    /// External storage is part of the shipped schema; changing it needs a migration plan (no automatic mapping).
    @Attribute(.externalStorage) var valuesData: Data?
    /// The class's own object (like a metaclass instance): holds class-level values such as
    /// Bench Press's muscles or cues, which every object of the class and its subclasses inherits.
    var isClassObject: Bool = false

    var classDef: ClassDef?
    var parent: ObjectRecord?

    @Relationship(deleteRule: .cascade, inverse: \ObjectRecord.parent)
    var children: [ObjectRecord]? = []

    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.from)
    var outgoingLinks: [ObjectLink]? = []

    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.toObject)
    var incomingLinks: [ObjectLink]? = []

    init(title: String = "", classDef: ClassDef?, parent: ObjectRecord? = nil) {
        id = .v7()
        self.title = title
        self.classDef = classDef
        self.parent = parent
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    /// Raw stored values; prefer `ObjectStore` accessors, which apply defaults and computed fields.
    var values: FieldValues {
        get {
            // Decoding JSON on every read dominated long histories; keep the last decode until the data changes.
            let data = valuesData
            if let decoded, decoded.data == data {
                return decoded.values
            }
            let values = data.flatMap { try? JSONDecoder().decode(FieldValues.self, from: $0) } ?? FieldValues()
            decoded = (data, values)
            return values
        }
        set {
            // No-op writes don't dirty the record (and don't create sync traffic).
            guard newValue != values, let data = try? Self.encoder.encode(newValue) else { return }
            valuesData = data
            decoded = (data, newValue)
            updatedAt = .now
        }
    }

    @Transient private var decoded: (data: Data?, values: FieldValues)?

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    /// Live children in order, excluding soft-deleted ones.
    var orderedChildren: [ObjectRecord] {
        (children ?? []).filter { !$0.isDeleted }.sorted { ($0.sortIndex, $0.createdAt) < ($1.sortIndex, $1.createdAt) }
    }
}
