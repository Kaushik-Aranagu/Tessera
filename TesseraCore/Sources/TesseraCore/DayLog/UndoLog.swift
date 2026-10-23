import Foundation

/// One change that can still be put back (Together round 9, 164, switch undoLogV2): a sentence and one Undo.
public struct UndoEntry: Equatable, Sendable, Identifiable {
    public let id: UUID
    /// What happened in plain words: "Moved Limes to To get." A private, walled or money change reads its generic
    /// summary ("Money moved") instead: no name, no amount.
    public let sentence: String
    public let at: Date
    /// Inside the 10 minutes the page foot offers; older ones are only on the Review list.
    public let isRecent: Bool
    /// A money move: Undo reads "Reversed", and the log keeps both the move and the reversal.
    public let isMoney: Bool
}

public enum UndoOutcome: Equatable, Sendable {
    /// "Put back."
    case putBack(line: String)
    /// Something changed since, so it was left as it is (nothing partial happens).
    case blocked(line: String)
    /// The change is gone or was already undone.
    case gone
}

/// Undo from the op log: every change already wrote an OpRecord, so any change of the last 10 minutes can be put back,
/// one op or one batch, never part of one. Derived from the log on every read; nothing is stored. Walls hold: undo
/// never brings back a purged private item, and no sentence names a private or money thing.
@MainActor
public enum UndoLog {
    public static let window: TimeInterval = 600
    static let putBack = "Put back."
    static let blocked = "Can't put that back."

    /// The newest change inside the 10 minutes, for the page foot.
    public static func latest(engine: ActionEngine, now: Date) -> UndoEntry? {
        recent(engine: engine, now: now, limit: 1).first(where: \.isRecent)
    }

    /// The last `limit` changes by him or Tess, newest first (Settings > Review > Recent changes uses 20).
    public static func recent(engine: ActionEngine, now: Date, limit: Int = 20) -> [UndoEntry] {
        var entries: [UndoEntry] = []
        for record in engine.history(limit: 300) where entries.count < limit {
            guard record.state == .committed, record.actor != .system, !record.ops.isEmpty else { continue }
            let money = isMoney(record, engine: engine)
            entries.append(UndoEntry(
                id: record.id,
                sentence: sentence(for: record, money: money, engine: engine),
                at: record.createdAt,
                isRecent: now.timeIntervalSince(record.createdAt) <= window,
                isMoney: money
            ))
        }
        return entries
    }

    /// Puts one change back. All of it or none of it.
    @discardableResult
    public static func undo(_ id: UUID, engine: ActionEngine) -> UndoOutcome {
        guard let record = engine.store.context.operations[id], record.state == .committed else { return .gone }
        // A purged private item stays gone: its words were scrubbed from the log, so restoring it would bring back an
        // empty shell and a link to nothing.
        for case let .softDelete(object) in record.ops {
            if engine.store.object(id: object)?.title == TessMemoryStore.redacted {
                return .blocked(line: blocked)
            }
        }
        let outcome = engine.undo(record)
        if case .partial = outcome {
            // Some ops no longer fit: take back what was taken back, so nothing is half done.
            engine.redo(record)
            return .blocked(line: blocked)
        }
        return .putBack(line: putBack)
    }

    private static func isMoney(_ record: OpRecord, engine: ActionEngine) -> Bool {
        record.objectIDs.contains { id in
            guard let classDef = engine.store.object(id: id)?.classDef else { return false }
            return ClassResolver.app(for: classDef) == .money
        }
    }

    /// Records that read their generic summary whatever their text says: money, and the body, health and calorie
    /// records (Me, a Health sync).
    private static let genericActions: Set<String> = ["syncHealth", "syncCalendar"]

    private static func isBodyOrHealth(_ record: OpRecord, engine: ActionEngine) -> Bool {
        if genericActions.contains(record.action) {
            return true
        }
        guard let me = engine.classes[.meProfile] else { return false }
        return record.objectIDs.contains { id in
            engine.store.object(id: id)?.classDef.map { ClassResolver.isSubclass($0, of: me) } ?? false
        }
    }

    private static func sentence(for record: OpRecord, money: Bool, engine: ActionEngine) -> String {
        let store = engine.store
        let touchedPrivate = record.objectIDs.contains { id in
            store.object(id: id).map { ObjectPrivacy.shownLabel(of: $0, in: store, classes: engine.classes) != nil }
                ?? false
        }
        let generic = record.summary.hasSuffix(".") ? record.summary : record.summary + "."
        if money || touchedPrivate || isBodyOrHealth(record, engine: engine) {
            return generic
        }
        let text = record.receipt ?? record.summary
        // The stored text may name something that has since been retitled, so it is checked itself too: a private
        // word, a secret, or a money or body fact reads the generic summary.
        if ObjectPrivacy.containsPrivateWord(text, in: store) || SecretWords.mentions(text)
            || PrivateFacts.isWalled(text, lastWeightKg: BodyWeight.lastKg(in: store))
            || PrivateFacts.isCalorieShaped(text)
        {
            return generic
        }
        return text.hasSuffix(".") ? text : text + "."
    }
}
