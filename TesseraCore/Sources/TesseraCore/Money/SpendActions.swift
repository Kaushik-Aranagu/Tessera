import Foundation

/// Logs a spend (Money slice 1). The thing comes first in every line: "12.40 lunch" in the op summary, "12.40 lunch,
/// logged." as the receipt (Money amendment 1). Name-only parameters, so the on-device model and Claude can call it
/// and the result is a pending ghost row.
public struct LogSpend: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "logSpend", summary: "Log a spend",
        parameters: [
            .init("amount", .number, "The amount"),
            .init("typed", .string, "The amount as it was said, e.g. 12.40 or €8", required: false),
            .init("currency", .string, "EUR, GBP, USD or INR, only if said", required: false),
            .init("note", .string, "What it was for, e.g. lunch with sam", required: false),
            .init("spentAt", .date, "When; defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var amount: Double
    public var typed: String?
    public var currency: String?
    public var note: String?
    public var spentAt: Date?
    public var about: [UUID]?

    public init(amount: Double, typed: String? = nil, currency: String? = nil, note: String? = nil,
                spentAt: Date? = nil, about: [UUID]? = nil)
    {
        self.amount = amount
        self.typed = typed
        self.currency = currency
        self.note = note
        self.spentAt = spentAt
        self.about = about
    }

    /// "12.40 lunch": the amount as typed, then the word.
    static func title(typed: String, note: String) -> String {
        note.isEmpty ? typed : "\(typed) \(note)"
    }

    /// One lowercased word: the note's first.
    static func category(of note: String) -> String {
        note.split(separator: " ").first.map { String($0).lowercased() } ?? ""
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        guard amount.isFinite, amount > 0, amount < 1_000_000_000 else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "amount must be a positive number")
        }
        let shown = typed?.trimmingCharacters(in: .whitespaces).nilIfEmpty
            ?? MoneyAmount.format(Decimal(string: String(amount)) ?? Decimal(amount))
        let words = (note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let spend = try transaction.create(transaction.classDef(.spend), title: Self.title(typed: shown, note: words))
        try transaction.set("amount", to: .number(amount), on: spend)
        try transaction.set("typed", to: .text(shown), on: spend)
        try transaction.set("currency", to: .text(currency?.uppercased() ?? ""), on: spend)
        try transaction.set("note", to: .text(words), on: spend)
        try transaction.set("category", to: .text(Self.category(of: words)), on: spend)
        try transaction.set("spentAt", to: .date(spentAt ?? .now), on: spend)
        if let about, !about.isEmpty {
            try transaction.setLinks("about", on: spend, to: about.map { try transaction.object($0) })
        }
        return spend
    }

    public func summary(in _: ObjectStore) -> String {
        Self.title(typed: typed ?? MoneyAmount.format(Decimal(amount)), note: note ?? "")
    }

    public func receipt(in _: ObjectStore, output spend: ObjectRecord) -> String? {
        "\(spend.title), logged."
    }

    public func summary(in _: ObjectStore, output spend: ObjectRecord) -> String {
        spend.title
    }
}

/// Changes a spend: its amount, word or date. One undo.
public struct EditSpend: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "editSpend", summary: "Change a spend",
        parameters: [
            .init("spend", .object, "The spend"),
            .init("amount", .number, "The new amount", required: false),
            .init("typed", .string, "The new amount as typed", required: false),
            .init("currency", .string, "EUR, GBP, USD or INR", required: false),
            .init("note", .string, "What it was for", required: false),
            .init("spentAt", .date, "When", required: false),
        ], isOfferedToModel: false
    )

    public var spend: UUID
    public var amount: Double?
    public var typed: String?
    public var currency: String?
    public var note: String?
    public var spentAt: Date?

    public init(spend: UUID, amount: Double? = nil, typed: String? = nil, currency: String? = nil, note: String? = nil,
                spentAt: Date? = nil)
    {
        self.spend = spend
        self.amount = amount
        self.typed = typed
        self.currency = currency
        self.note = note
        self.spentAt = spentAt
    }

    public func apply(_ transaction: inout Transaction) throws {
        let object = try transaction.object(spend, is: .spend)
        if let amount {
            guard amount.isFinite, amount > 0, amount < 1_000_000_000 else {
                throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "amount must be positive")
            }
            try transaction.set("amount", to: .number(amount), on: object)
        }
        let store = transaction.store
        let shown = typed?.trimmingCharacters(in: .whitespaces).nilIfEmpty
            ?? (amount.map { MoneyAmount.format(Decimal(string: String($0)) ?? Decimal($0)) }
                ?? store.value("typed", of: object)?.stringValue ?? "")
        if typed != nil || amount != nil {
            try transaction.set("typed", to: .text(shown), on: object)
        }
        if let currency {
            try transaction.set("currency", to: .text(currency.uppercased()), on: object)
        }
        if let note {
            let words = note.trimmingCharacters(in: .whitespacesAndNewlines)
            try transaction.set("note", to: .text(words), on: object)
            try transaction.set("category", to: .text(LogSpend.category(of: words)), on: object)
        }
        if let spentAt {
            try transaction.set("spentAt", to: .date(spentAt), on: object)
        }
        let words = store.value("note", of: object)?.stringValue ?? ""
        transaction.setTitle(LogSpend.title(typed: store.value("typed", of: object)?.stringValue ?? shown, note: words),
                             on: object)
    }

    public func summary(in store: ObjectStore) -> String {
        store.object(id: spend)?.title ?? "A spend"
    }

    public func receipt(in store: ObjectStore) -> String? {
        store.object(id: spend).map { "\($0.title), changed." }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
