import Foundation
import SwiftData

/// Runs typed actions and keeps the operation log: commit, pending previews, undo and redo.
///
/// - Every action is one `OpRecord` holding the ops it applied, its actor and a one-line summary.
/// - A pending action (Tess's ghost row) is already applied, so it shows; `commit` makes it final,
///   `discard` reverts it.
/// - Undo and redo replay ops only where the data still looks the way the op left it. Anything changed since
///   (by a later edit or a sync) is left alone and reported as a conflict, never overwritten.
@MainActor
public final class ActionEngine {
    public struct Result<Output> {
        public let record: OpRecord
        public let output: Output
    }

    public enum ReplayOutcome: Equatable {
        case applied
        /// Some ops were skipped because the data changed since; the rest were applied.
        case partial(skipped: [Op])
        case nothingToDo
    }

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]
    /// How long a pending preview waits before `commitExpired` makes it final.
    public var pendingGracePeriod: TimeInterval = 2

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    // MARK: Performing

    /// Runs an action and logs it. If it throws, everything it wrote so far is rolled back.
    @discardableResult
    public func perform<A: EngineAction>(_ action: A, by actor: Actor,
                                         pending: Bool = false) throws -> Result<A.Output>
    {
        var transaction = Transaction(store: store, classes: classes)
        let output: A.Output
        do {
            output = try action.apply(&transaction)
        } catch {
            _ = replay(transaction.ops.reversed().map(\.inverse), guarded: false)
            throw error
        }
        let record = OpRecord(
            action: A.descriptor.name,
            actor: actor,
            summary: action.summary(in: store),
            ops: transaction.ops,
            state: pending ? .pending : .committed
        )
        store.context.insert(record)
        return Result(record: record, output: output)
    }

    /// Decodes a tool call (from Tess, Claude or an intent) and runs it. Dates are ISO 8601.
    @discardableResult
    public func perform(named name: String, arguments: Data, by actor: Actor,
                        pending: Bool = false) throws -> OpRecord
    {
        let action = try ActionRegistry.decode(name: name, arguments: arguments)
        return try performErased(action, by: actor, pending: pending)
    }

    private func performErased(_ action: some EngineAction, by actor: Actor, pending: Bool) throws -> OpRecord {
        try perform(action, by: actor, pending: pending).record
    }

    // MARK: Pending previews

    public func commit(_ record: OpRecord) throws {
        guard record.state == .pending else { throw ActionError.notPending(record.id) }
        record.state = .committed
    }

    /// Reverts a preview the person dismissed.
    @discardableResult
    public func discard(_ record: OpRecord) throws -> ReplayOutcome {
        guard record.state == .pending else { throw ActionError.notPending(record.id) }
        return undo(record)
    }

    /// Commits every preview older than the grace period. Call it from a timer or on the next interaction.
    public func commitExpired(now: Date = .now) {
        for record in pendingRecords() where now.timeIntervalSince(record.createdAt) >= pendingGracePeriod {
            record.state = .committed
        }
    }

    public func pendingRecords() -> [OpRecord] {
        let pending = OpState.pending.rawValue
        let descriptor = FetchDescriptor<OpRecord>(
            predicate: #Predicate { $0.stateRaw == pending },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? store.context.fetch(descriptor)) ?? []
    }

    /// Whether an object only exists or changed because of a preview (draw it as a ghost).
    public func isPending(_ objectID: UUID) -> Bool {
        pendingRecords().contains { $0.objectIDs.contains(objectID) }
    }

    // MARK: Undo & redo

    /// Reverts an action. Works on any committed or pending record, not only the latest.
    @discardableResult
    public func undo(_ record: OpRecord) -> ReplayOutcome {
        guard record.state != .undone else { return .nothingToDo }
        let outcome = replay(record.ops.reversed().map(\.inverse), guarded: true)
        record.state = .undone
        return outcome
    }

    @discardableResult
    public func redo(_ record: OpRecord) -> ReplayOutcome {
        guard record.state == .undone else { return .nothingToDo }
        let outcome = replay(record.ops, guarded: true)
        record.state = .committed
        return outcome
    }

    /// Undoes the latest action, optionally only one by a given actor ("undo what Tess did") or of a given
    /// kind ("undo the last set" from the Lock Screen: `undoLatest(action: LogSet.descriptor.name)`).
    @discardableResult
    public func undoLatest(by actor: Actor? = nil, action: String? = nil) -> OpRecord? {
        let match = { (record: OpRecord) in
            record.state != .undone && (actor == nil || record.actor == actor)
                && (action == nil || record.action == action)
        }
        guard let record = history(limit: 200).first(where: match) else { return nil }
        undo(record)
        return record
    }

    // MARK: History

    /// Newest first.
    public func history(limit: Int = 100) -> [OpRecord] {
        var descriptor = FetchDescriptor<OpRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? store.context.fetch(descriptor)) ?? []
    }

    /// Actions that touched an object, newest first (for the object page's history scrubber).
    public func history(of objectID: UUID, limit: Int = 100) -> [OpRecord] {
        let descriptor = FetchDescriptor<OpRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let all = (try? store.context.fetch(descriptor)) ?? []
        return Array(all.lazy.filter { $0.objectIDs.contains(objectID) }.prefix(limit))
    }

    // MARK: Replay

    private func replay(_ ops: [Op], guarded: Bool) -> ReplayOutcome {
        var skipped: [Op] = []
        for operation in ops where !apply(operation, guarded: guarded) {
            skipped.append(operation)
        }
        return skipped.isEmpty ? .applied : .partial(skipped: skipped)
    }

    /// Applies one op. When guarded, only if the current state still matches the op's "before".
    private func apply(_ operation: Op, guarded: Bool) -> Bool {
        guard let object = store.object(id: operation.objectID) else { return false }
        switch operation {
        case .create, .restore:
            // Redoing a creation brings the same object back.
            return setDeleted(false, object, guarded: guarded)
        case .softDelete:
            return setDeleted(true, object, guarded: guarded)
        case let .setTitle(_, old, new):
            if guarded, object.title != old {
                return false
            }
            object.title = new
            object.updatedAt = .now
            store.noteChange(object)
        case let .setValue(_, field, old, new):
            if guarded, object.values[field] != old {
                return false
            }
            store.setRaw(fieldID: field, to: new, on: object)
        case let .setLinks(_, field, old, new):
            if guarded, store.ownLinkTargets(fieldID: field, of: object) != old {
                return false
            }
            store.setLinksRaw(fieldID: field, on: object, to: new)
        }
        return true
    }

    private func setDeleted(_ deleted: Bool, _ object: ObjectRecord, guarded: Bool) -> Bool {
        guard object.isDeleted != deleted else { return !guarded }
        if deleted {
            store.softDelete(object)
        } else {
            store.restore(object)
        }
        return true
    }
}
