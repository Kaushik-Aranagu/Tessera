import Foundation

/// A new user class ("New subclass" on a class page): logged, so the 10 s UNDO takes it back. Not offered to Tess.
public struct CreateClass: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "createClass",
        summary: "Create a subclass of a class",
        parameters: [
            .init("parent", .classRef, "The class it extends"),
            .init("name", .string, "Its name", required: false),
        ],
        isOfferedToModel: false
    )

    public var parent: UUID
    public var name: String?

    public init(parent: UUID, name: String? = nil) {
        self.parent = parent
        self.name = name
    }

    public func apply(_ transaction: inout Transaction) throws -> ClassDef {
        guard let parentClass = transaction.store.classDef(id: parent) else {
            throw ActionError.objectNotFound(parent)
        }
        let title = name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "New \(parentClass.name)"
        return transaction.createClass(name: title, parent: parentClass, symbolName: parentClass.symbolName,
                                       colorRole: parentClass.colorRole)
    }

    public func summary(in store: ObjectStore) -> String {
        "Created a subclass of \(store.classDef(id: parent)?.name ?? "a class")"
    }

    public func summary(in _: ObjectStore, output: ClassDef) -> String {
        "Created \(output.name)"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
