import Foundation
import TesseraCore

/// What was sent to Claude, on the phone only (G653): one row per built request, beside its Tess Call row and linked
/// by `requestID`. The words are exactly as sent; a walled phrase (a secret, money, a body fact) is stored as "Private
/// phrase", and a key-shaped one too, so the log never holds the key. Written without ops, never in a backup copy, the
/// iCloud copy or an export (`PrivateWords.localOnlyClassKeys`). Tess Call keeps the numbers, so clearing the words
/// never touches the spend.
@MainActor
public struct TessSentLog {
    public static let privatePhrase = "Private phrase"
    /// A payload too large to keep (a recipe page's text): the row shows the job, time, size, model and cost only.
    public static let heldBackPayload = "Held back on this phone"
    /// The receipt for "Clear what was sent": plain, and there is no UNDO.
    public static let clearedLine = "Cleared what was sent."

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]
    public let flags: ClaudeMissFlags?

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef], flags: ClaudeMissFlags? = nil) {
        self.store = store
        self.classes = classes
        self.flags = flags
    }

    /// Newest first.
    public func entries() -> [ObjectRecord] {
        guard let sentClass = classes[.tessSent] else { return [] }
        return store.objects(of: sentClass).filter { !$0.isDeleted }.sorted { $0.createdAt > $1.createdAt }
    }

    public var count: Int {
        entries().count
    }

    /// The words of a row, as stored.
    public func words(of entry: ObjectRecord) -> String {
        store.value("words", of: entry)?.stringValue ?? ""
    }

    /// What a row shows, judged again now (QA on #1110): a row written before a wall or word-list change still reads
    /// "Private phrase" if its phrase is walled today, and a context line that is walled today is dropped. The row
    /// itself is not rewritten. Builder B's Receipts list calls this, never `words(of:)`.
    public func shownWords(of entry: ObjectRecord) -> String {
        let lastKg = BodyWeight.lastKg(in: store)
        func walled(_ text: String) -> Bool {
            text != Self.privatePhrase && text != Self.heldBackPayload
                && (looksLikeClaudeKey(text) || SecretWords.mentions(text) || PrivateFacts.isWalled(
                    text,
                    lastWeightKg: lastKg
                ))
        }
        let lines = words(of: entry).components(separatedBy: "\n")
        guard let first = lines.first else { return Self.privatePhrase }
        return ([walled(first) ? Self.privatePhrase : first] + lines.dropFirst().filter { !walled($0) })
            .joined(separator: "\n")
    }

    /// Requests held back on the phone (a walled or cook phrase, too long, or at the month cap): how many never left.
    public var heldBackCount: Int {
        flags?.heldBack ?? 0
    }

    /// Writes the row for one built request.
    @discardableResult
    func record(words: String, context: [String] = [], use: TessUse, requestID: String?, at date: Date,
                exact: Bool = false) -> ObjectRecord?
    {
        guard let sentClass = classes[.tessSent] else { return nil }
        // Lab mode (`exact`) keeps the words as sent, health and money included; a key-shaped string never goes in.
        let walled = looksLikeClaudeKey(words) || (!exact && (SecretWords.mentions(words)
                || PrivateFacts.isWalled(words, lastWeightKg: BodyWeight.lastKg(in: store))))
        // The phrase, then whatever rode with it (his date, the workout and last set in focus), exactly as sent.
        let lines = context.filter { !looksLikeClaudeKey($0) }
        let stored = ([walled ? Self.privatePhrase : words] + lines).joined(separator: "\n")
        trim(now: date)
        guard let row = try? store.create(sentClass, title: "\(use.rawValue) request") else { return nil }
        row.createdAt = date
        try? store.set("use", to: .text(use.rawValue), on: row)
        try? store.set("words", to: .text(stored), on: row)
        try? store.set("requestID", to: requestID.map(FieldValue.text), on: row)
        return row
    }

    /// The log keeps 30 days and 500 rows, whichever comes first (the oldest go).
    public static let maxAge: TimeInterval = 30 * 24 * 3600
    public static let maxRows = 500

    func trim(now: Date) {
        let all = entries() // newest first
        for (index, entry) in all.enumerated() where index >= Self.maxRows - 1
            || now.timeIntervalSince(entry.createdAt) > Self.maxAge
        {
            store.context.delete(entry)
        }
    }

    /// "Clear what was sent": deletes every row for good (no UNDO, no op). The spend in Tess Call stays.
    @discardableResult
    public func clear() -> String {
        for entry in entries() {
            store.context.delete(entry)
        }
        store.save()
        return Self.clearedLine
    }
}
