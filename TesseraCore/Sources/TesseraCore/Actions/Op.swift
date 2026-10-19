import Foundation

/// Who made a change. Every op carries one, so "undo what Tess did" and receipts are a query.
public enum Actor: String, Codable, Sendable, CaseIterable {
    /// The person, through the UI.
    case user
    /// Tess, the on-device assistant.
    case tess
    /// Siri, Shortcuts, the Action button or a widget, through App Intents.
    case intent
    /// The app itself: seeding, migrations, dedupe.
    case system
}

/// What a link field points at.
public enum LinkTarget: Codable, Hashable, Sendable {
    case object(UUID)
    case classDef(UUID)
}

/// One primitive change to the object graph. Each op carries enough to reverse itself.
public enum Op: Codable, Hashable, Sendable {
    case create(object: UUID, classID: UUID, parent: UUID?, title: String)
    case softDelete(object: UUID)
    case restore(object: UUID)
    case setTitle(object: UUID, old: String, new: String)
    /// Position among siblings (reordering a routine's slots, a workout's entries).
    case setSortIndex(object: UUID, old: Int, new: Int)
    case setValue(object: UUID, field: UUID, old: FieldValue?, new: FieldValue?)
    case setLinks(object: UUID, field: UUID, old: [LinkTarget], new: [LinkTarget])
    /// A new user class (the class page's "New subclass"). Undo removes it, if nothing uses it yet.
    case createClass(classID: UUID, parent: UUID?, name: String, symbolName: String, colorRole: String)
    case deleteClass(classID: UUID, parent: UUID?, name: String, symbolName: String, colorRole: String)

    /// The op that undoes this one.
    public var inverse: Op {
        switch self {
        case let .create(object, _, _, _): .softDelete(object: object)
        case let .softDelete(object): .restore(object: object)
        case let .restore(object): .softDelete(object: object)
        case let .setTitle(object, old, new): .setTitle(object: object, old: new, new: old)
        case let .setSortIndex(object, old, new): .setSortIndex(object: object, old: new, new: old)
        case let .setValue(object, field, old, new): .setValue(object: object, field: field, old: new, new: old)
        case let .setLinks(object, field, old, new): .setLinks(object: object, field: field, old: new, new: old)
        case let .createClass(classID, parent, name, symbol, color):
            .deleteClass(classID: classID, parent: parent, name: name, symbolName: symbol, colorRole: color)
        case let .deleteClass(classID, parent, name, symbol, color):
            .createClass(classID: classID, parent: parent, name: name, symbolName: symbol, colorRole: color)
        }
    }

    /// The object this op touches.
    public var objectID: UUID {
        switch self {
        case let .create(object, _, _, _), let .softDelete(object), let .restore(object),
             let .setTitle(object, _, _), let .setSortIndex(object, _, _), let .setValue(object, _, _, _),
             let .setLinks(object, _, _, _), let .createClass(object, _, _, _, _), let .deleteClass(object, _, _, _, _):
            object
        }
    }
}

/// Lifecycle of a logged action.
public enum OpState: String, Codable, Sendable {
    /// Applied and final.
    case committed
    /// Applied but still a preview (Tess's ghost row); commits on tap or after a moment, or is discarded.
    case pending
    /// Reverted by undo (or a discarded preview). Can be redone.
    case undone
}
