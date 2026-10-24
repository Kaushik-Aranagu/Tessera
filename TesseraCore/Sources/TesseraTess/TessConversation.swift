import Foundation
import TesseraCore

/// Her conversation (sheet 215 rev 5), on the phone only. One row per turn, written without ops (so never in the op
/// log,
/// sync, logs or analytics), kept seven days, and in no backup copy at all (the local one included, the iCloud copy, an
/// export): `Tess Turn` is a mirror class (`PrivateWords.mirrorClassKeys`).
///
/// What is stored is filtered at write time, by class and by words:
/// - an object that is money, health, body or calendar is never named: the turn keeps a placeholder;
/// - a private thing is named by its shown label only;
/// - words that are walled (a secret, money, a body fact, calories) or key-shaped are stored as a placeholder and the
///   turn is held back, so it never goes to Claude;
/// - an unsent draft is never stored: only a turn that was sent or said is handed to `append`.
///
/// Toward Claude, only under `asksClaude`, at most the last few turns, never a held-back turn; a cleared conversation
/// sends nothing. It appears in no widget, Lock Screen, notice, Spotlight, Siri suggestion or Handoff (a test scans).
@MainActor
public struct TessConversation {
    public enum Role: String, Sendable {
        case user, tess
    }

    /// What Claude may be given: a role and plain words.
    public struct Turn: Equatable, Sendable {
        public let role: Role
        public let text: String
    }

    public static let keepDays = 7
    /// Stored in place of walled words or a thing that is not to be named.
    public static let placeholder = "Something private"
    /// The receipt for Clear: plain, and there is no Undo.
    public static let clearedLine = "Cleared"
    public static let claudeTurnLimit = 4

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    // MARK: Reading

    /// Every live turn, oldest first.
    public func turns() -> [ObjectRecord] {
        guard let turnClass = classes[.tessTurn] else { return [] }
        return store.objects(of: turnClass).filter { !$0.isDeleted }.sorted { $0.createdAt < $1.createdAt }
    }

    public var count: Int {
        turns().count
    }

    public func text(of turn: ObjectRecord) -> String {
        store.value("text", of: turn)?.stringValue ?? ""
    }

    public func role(of turn: ObjectRecord) -> Role {
        store.value("role", of: turn)?.stringValue.flatMap(Role.init(rawValue:)) ?? .tess
    }

    public func isHeldBack(_ turn: ObjectRecord) -> Bool {
        store.value("held", of: turn) == .bool(true)
    }

    /// The objects a turn named, still live.
    public func about(_ turn: ObjectRecord) -> [ObjectRecord] {
        store.linkedObjects("about", of: turn).filter { !$0.isDeleted }
    }

    /// Her last turn as the opener needs it: when, and the ids of what it named (a deleted thing included, so a
    /// deletion
    /// counts as a change). No words leave this function.
    public func lastTessTurn() -> TessLastTurn? {
        guard let turn = turns().last(where: { role(of: $0) == .tess }) else { return nil }
        let field = classes[.tessTurn].flatMap { ClassResolver.field("about", of: $0) }
        let ids = (turn.outgoingLinks ?? []).filter { $0.fieldID == field?.id }.compactMap { $0.toObject?.id }
        return TessLastTurn(at: turn.createdAt, about: ids)
    }

    // MARK: Writing

    /// Writes one turn. `about` is what the turn is about (an object he dragged her onto, a thing she named). Returns
    /// nil when the catalog has no turn class. The stored words are the filtered ones.
    @discardableResult
    public func append(role: Role, text: String, about: [ObjectRecord] = [], at date: Date = .now) -> ObjectRecord? {
        guard let turnClass = classes[.tessTurn] else { return nil }
        expire(now: date)
        let weight = BodyWeight.lastKg(in: store)
        var held = false
        var stored = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // A thing that is not to be named, or a private one, holds the turn back from Claude; the words stay only if
        // they
        // are themselves plain.
        let unnameable = about.contains { TessAskRouter.isUnnameable($0, classes: classes) }
        let hidden = about.contains { ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) != nil }
        if unnameable || hidden {
            held = true
        }
        let walled = looksLikeClaudeKey(stored) || SecretWords.mentions(stored) || ObjectPrivacy.containsPrivateWord(
            stored,
            in: store
        )
            || PrivateFacts.isWalled(stored, lastWeightKg: weight) || PrivateFacts.isCalorieShaped(stored)
        if unnameable || stored.isEmpty {
            stored = Self.placeholder
            held = true
        } else if hidden {
            // A private thing is named by its shown label only: the words he said about it are not kept.
            stored = about.compactMap { ObjectPrivacy.shownLabel(of: $0, in: store, classes: classes) }.first
                ?? Self.placeholder
        } else if walled {
            stored = Self.placeholder
            held = true
        }
        guard let row = try? store.create(turnClass, title: "") else { return nil }
        row.createdAt = date
        try? store.set("role", to: .text(role.rawValue), on: row)
        try? store.set("text", to: .text(stored), on: row)
        try? store.set("at", to: .date(date), on: row)
        try? store.set("held", to: .bool(held), on: row)
        let named = about.filter { !$0.isDeleted }
        if !named.isEmpty {
            try? store.setLinks("about", on: row, to: named)
        }
        return row
    }

    // MARK: Toward Claude

    /// The last few turns Claude may be given: only with `asksClaude`, never a held-back one, nothing after a clear.
    public func forClaude(asksClaude: Bool, limit: Int = TessConversation.claudeTurnLimit) -> [Turn] {
        guard asksClaude, limit > 0 else { return [] }
        return turns().suffix(limit).filter { !isHeldBack($0) }.map { Turn(role: role(of: $0), text: text(of: $0)) }
    }

    // MARK: Keeping and clearing

    /// Removes turns older than seven days. Called when the app launches and before every write.
    @discardableResult
    public func expire(now: Date = .now) -> Int {
        var removed = 0
        for turn in turns() where now.timeIntervalSince(turn.createdAt) > Double(Self.keepDays) * 86400 {
            store.context.delete(turn)
            removed += 1
        }
        if removed > 0 {
            store.save()
            store.context.scrubLog()
        }
        return removed
    }

    /// Clear: every turn is erased for good (no Undo, no op).
    @discardableResult
    public func clear() -> String {
        for turn in turns() {
            store.context.delete(turn)
        }
        store.save()
        store.context.scrubLog()
        return Self.clearedLine
    }
}
