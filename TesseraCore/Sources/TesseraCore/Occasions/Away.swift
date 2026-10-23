import Foundation

/// Marks one occasion as the trip Home is quiet for. Never automatic: only this action sets it, and one UNDO takes it
/// back. Turning one on turns any other off, so at most one occasion is away. The flag does nothing outside the
/// occasion's own days: the day after the last day Home is Home again with no action.
public struct SetAway: EngineAction {
    public static let descriptor = ActionDescriptor(
        name: "setAway", summary: "Mark an occasion as away, or not",
        parameters: [
            .init("occasion", .object, "The occasion"),
            .init("on", .boolean, "True to be away for it"),
        ], isOfferedToModel: false
    )

    public var occasion: UUID
    public var on: Bool

    public init(occasion: UUID, on: Bool) {
        self.occasion = occasion
        self.on = on
    }

    public func apply(_ transaction: inout Transaction) throws {
        let record = try OccasionRules.occasion(occasion, in: transaction, action: Self.descriptor.name)
        if on, let key = transaction.classes[.occasion] {
            for other in transaction.store.objects(of: key) where other.id != record.id
                && transaction.store.value("away", of: other) == .bool(true)
            {
                try transaction.set("away", to: .bool(false), on: other)
            }
        }
        try transaction.set("away", to: .bool(on), on: record)
    }

    public func summary(in _: ObjectStore) -> String {
        on ? "Away on" : "Away off"
    }
}

/// The trip Home is quiet for (Together round 14, switch awayV2): "Trip, day 2 of 3. Packing is done." Derived on
/// every read, never stored. Only words and the day count: no pool, amount or money word ever appears, and a title
/// that has since become private or turned into a pool's name reads "Away".
@MainActor
public enum Away {
    /// The occasion that is marked away and whose days include today (the 4 AM day), else nil.
    public static func current(engine: ActionEngine, now: Date, calendar: Calendar = .current) -> ObjectRecord? {
        guard let key = engine.classes[.occasion] else { return nil }
        return engine.store.objects(of: key).first { occasion in
            !occasion.isDeleted && engine.store.value("away", of: occasion) == .bool(true)
                && day(of: occasion, store: engine.store, now: now, calendar: calendar) != nil
        }
    }

    /// Day N of M of a trip today, or nil when today is before its first day or after its last.
    public static func day(of occasion: ObjectRecord, store: ObjectStore, now: Date, calendar: Calendar = .current)
        -> (day: Int, of: Int)?
    {
        guard let start = store.value("start", of: occasion)?.dateValue else { return nil }
        let end = store.value("end", of: occasion)?.dateValue ?? start
        let tesseraDay = TesseraDay(calendar: calendar)
        let first = calendar.startOfDay(for: start), last = calendar.startOfDay(for: end)
        let today = calendar.startOfDay(for: tesseraDay.day(of: now))
        guard today >= first, today <= last,
              let total = calendar.dateComponents([.day], from: first, to: last).day,
              let passed = calendar.dateComponents([.day], from: first, to: today).day else { return nil }
        return (passed + 1, total + 1)
    }

    /// True while Home should be quiet for a trip.
    public static func isAway(engine: ActionEngine, now: Date, calendar: Calendar = .current) -> Bool {
        current(engine: engine, now: now, calendar: calendar) != nil
    }

    /// "Trip, day 2 of 3. Packing is done." Nil when no trip is away today.
    public static func line(engine: ActionEngine, now: Date, calendar: Calendar = .current) -> String? {
        let store = engine.store, classes = engine.classes
        guard let occasion = current(engine: engine, now: now, calendar: calendar),
              let position = day(of: occasion, store: store, now: now, calendar: calendar) else { return nil }
        let title = OccasionRules.plainTitle(occasion.title, in: store, classes: classes) ?? "Away"
        var text = "\(title), day \(position.day) of \(position.of)."
        if let packing = packing(of: occasion, store: store, classes: classes) {
            text += " " + packing
        }
        return text
    }

    /// The packing list's own line, from the first plain linked list with "pack" in its name.
    private static func packing(of occasion: ObjectRecord, store: ObjectStore,
                                classes: [SystemCatalog.Key: ClassDef]) -> String?
    {
        let contents = ListContents(store: store, classes: classes)
        for thing in store.linkedObjects("links", of: occasion) where !thing.isDeleted {
            guard let classDef = thing.classDef, let list = classes[.list],
                  ClassResolver.isSubclass(classDef, of: list),
                  thing.title.lowercased().contains("pack"),
                  ObjectPrivacy.shownLabel(of: thing, in: store, classes: classes) == nil else { continue }
            let items = contents.items(of: thing)
            guard !items.isEmpty else { return nil }
            let left = items.count { !$0.isDone }
            return left == 0 ? "Packing is done." : "Packing, \(left) left of \(items.count)."
        }
        return nil
    }
}
