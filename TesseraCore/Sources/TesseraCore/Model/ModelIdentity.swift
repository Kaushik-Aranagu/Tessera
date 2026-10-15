import Foundation

// MARK: Identity

/// Models compare and hash by identity (one instance per id in a context), like the SwiftData models they replace.
extension ClassDef: Hashable {
    public nonisolated static func == (lhs: ClassDef, rhs: ClassDef) -> Bool {
        lhs === rhs
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension FieldDef: Hashable {
    public nonisolated static func == (lhs: FieldDef, rhs: FieldDef) -> Bool {
        lhs === rhs
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension ObjectRecord: Hashable {
    public nonisolated static func == (lhs: ObjectRecord, rhs: ObjectRecord) -> Bool {
        lhs === rhs
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension ObjectLink: Hashable {
    public nonisolated static func == (lhs: ObjectLink, rhs: ObjectLink) -> Bool {
        lhs === rhs
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension OpRecord: Hashable {
    public nonisolated static func == (lhs: OpRecord, rhs: OpRecord) -> Bool {
        lhs === rhs
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension ClassDef: @MainActor Identifiable {}
extension ObjectRecord: @MainActor Identifiable {}
extension OpRecord: @MainActor Identifiable {}
