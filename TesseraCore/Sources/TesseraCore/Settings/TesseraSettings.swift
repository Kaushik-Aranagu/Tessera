import Foundation

/// His preferences that travel with a restore (docs/research/settings-object.md, board item 96). Every field is
/// optional: nil means "never set on any phone", and readers apply the defaults, so a stored "Porcelain" means he chose
/// it. Never holds the Claude key (or its last four), the folder bookmark, or anything about this phone's disk.
public struct TesseraSettings: Equatable, Sendable, Codable {
    /// A Look name. Text, not a choice, so an older build keeps a newer build's look.
    public var lookDay: String?
    public var lookNight: String?
    public var lookPinned: String?
    /// Read as `missesGoToClaude ?? true` (typing the key opts in; Product 8:28 PM PT Oct 15).
    public var missesGoToClaude: Bool?
    /// The folder's display name only ("iCloud Drive/Tessera"); never a path or URL.
    public var backupFolderName: String? {
        didSet {
            if let name = backupFolderName, !Self.isDisplayName(name) {
                backupFolderName = oldValue
            }
        }
    }

    public var backupFolderPickedAt: Date?
    /// His rest weekday, 1 to 7 with Sunday as 1 (Calendar numbering). Nil means the engine decides (the floating
    /// rest day); Sunday is only the pre-filled answer he's shown, written when he answers (Product, Oct 15).
    public var restWeekday: Int?

    public init(lookDay: String? = nil, lookNight: String? = nil, lookPinned: String? = nil,
                missesGoToClaude: Bool? = nil, backupFolderName: String? = nil, backupFolderPickedAt: Date? = nil,
                restWeekday: Int? = nil)
    {
        self.lookDay = lookDay
        self.lookNight = lookNight
        self.lookPinned = lookPinned
        self.missesGoToClaude = missesGoToClaude
        self.backupFolderName = backupFolderName.flatMap { Self.isDisplayName($0) ? $0 : nil }
        self.backupFolderPickedAt = backupFolderPickedAt
        self.restWeekday = restWeekday
    }

    /// "Misses go to Claude", with its default.
    public var sendsMissesToClaude: Bool {
        missesGoToClaude ?? true
    }

    /// A display name, not a path: no leading "/", no "file:", no "/private/var" or container ids.
    public static func isDisplayName(_ name: String) -> Bool {
        let lower = name.lowercased()
        return !name.isEmpty && !name.hasPrefix("/") && !lower.hasPrefix("file:") && !lower.contains("/private/")
            && !lower.contains("/var/mobile") && !lower.contains("containers/")
            && name.firstMatch(of: /[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-/) == nil
    }
}

/// Reads and writes the one settings object (fixed id). Every write is one op, so settings ride in the op log,
/// every backup copy and every export. Ops on it never count as his actions for the rolling copy.
@MainActor
public struct SettingsStore {
    /// The settings object's id, the same on every phone.
    public nonisolated static let objectID = SystemCatalog.stableID("settings")

    public let engine: ActionEngine

    public init(engine: ActionEngine) {
        self.engine = engine
    }

    /// All nil until the first write; creates nothing.
    public func read() -> TesseraSettings {
        guard let object = engine.store.object(id: Self.objectID), !object.isDeleted else { return TesseraSettings() }
        let store = engine.store
        func text(_ key: String) -> String? {
            if case let .text(value)? = store.value(key, of: object) {
                return value
            }
            return nil
        }
        var settings = TesseraSettings(lookDay: text("lookDay"), lookNight: text("lookNight"),
                                       lookPinned: text("lookPinned"), backupFolderName: text("backupFolderName"),
                                       backupFolderPickedAt: store.value("backupFolderPickedAt", of: object)?.dateValue,
                                       // Outside 1 to 7 reads as empty: the engine places the rest day.
                                       restWeekday: store.number("restWeekday", of: object).map { Int($0) }
                                           .flatMap { (1 ... 7).contains($0) ? $0 : nil })
        if case let .bool(value)? = store.value("missesGoToClaude", of: object) {
            settings.missesGoToClaude = value
        }
        return settings
    }

    /// One op: reads, applies `change`, writes what changed. `by` is `.system` for the migration.
    @discardableResult
    public func update(by actor: Actor = .user, _ change: (inout TesseraSettings) -> Void) throws -> TesseraSettings {
        var settings = read()
        let before = settings
        change(&settings)
        guard settings != before else { return settings }
        try engine.perform(WriteSettings(settings: settings), by: actor)
        return settings
    }

    /// The release that adds the object (docs/research/settings-object.md, Migration): copies the old keys that are
    /// actually present, once, as `.system`. Never overwrites a field the object has (it may have come back from a
    /// restore), except that "no" wins for misses going to Claude.
    public func migrate(looks: UserDefaults, standard: UserDefaults, folderName: String?) throws {
        func old(_ key: String) -> String? {
            looks.string(forKey: key) ?? standard.string(forKey: key)
        }
        try update(by: .system) { settings in
            settings.lookDay = settings.lookDay ?? old("look.day")
            settings.lookNight = settings.lookNight ?? old("look.night")
            settings.lookPinned = settings.lookPinned ?? old("look.pinned")
            if standard.object(forKey: "tess.missesGoToClaude") != nil {
                let said = standard.bool(forKey: "tess.missesGoToClaude")
                settings.missesGoToClaude = settings.missesGoToClaude.map { $0 && said } ?? said
            }
            if settings.backupFolderName == nil, let folderName {
                settings.backupFolderName = folderName
            }
        }
    }
}

/// Writes the settings object, creating it with its fixed id on the first write.
public struct WriteSettings: EngineAction {
    public static let descriptor = ActionDescriptor(name: "writeSettings", summary: "Change a preference",
                                                    parameters: [])

    public var settings: TesseraSettings

    public init(settings: TesseraSettings) {
        self.settings = settings
    }

    public func apply(_ transaction: inout Transaction) throws -> ObjectRecord {
        // A soft-deleted one is brought back, so a write never lands where read() can't see it.
        let object = try transaction.store.object(id: SettingsStore.objectID)
            ?? transaction.create(transaction.classDef(.settings), title: "Settings", id: SettingsStore.objectID)
        if object.isDeleted {
            object.deletedAt = nil
        }
        try transaction.set("lookDay", to: settings.lookDay.map(FieldValue.text), on: object)
        try transaction.set("lookNight", to: settings.lookNight.map(FieldValue.text), on: object)
        try transaction.set("lookPinned", to: settings.lookPinned.map(FieldValue.text), on: object)
        try transaction.set("missesGoToClaude", to: settings.missesGoToClaude.map(FieldValue.bool), on: object)
        try transaction.set("backupFolderName", to: settings.backupFolderName.map(FieldValue.text), on: object)
        try transaction.set("backupFolderPickedAt", to: settings.backupFolderPickedAt.map(FieldValue.date), on: object)
        try transaction.set("restWeekday", to: settings.restWeekday.map { .number(Double($0)) }, on: object)
        return object
    }

    public func summary(in _: ObjectStore) -> String {
        "Changed a preference"
    }
}
