import Foundation
import SwiftData

// CloudKit-compatible SwiftData models: every stored property is optional or
// defaulted, no unique constraints, and all relationships are optional with inverses.

/// A user-defined kind of thing to track (e.g. "Workout", "Book", "Task").
@Model
final class AppType {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "square.grid.2x2"
    var colorHex: String = "#5856D6"
    var sortIndex: Int = 0
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \FieldDef.appType)
    var fields: [FieldDef]? = []

    @Relationship(deleteRule: .cascade, inverse: \Record.appType)
    var records: [Record]? = []

    @Relationship(deleteRule: .cascade, inverse: \ViewDef.appType)
    var views: [ViewDef]? = []

    init(name: String = "", symbolName: String = "square.grid.2x2") {
        self.name = name
        self.symbolName = symbolName
    }
}

/// A field in an `AppType`'s schema.
@Model
final class FieldDef {
    enum Kind: String, Codable, CaseIterable {
        case text, number, bool, date, choice, duration
    }

    var id: UUID = UUID()
    var name: String = ""
    var kindRaw: String = Kind.text.rawValue
    var sortIndex: Int = 0
    var isRequired: Bool = false
    /// Options for `.choice` fields.
    var choices: [String] = []
    var appType: AppType?

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    init(name: String = "", kind: Kind = .text, sortIndex: Int = 0) {
        self.name = name
        kindRaw = kind.rawValue
        self.sortIndex = sortIndex
    }
}

/// One entry of an `AppType`. Field values are stored as JSON keyed by `FieldDef.id`.
@Model
final class Record {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var dueAt: Date?
    var isDone: Bool = false
    @Attribute(.externalStorage) var valuesData: Data?
    var appType: AppType?

    init(title: String = "", dueAt: Date? = nil) {
        self.title = title
        self.dueAt = dueAt
    }
}

/// A saved presentation of an `AppType`'s records (list, board, calendar…).
@Model
final class ViewDef {
    enum Layout: String, Codable, CaseIterable {
        case list, board, calendar, gallery
    }

    var id: UUID = UUID()
    var name: String = ""
    var layoutRaw: String = Layout.list.rawValue
    var sortIndex: Int = 0
    var filterData: Data?
    var appType: AppType?

    var layout: Layout {
        get { Layout(rawValue: layoutRaw) ?? .list }
        set { layoutRaw = newValue.rawValue }
    }

    init(name: String = "", layout: Layout = .list) {
        self.name = name
        layoutRaw = layout.rawValue
    }
}
