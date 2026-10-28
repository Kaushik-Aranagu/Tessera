import Foundation

// Money pools, PR 2: the actions (Part B, B3). None is offered to the model or Claude; every one is one op with one
// UNDO. Summaries are generic (no pool name, amount or rate ever lands in the op log); the receipt, shown on screen
// only, carries the amounts. Every amount is `Decimal` from the typed digits.

enum PoolRules {
    static let sources = ["paycheck", "freelance", "gift", "refund", "sale"]
    static let kinds = ["account", "cash", "saving"]

    /// Typed digits that are a positive amount, else nil.
    static func positive(_ typed: String?) -> Decimal? {
        guard let typed, typed.wholeMatch(of: /\s*[\d,]+(?:\.\d+)?\s*/) != nil else { return nil }
        let value = PoolBook.decimal(typed)
        return value > 0 ? value : nil
    }

    static func currencyCode(_ code: String?) -> String {
        let trimmed = (code ?? "").trimmingCharacters(in: .whitespaces).uppercased()
        return trimmed.isEmpty ? "USD" : trimmed
    }

    /// The currency a pool holds, "USD" when none is set.
    @MainActor
    static func code(of pool: ObjectRecord?, in store: ObjectStore) -> String {
        currencyCode(pool.flatMap { store.value("currency", of: $0)?.stringValue })
    }

    static func isCode(_ code: String) -> Bool {
        code.wholeMatch(of: /[A-Z]{3}/) != nil
    }

    static func mismatch(_ action: String, holds currency: String) -> ActionError {
        .invalidArguments(action: action, reason: "That pool holds \(currency)")
    }

    /// A pool's name wherever a receipt shows it: "Private pool" for a walled name.
    @MainActor
    static func shown(_ pool: ObjectRecord, in store: ObjectStore) -> String {
        ObjectPrivacy.isPrivateWord(pool.title, in: store) ? ObjectPrivacy.poolLabel : pool.title
    }
}

public extension Transaction {
    /// The pool a new row defaults to for a currency (see `PoolBook.lastUsedPool`).
    @MainActor
    func lastUsedPool(currency: String) -> ObjectRecord? {
        PoolBook(store: store, classes: classes).lastUsedPool(currency: currency)
    }

    /// "Unassigned USD": the pool a spend or inflow lands in when no pool fits. Made in the same op on first need.
    @MainActor
    mutating func unassignedPool(currency: String) throws -> ObjectRecord {
        let id = SystemCatalog.stableID("money.unassigned.\(currency)")
        if let existing = store.object(id: id), !existing.isDeleted {
            return existing
        }
        let pool = try create(classDef(.pool), title: "Unassigned \(currency)", id: id)
        try set("currency", to: .text(currency), on: pool)
        try set("poolKind", to: .choice("account"), on: pool)
        try set("openingTyped", to: .text("0.00"), on: pool)
        return pool
    }
}

/// Starts a pool: where money sits, in one currency.
public struct CreatePool: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "createPool", summary: "Start a money pool",
        parameters: [
            .init("name", .string, "What the pool is, e.g. India account"),
            .init("currency", .string, "ISO code, e.g. USD or INR; USD if not said", required: false),
            .init("source", .string, "Where its money comes from, e.g. Acme payroll", required: false),
            .init("kind", .string, "account, cash or saving", required: false),
            .init("opening", .string, "What it held when you started it, e.g. 1200.00", required: false),
        ], isOfferedToModel: false
    )

    public var name: String
    public var currency: String?
    public var source: String?
    public var kind: String?
    public var opening: String?

    public init(name: String, currency: String? = nil, source: String? = nil, kind: String? = nil,
                opening: String? = nil)
    {
        self.name = name
        self.currency = currency
        self.source = source
        self.kind = kind
        self.opening = opening
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !looksLikeClaudeKey(name), !SecretWords.mentions(name) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that can't be a pool name")
        }
        let code = PoolRules.currencyCode(currency)
        guard PoolRules.isCode(code) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "that isn't a currency code")
        }
        let kind = (kind ?? "account").lowercased()
        guard PoolRules.kinds.contains(kind) else {
            throw ActionError.invalidArguments(
                action: Self.descriptor.name,
                reason: "a pool is an account, cash or saving"
            )
        }
        var opening = "0.00"
        if let typed = self.opening?.trimmingCharacters(in: .whitespaces), !typed.isEmpty {
            guard typed.wholeMatch(of: /[\d,]+(?:\.\d+)?/) != nil else {
                throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "the opening needs digits")
            }
            opening = typed
        }
        let pool = try transaction.create(transaction.classDef(.pool), title: name)
        try transaction.set("currency", to: .text(code), on: pool)
        try transaction.set("poolKind", to: .choice(kind), on: pool)
        try transaction.set("openingTyped", to: .text(opening), on: pool)
        if let source = source?.trimmingCharacters(in: .whitespacesAndNewlines), !source.isEmpty {
            try transaction.set("source", to: .text(source), on: pool)
        }
        return pool
    }

    public func summary(in _: ObjectStore) -> String {
        "New pool"
    }

    public func receipt(in store: ObjectStore, output pool: ObjectRecord) -> String? {
        "\(PoolRules.shown(pool, in: store)), started"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }
}

/// Money in: a paycheck, a gift, a refund. Lands in the pool given, else the one used last for the currency, else
/// "Unassigned". A pool in another currency is refused; so is an amount that is not a positive number.
public struct LogInflow: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "logInflow", summary: "Log money in",
        parameters: [
            .init("amount", .string, "The amount as typed, e.g. 3200 or 3,200.00"),
            .init("pool", .object, "The pool; the one used last for the currency if not said", required: false),
            .init("currency", .string, "ISO code; USD if not said", required: false),
            .init("source", .string, "paycheck, freelance, gift, refund or sale", required: false),
            .init("note", .string, "A few words", required: false),
            .init("at", .date, "When; defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var amount: String
    public var pool: UUID?
    public var currency: String?
    public var source: String?
    public var note: String?
    public var at: Date?

    public init(amount: String, pool: UUID? = nil, currency: String? = nil, source: String? = nil, note: String? = nil,
                at: Date? = nil)
    {
        self.amount = amount
        self.pool = pool
        self.currency = currency
        self.source = source
        self.note = note
        self.at = at
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = Self.descriptor.name
        guard let value = PoolRules.positive(amount) else {
            throw ActionError.invalidArguments(action: name, reason: "money in must be a positive amount")
        }
        let source = (source ?? "paycheck").lowercased()
        guard PoolRules.sources.contains(source) else {
            throw ActionError.invalidArguments(action: name, reason: "that isn't a source of money")
        }
        let book = PoolBook(store: transaction.store, classes: transaction.classes)
        let target: ObjectRecord
        if let pool {
            target = try transaction.object(pool, is: .pool)
            let held = book.currency(of: target)
            if let asked = currency.map(PoolRules.currencyCode), asked != held {
                throw PoolRules.mismatch(name, holds: held)
            }
        } else {
            let code = PoolRules.currencyCode(currency)
            guard PoolRules.isCode(code) else {
                throw ActionError.invalidArguments(action: name, reason: "that isn't a currency code")
            }
            target = try transaction.lastUsedPool(currency: code) ?? transaction.unassignedPool(currency: code)
        }
        let inflow = try transaction.create(transaction.classDef(.inflow), title: source.capitalized)
        try transaction.setLinks("pool", on: inflow, to: [target])
        try transaction.set("amountTyped", to: .text(amount.trimmingCharacters(in: .whitespaces)), on: inflow)
        try transaction.set("source", to: .choice(source), on: inflow)
        try transaction.set("at", to: .date(at ?? .now), on: inflow)
        if let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            try transaction.set("note", to: .text(note), on: inflow)
        }
        _ = value
        return inflow
    }

    public func summary(in _: ObjectStore) -> String {
        "Money in"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in store: ObjectStore, output inflow: ObjectRecord) -> String? {
        let pool = store.linkedObjects("pool", of: inflow).first
        let currency = PoolRules.code(of: pool, in: store)
        let value = PoolBook.decimal(store.value("amountTyped", of: inflow)?.stringValue)
        let source = store.value("source", of: inflow)?.stringValue ?? "paycheck"
        return "Got \(PoolFormat.amount(value, currency: currency, text: true)), \(source)"
    }
}

/// Moves a spend to another pool of the same currency.
public struct ReassignSpend: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "reassignSpend", summary: "Move a spend to another pool",
        parameters: [.init("spend", .object, "The spend"), .init("pool", .object, "The pool")], isOfferedToModel: false
    )

    public var spend: UUID
    public var pool: UUID

    public init(spend: UUID, pool: UUID) {
        self.spend = spend
        self.pool = pool
    }

    public func apply(_ transaction: inout Transaction) throws {
        let row = try transaction.object(spend, is: .spend)
        let target = try transaction.object(pool, is: .pool)
        let held = PoolBook(store: transaction.store, classes: transaction.classes).currency(of: target)
        let spendCurrency = PoolRules.currencyCode(transaction.store.value("currency", of: row)?.stringValue)
        guard spendCurrency == held else {
            throw PoolRules.mismatch(Self.descriptor.name, holds: held)
        }
        try transaction.setLinks("pool", on: row, to: [target])
    }

    public func summary(in _: ObjectStore) -> String {
        "Spend moved to another pool"
    }

    public func receipt(in store: ObjectStore) -> String? {
        store.object(id: pool).map { "Moved to \(PoolRules.shown($0, in: store))" }
    }
}

/// Moves money between two pools. A move across currencies also notes the rate it implies, in the same op, so undoing
/// the move removes the rate. Within one currency what arrives is what was sent.
public struct LogMove: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "logMove", summary: "Move money between pools",
        parameters: [
            .init("from", .object, "The pool it leaves"), .init("to", .object, "The pool it arrives in"),
            .init("sent", .string, "What you sent, in the first pool's currency"),
            .init("arrived", .string, "What arrived, in the second pool's currency"),
            .init("fee", .string, "The fee, in the first pool's currency; none if not said", required: false),
            .init("at", .date, "When; defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var from: UUID
    public var to: UUID // swiftlint:disable:this identifier_name
    public var sent: String
    public var arrived: String
    public var fee: String?
    public var at: Date?

    public init(from: UUID, to: UUID, sent: String, arrived: String, fee: String? = nil, at: Date? = nil) {
        self.from = from
        self.to = to
        self.sent = sent
        self.arrived = arrived
        self.fee = fee
        self.at = at
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let name = Self.descriptor.name
        guard from != to else {
            throw ActionError.invalidArguments(action: name, reason: "a move needs two different pools")
        }
        let source = try transaction.object(from, is: .pool)
        let target = try transaction.object(to, is: .pool)
        guard let sentValue = PoolRules.positive(sent), let arrivedValue = PoolRules.positive(arrived) else {
            throw ActionError.invalidArguments(action: name, reason: "what you sent and what arrived must be positive")
        }
        var feeValue = Decimal(0)
        if let fee = fee?.trimmingCharacters(in: .whitespaces), !fee.isEmpty {
            guard fee.wholeMatch(of: /[\d,]+(?:\.\d+)?/) != nil else {
                throw ActionError.invalidArguments(action: name, reason: "the fee needs digits")
            }
            feeValue = PoolBook.decimal(fee)
        }
        let book = PoolBook(store: transaction.store, classes: transaction.classes)
        let fromCurrency = book.currency(of: source), toCurrency = book.currency(of: target)
        if fromCurrency == toCurrency, arrivedValue != sentValue {
            throw ActionError.invalidArguments(
                action: name,
                reason: "Within one currency, what arrives is what was sent"
            )
        }
        let move = try transaction.create(transaction.classDef(.poolMove), title: "Move")
        try transaction.setLinks("fromPool", on: move, to: [source])
        try transaction.setLinks("toPool", on: move, to: [target])
        try transaction.set("sentTyped", to: .text(sent.trimmingCharacters(in: .whitespaces)), on: move)
        try transaction.set(
            "feeTyped",
            to: .text(feeValue == 0 ? "0" : (fee ?? "0").trimmingCharacters(in: .whitespaces)),
            on: move
        )
        try transaction.set("arrivedTyped", to: .text(arrived.trimmingCharacters(in: .whitespaces)), on: move)
        let when = at ?? .now
        try transaction.set("at", to: .date(when), on: move)
        if fromCurrency != toCurrency {
            let figures = PoolBook.MoveFigures(sent: sentValue, fee: feeValue, arrived: arrivedValue)
            if let rate = figures.effectiveRate {
                let note = try transaction.create(transaction.classDef(.rateNote), title: "Rate")
                try transaction.set("pair", to: .text("\(fromCurrency)/\(toCurrency)"), on: note)
                try transaction.set("valueTyped", to: .text(NSDecimalNumber(decimal: rate).stringValue), on: note)
                try transaction.set("at", to: .date(when), on: note)
                try transaction.set("origin", to: .choice("move"), on: note)
            }
        }
        return move
    }

    public func summary(in _: ObjectStore) -> String {
        "Money moved"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in store: ObjectStore, output move: ObjectRecord) -> String? {
        let sentValue = PoolBook.decimal(store.value("sentTyped", of: move)?.stringValue)
        let arrivedValue = PoolBook.decimal(store.value("arrivedTyped", of: move)?.stringValue)
        let source = store.linkedObjects("fromPool", of: move).first
        let target = store.linkedObjects("toPool", of: move).first
        let fromCode = PoolRules.code(of: source, in: store), toCode = PoolRules.code(of: target, in: store)
        return "Moved \(PoolFormat.amount(sentValue, currency: fromCode, text: true)), got "
            + "\(PoolFormat.amount(arrivedValue, currency: toCode, text: true))"
    }
}

/// Notes a rate by hand: how many of the second currency one of the first buys.
public struct RecordRate: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "recordRate", summary: "Note an exchange rate",
        parameters: [
            .init("pair", .string, "e.g. USD/INR"), .init("value", .string, "e.g. 83.10"),
            .init("at", .date, "When; defaults to now", required: false),
        ], isOfferedToModel: false
    )

    public var pair: String
    public var value: String
    public var at: Date?

    public init(pair: String, value: String, at: Date? = nil) {
        self.pair = pair
        self.value = value
        self.at = at
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let parts = pair.uppercased().split(separator: "/").map(String.init)
        guard parts.count == 2, parts.allSatisfy(PoolRules.isCode), parts[0] != parts[1] else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "a rate is between two currencies")
        }
        guard PoolRules.positive(value) != nil else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "a rate must be a positive number")
        }
        let note = try transaction.create(transaction.classDef(.rateNote), title: "Rate")
        try transaction.set("pair", to: .text(parts.joined(separator: "/")), on: note)
        try transaction.set("valueTyped", to: .text(value.trimmingCharacters(in: .whitespaces)), on: note)
        try transaction.set("at", to: .date(at ?? .now), on: note)
        try transaction.set("origin", to: .choice("typed"), on: note)
        return note
    }

    public func summary(in _: ObjectStore) -> String {
        "Rate noted"
    }

    public func receipt(in _: ObjectStore) -> String? {
        nil
    }

    public func receipt(in store: ObjectStore, output note: ObjectRecord) -> String? {
        let pair = store.value("pair", of: note)?.stringValue ?? ""
        let second = pair.split(separator: "/").last.map(String.init) ?? ""
        let value = PoolBook.decimal(store.value("valueTyped", of: note)?.stringValue)
        return "Rate saved, \(second) \(PoolFormat.rate(value))"
    }
}

/// Puts a pool away. It stays in totals; it is no longer offered for new rows.
public struct ArchivePool: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "archivePool", summary: "Archive a money pool",
        parameters: [.init("pool", .object, "The pool")], isOfferedToModel: false
    )

    public var pool: UUID

    public init(pool: UUID) {
        self.pool = pool
    }

    public func apply(_ transaction: inout Transaction) throws {
        let target = try transaction.object(pool, is: .pool)
        try transaction.set("archivedAt", to: .date(.now), on: target)
    }

    public func summary(in _: ObjectStore) -> String {
        "Pool archived"
    }

    public func receipt(in store: ObjectStore) -> String? {
        store.object(id: pool).map { "\(PoolRules.shown($0, in: store)), archived" }
    }
}
