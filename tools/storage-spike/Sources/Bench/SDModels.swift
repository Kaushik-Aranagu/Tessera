import Foundation
import SwiftData

// Mirrors TesseraCore/Model (ClassDef, FieldDef, ObjectRecord, ObjectLink, ViewDef, OpRecord) closely.
// Differences: no convenience accessors beyond `values`; OpRecord stores opsData only; one #Index on
// ObjectLink.fieldID (the real models declare none; the spike spec asks for a link fieldId index).

@Model
final class ClassDef {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "circle"
    var colorRole: String = "neutral"
    var traitsRaw: [String] = []
    var systemKey: String?
    var sortIndex: Int = 0
    var createdAt: Date = Date.now
    var packageID: String?
    var packageVersion: Int = 0
    var isUserModified: Bool = false
    var parent: ClassDef?
    @Relationship(deleteRule: .nullify, inverse: \ClassDef.parent) var subclasses: [ClassDef]? = []
    @Relationship(deleteRule: .cascade, inverse: \FieldDef.owner) var ownFields: [FieldDef]? = []
    @Relationship(deleteRule: .nullify, inverse: \ObjectRecord.classDef) var objects: [ObjectRecord]? = []
    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.toClass) var incomingLinks: [ObjectLink]? = []
    @Relationship(deleteRule: .cascade, inverse: \ViewDef.classDef) var views: [ViewDef]? = []

    init(name: String, systemKey: String?) {
        id = .v7()
        self.name = name
        self.systemKey = systemKey
    }
}

@Model
final class FieldDef {
    var id: UUID = UUID()
    var name: String = ""
    var key: String = ""
    var kindRaw: String = "text"
    var sortIndex: Int = 0
    var isRequired: Bool = false
    var unit: String?
    var enumOptions: [String] = []
    var targetClassID: UUID?
    var expression: String?
    var defaultValueData: Data?
    var overridesFieldID: UUID?
    var isUserModified: Bool = false
    var owner: ClassDef?

    init(key: String, kind: String) {
        id = .v7()
        name = key
        self.key = key
        kindRaw = kind
    }
}

@Model
final class ObjectRecord {
    var id: UUID = UUID()
    var title: String = ""
    var sortIndex: Int = 0
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var deletedAt: Date?
    @Attribute(.externalStorage) var valuesData: Data?
    var isClassObject: Bool = false
    var classDef: ClassDef?
    var parent: ObjectRecord?
    @Relationship(deleteRule: .cascade, inverse: \ObjectRecord.parent) var children: [ObjectRecord]? = []
    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.from) var outgoingLinks: [ObjectLink]? = []
    @Relationship(deleteRule: .cascade, inverse: \ObjectLink.toObject) var incomingLinks: [ObjectLink]? = []

    init(title: String, createdAt: Date) {
        id = .v7(at: createdAt)
        self.title = title
        self.createdAt = createdAt
        updatedAt = createdAt
    }

    var values: FieldValues {
        valuesData.flatMap { try? JSONDecoder().decode(FieldValues.self, from: $0) } ?? FieldValues()
    }
}

@Model
final class ObjectLink {
    #Index<ObjectLink>([\.fieldID])
    var id: UUID = UUID()
    var fieldID: UUID = UUID()
    var sortIndex: Int = 0
    var createdAt: Date = Date.now
    var from: ObjectRecord?
    var toObject: ObjectRecord?
    var toClass: ClassDef?

    init(fieldID: UUID) {
        id = .v7()
        self.fieldID = fieldID
    }
}

@Model
final class ViewDef {
    var id: UUID = UUID()
    var name: String = ""
    var layoutRaw: String = "list"
    var classDef: ClassDef?
    init() {}
}

@Model
final class OpRecord {
    var id: UUID = UUID()
    var action: String = ""
    var actorRaw: String = "user"
    var stateRaw: String = "committed"
    var summary: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var opsData: Data?
    var objectIDs: [UUID] = []
    init(action: String, summary: String, opsData: Data, objectIDs: [UUID]) {
        id = .v7()
        self.action = action
        self.summary = summary
        self.opsData = opsData
        self.objectIDs = objectIDs
    }
}

let sdModels: [any PersistentModel.Type] = [
    ClassDef.self, FieldDef.self, ObjectRecord.self, ObjectLink.self, ViewDef.self, OpRecord.self,
]
