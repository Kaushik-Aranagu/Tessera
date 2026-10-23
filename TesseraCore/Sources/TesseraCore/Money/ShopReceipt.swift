import Foundation

/// The receipt total after a shop (Money slice 3): the shop ended by `FinishShop` within the last 2 hours, with no
/// spend linking it and not skipped, is awaiting its total. Asked once: a total or a skip ends it for good.
@MainActor
public struct ShopReceipt {
    /// How long after finishing the question stays open.
    public static let window: TimeInterval = 2 * 3600
    /// Now reads "Groceries total?" while it is awaited and nothing is running.
    public static let prompt = "Groceries total?"

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    /// The shop process still awaiting its total, or nil.
    public func awaiting(at now: Date) -> ObjectRecord? {
        guard let processClass = classes[.process], let spendClass = classes[.spend] else { return nil }
        let linked = Set(store.objects(of: spendClass).filter { !$0.isDeleted }
            .flatMap { store.linkedObjects("about", of: $0).map(\.id) })
        return store.objects(of: processClass).filter { process in
            guard !process.isDeleted,
                  store.value("endReason", of: process)?.stringValue == ProcessEndReason.done.rawValue,
                  let ended = store.value("endedAt", of: process)?.dateValue,
                  store.linkedObjects("subject", of: process).first?.id == Groceries.listID,
                  now >= ended, now.timeIntervalSince(ended) < Self.window,
                  !linked.contains(process.id) else { return false }
            return ResumePoint(encoded: store.value("resumePoint", of: process)?.stringValue)?
                .extras["totalSkipped"] != "1"
        }.max { (store.value("endedAt", of: $0)?.dateValue ?? .distantPast)
            < (store.value("endedAt", of: $1)?.dateValue ?? .distantPast)
        }
    }

    /// Nothing runs and a total is awaited, outside his quiet hours (11 pm to 7 am until he changes them): the Now
    /// slot's words. The question
    /// still shows once at the finish, which is his act (amendment 5).
    public func nowPrompt(at now: Date, calendar: Calendar = .current, somethingRuns: Bool) -> String? {
        guard !somethingRuns, !SettingsStore.quietHours(in: store).contains(now, calendar: calendar),
              awaiting(at: now) != nil else { return nil }
        return Self.prompt
    }
}

/// Logs the shop's total: note "Groceries", category "groceries", about the Groceries list and the ended shop.
public struct LogShopTotal: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "logShopTotal", summary: "Log the groceries total",
        parameters: [
            .init("amount", .number, "The total"),
            .init("typed", .string, "The total as typed", required: false),
            .init("currency", .string, "EUR, GBP, USD or INR, only if said", required: false),
        ], isOfferedToModel: false
    )

    public var amount: Double
    public var typed: String?
    public var currency: String?
    public var time: Date?

    public init(amount: Double, typed: String? = nil, currency: String? = nil, time: Date? = nil) {
        self.amount = amount
        self.typed = typed
        self.currency = currency
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        let now = time ?? .now
        guard let shop = ShopReceipt(store: transaction.store, classes: transaction.classes).awaiting(at: now) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "no groceries total is awaited")
        }
        var links: [UUID] = [shop.id]
        if transaction.store.object(id: Groceries.listID) != nil {
            links.insert(Groceries.listID, at: 0)
        }
        return try LogSpend(amount: amount, typed: typed, currency: currency, note: "Groceries", spentAt: now,
                            about: links).apply(&transaction)
    }

    public func summary(in _: ObjectStore) -> String {
        "Groceries total"
    }

    public func summary(in _: ObjectStore, output spend: ObjectRecord) -> String {
        spend.title
    }

    public func receipt(in store: ObjectStore, output spend: ObjectRecord) -> String? {
        SpendLedger.receiptLine(for: spend, in: store)
    }
}

/// "No total. Fine.": marks the shop skipped, so the question is asked once and never again. One undo ("Groceries
/// total, skipped." then "Groceries total is back.").
public struct SkipShopTotal: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "skipShopTotal", summary: "Skip the groceries total", parameters: [], isOfferedToModel: false
    )

    public var time: Date?

    public init(time: Date? = nil) {
        self.time = time
    }

    public func apply(_ transaction: inout Transaction) throws {
        let now = time ?? .now
        guard let shop = ShopReceipt(store: transaction.store, classes: transaction.classes).awaiting(at: now) else {
            throw ActionError.invalidArguments(action: Self.descriptor.name, reason: "no groceries total is awaited")
        }
        var point = ResumePoint(encoded: transaction.store.value("resumePoint", of: shop)?.stringValue) ?? ResumePoint()
        point.extras["totalSkipped"] = "1"
        try transaction.set("resumePoint", to: point.encoded.map(FieldValue.text), on: shop)
    }

    public func summary(in _: ObjectStore) -> String {
        "Groceries total, skipped"
    }

    public func receipt(in _: ObjectStore) -> String? {
        "Groceries total, skipped."
    }
}
