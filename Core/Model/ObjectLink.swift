import Foundation
import SwiftData

/// A typed reference from one object's field to another object or to a class.
/// Stored as rows so backlinks ("used in 12 workouts") are a query, not a scan of JSON.
@Model
final class ObjectLink {
    var id: UUID = UUID()
    /// The `FieldDef.id` this link belongs to.
    var fieldID: UUID = UUID()
    var sortIndex: Int = 0
    var createdAt: Date = Date.now

    var from: ObjectRecord?
    /// Exactly one of `toObject` / `toClass` is set.
    var toObject: ObjectRecord?
    var toClass: ClassDef?

    init(
        from: ObjectRecord,
        fieldID: UUID,
        toObject: ObjectRecord? = nil,
        toClass: ClassDef? = nil,
        sortIndex: Int = 0
    ) {
        self.from = from
        self.fieldID = fieldID
        self.toObject = toObject
        self.toClass = toClass
        self.sortIndex = sortIndex
    }
}
