import Foundation

/// The reader for the settings field `restWeekday` (Calendar numbering, Sunday = 1), Research 146.
///
/// On a rolling plan the rest weekday is out of the pool before the week is spread (RG1), whether or not a rhythm is
/// passed (RG2). A past day reads the value that was in force that day from the settings op log, so changing it later
/// never redraws an old week (RG7). A fixed-days plan never reads it (RW12).
@MainActor
public enum RestWeekday {
    /// Sunday, the day the first launch with the reader writes.
    public static let sunday = 1

    /// One committed change of the field: when, and the values either side.
    struct Change {
        let time: Date
        let old: Int?
        let new: Int?
    }

    /// "Sunday, rest day.": the receipt for setting it, thing first.
    public static func receipt(for weekday: Int) -> String {
        "\(name(of: weekday)), rest day."
    }

    /// "Sunday" for 1 ... "Saturday" for 7.
    public static func name(of weekday: Int) -> String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return names[(weekday - 1 + 7) % 7]
    }

    /// The value now; the settings read of `restWeekday` without needing an engine.
    public static func current(in store: ObjectStore) -> Int? {
        guard let object = store.object(id: SettingsStore.objectID), !object.isDeleted else { return nil }
        return store.number("restWeekday", of: object).map { Int($0) }.flatMap { (1 ... 7).contains($0) ? $0 : nil }
    }

    /// Every change of the field on the settings object, oldest first. Only ones that still stand (undone ones are
    /// not history) unless `standingOnly` is false. Records of any actor count: the first-launch write is Tess's.
    static func changes(in store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]? = nil,
                        standingOnly: Bool = true) -> [Change]
    {
        let settingsClass = store.object(id: SettingsStore.objectID)?.classDef ?? classes?[.settings]
        guard let fieldID = settingsClass.flatMap({ store.field("restWeekday", of: $0)?.id }) else { return [] }
        func weekday(_ value: FieldValue?) -> Int? {
            value?.numericValue.map { Int($0) }.flatMap { (1 ... 7).contains($0) ? $0 : nil }
        }
        return store.context.operations.values
            .filter { (!standingOnly || $0.state == .committed) && $0.objectIDs.contains(SettingsStore.objectID) }
            .sorted { $0.createdAt < $1.createdAt }
            .flatMap { record in
                record.ops.compactMap { op -> Change? in
                    guard case let .setValue(target, id, old, new) = op, target == SettingsStore.objectID,
                          id == fieldID else { return nil }
                    return Change(time: record.createdAt, old: weekday(old), new: weekday(new))
                }
            }
    }

    /// The rest weekday in force on a past day that ended at `end`: the last change before it, else what the first
    /// later change replaced, else `current` (no change on record).
    static func inForce(endingAt end: Date, changes: [Change], current: Int?) -> Int? {
        if let last = changes.last(where: { $0.time < end }) {
            return last.new
        }
        return changes.first?.old ?? current
    }
}

public extension SettingsStore {
    /// The first launch with the reader (Product 11:52 AM PT Oct 16, his Oct 15 "Sun rest"): when nothing has ever
    /// been written to `restWeekday`, writes Sunday as one op, receipt "Sunday, rest day." with UNDO. Once: an UNDO
    /// or a later "Any" leaves a record, so it never writes again. Nil when nothing was written.
    @discardableResult
    func writeFirstRestWeekday() -> OpRecord? {
        let store = engine.store
        guard RestWeekday.current(in: store) == nil,
              RestWeekday.changes(in: store, classes: engine.classes, standingOnly: false).isEmpty else { return nil }
        var settings = read()
        settings.restWeekday = RestWeekday.sunday
        return try? engine.perform(WriteSettings(settings: settings), by: .tess).record
    }
}
