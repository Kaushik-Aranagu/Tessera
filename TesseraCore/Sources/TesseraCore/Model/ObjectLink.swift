import Foundation
import SwiftData

/// A typed reference from one object's field to another object or to a class.
/// Stored as rows so backlinks ("used in 12 workouts") are a query, not a scan of JSON.
@Model
public final class ObjectLink {
    public var id: UUID = UUID()
    /// The `FieldDef.id` this link belongs to.
    public var fieldID: UUID = UUID()
    public var sortIndex: Int = 0
    public var createdAt: Date = Date.now

    public var from: ObjectRecord?
    /// Exactly one of `toObject` / `toClass` is set.
    public var toObject: ObjectRecord?
    public var toClass: ClassDef?

    /// An unrelated link; insert it into a context, then set `from` and a target.
    public init(fieldID: UUID, sortIndex: Int = 0) {
        self.fieldID = fieldID
        self.sortIndex = sortIndex
    }

    public init(
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
