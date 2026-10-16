import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// docs/research/settings-object.md (board item 96): one settings object that rides in every copy and export.
@MainActor
struct SettingsTests {
    let dir: URL
    let url: URL
    let store: ObjectStore
    let engine: ActionEngine
    var settings: SettingsStore {
        SettingsStore(engine: engine)
    }

    init() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("tessera.sqlite")
        store = try ObjectStore(context: TesseraContext(url: url))
        engine = try ActionEngine(store: store, classes: store.prepareCatalog())
    }

    @Test func readIsAllNilBeforeAnyWrite() {
        #expect(settings.read() == TesseraSettings())
        #expect(store.object(id: SettingsStore.objectID) == nil)
        #expect(settings.read().sendsMissesToClaude && settings.read().restWeekday == nil)
    }

    @Test func theFirstWriteMakesOneObjectWithTheFixedIDAndOneOp() throws {
        let before = engine.history(limit: 100).count
        try settings.update { $0.lookDay = "Porcelain" }
        try settings.update { $0.lookNight = "Obsidian" }
        _ = try store.prepareCatalog()
        try settings.update { $0.restWeekday = 7 }
        #expect(store.object(id: SettingsStore.objectID) != nil)
        let settingsClass = try #require(engine.classes[.settings])
        #expect(store.objects(of: settingsClass).count == 1)
        #expect(engine.history(limit: 100).count == before + 3)
        #expect(settings.read() == TesseraSettings(lookDay: "Porcelain", lookNight: "Obsidian", restWeekday: 7))
        // An unchanged write is no op.
        try settings.update { $0.lookDay = "Porcelain" }
        #expect(engine.history(limit: 100).count == before + 3)
    }

    @Test func anUnknownLookNameSurvives() throws {
        try settings.update { $0.lookPinned = "Aurora (a look from a newer build)" }
        #expect(settings.read().lookPinned == "Aurora (a look from a newer build)")
    }

    @Test func undoPutsTheOldValueBack() throws {
        try settings.update { $0.missesGoToClaude = true }
        try settings.update { $0.missesGoToClaude = false }
        #expect(settings.read().sendsMissesToClaude == false)
        try engine.undo(#require(engine.history(limit: 1).first))
        #expect(settings.read().missesGoToClaude == true)
    }

    @Test func folderNamesAreDisplayNamesOnly() {
        #expect(TesseraSettings.isDisplayName("iCloud Drive/Tessera"))
        for path in ["/private/var/mobile/Library/Mobile Documents/x", "file:///Users/k/Tessera", "/Tessera",
                     "On My iPhone/Containers/Data/Application/0A1B2C3D-1111-2222-3333-444455556666/Documents"]
        {
            #expect(!TesseraSettings.isDisplayName(path), "\(path)")
            #expect(TesseraSettings(backupFolderName: path).backupFolderName == nil)
        }
        var settings = TesseraSettings(backupFolderName: "iCloud Drive/Tessera")
        settings.backupFolderName = "/private/var/x"
        #expect(settings.backupFolderName == "iCloud Drive/Tessera")
    }

    // MARK: Copies, restores, exports

    @Test func settingsAloneNeverMakeACopy() throws {
        // #239's empty-store guard: a fresh install whose only change is a look is still empty.
        try settings.update { $0.lookDay = "Porcelain" }
        store.save()
        let backups = dir.appendingPathComponent("Backups")
        #expect(try TesseraBackup.writeRolling(from: store.context, in: backups, now: TesseraDayTests.at(10, 21, 12),
                                               calendar: TesseraDayTests.calendar) == nil)
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        #expect(try TesseraBackup.writeRolling(from: store.context, in: backups, now: TesseraDayTests.at(10, 21, 12),
                                               calendar: TesseraDayTests.calendar) != nil)
    }

    @Test func settingsRideInACopyAndComeBackWithARestore() throws {
        try settings.update {
            $0.lookDay = "Porcelain"
            $0.missesGoToClaude = false
            $0.backupFolderName = "iCloud Drive/Tessera"
        }
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        store.save()
        let copy = dir.appendingPathComponent("copy.tessera")
        try TesseraBackup.write(from: store.context, to: copy)
        let toRestore = dir.appendingPathComponent("restore.tessera")
        try TesseraBackup.write(from: store.context, to: toRestore)
        let opened = try ObjectStore(context: TesseraContext(url: copy))
        let restoredEngine = try ActionEngine(store: opened, classes: opened.prepareCatalog())
        #expect(SettingsStore(engine: restoredEngine).read() == settings.read())

        // A fresh phone with a different look, then the restore: the copy's values win.
        let phone = dir.appendingPathComponent("phone").appendingPathComponent("tessera.sqlite")
        try FileManager.default.createDirectory(
            at: phone.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        do {
            let fresh = try ObjectStore(context: TesseraContext(url: phone))
            let freshEngine = try ActionEngine(store: fresh, classes: fresh.prepareCatalog())
            try SettingsStore(engine: freshEngine).update { $0.lookDay = "Obsidian" }
            fresh.save()
        }
        _ = try TesseraBackup.stageRestore(from: toRestore, storeURL: phone)
        let container = TesseraSchema.makeContainer(url: phone)
        let after = ObjectStore(context: container.mainContext)
        let afterEngine = try ActionEngine(store: after, classes: after.prepareCatalog())
        #expect(SettingsStore(engine: afterEngine).read().lookDay == "Porcelain")
        #expect(SettingsStore(engine: afterEngine).read().missesGoToClaude == false)
        TesseraSchema.clearLaunchNote()
    }

    @Test func settingsAreInTheExport() throws {
        try settings.update { $0.restWeekday = 1 }
        let json = try String(data: TesseraExport(context: store.context).encoded(), encoding: .utf8) ?? ""
        #expect(json.contains(SettingsStore.objectID.uuidString))
    }

    @Test func aDemoResetClearsSettings() throws {
        try settings.update { $0.lookDay = "Porcelain" }
        store.resetUserData()
        _ = try store.prepareCatalog()
        #expect(settings.read() == TesseraSettings())
    }

    // MARK: Migration

    func defaults() throws -> (looks: UserDefaults, standard: UserDefaults) {
        let looks = try #require(UserDefaults(suiteName: "settings-test-looks-\(UUID().uuidString)"))
        let standard = try #require(UserDefaults(suiteName: "settings-test-standard-\(UUID().uuidString)"))
        return (looks, standard)
    }

    @Test func migrationCopiesOnlyPresentKeysOnceAsSystem() throws {
        let (looks, standard) = try defaults()
        looks.set("Porcelain", forKey: "look.day")
        standard.set("Obsidian", forKey: "look.night") // pre-#221, standard only
        try settings.migrate(looks: looks, standard: standard, folderName: "iCloud Drive/Tessera")
        let read = settings.read()
        #expect(read.lookDay == "Porcelain" && read.lookNight == "Obsidian" && read.lookPinned == nil)
        #expect(read.missesGoToClaude == nil && read.backupFolderName == "iCloud Drive/Tessera")
        #expect(engine.history(limit: 1).first?.actor == .system)
        let ops = engine.history(limit: 100).count
        try settings.migrate(looks: looks, standard: standard, folderName: "iCloud Drive/Tessera")
        #expect(engine.history(limit: 100).count == ops)
    }

    @Test func migrationNeverOverwritesAFieldButNoWins() throws {
        try settings.update {
            $0.lookDay = "Obsidian"
            $0.missesGoToClaude = true
        }
        let (looks, standard) = try defaults()
        looks.set("Porcelain", forKey: "look.day")
        standard.set(false, forKey: "tess.missesGoToClaude")
        try settings.migrate(looks: looks, standard: standard, folderName: nil)
        #expect(settings.read().lookDay == "Obsidian")
        #expect(settings.read().missesGoToClaude == false)
    }
}

/// QA on #258, and a check Research asked for before Oct 22: an older build reading a newer catalog.
@MainActor
struct SettingsFollowUpTests {
    @Test func aRestWeekdayOutsideOneToSevenReadsAsEmpty() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let settings = SettingsStore(engine: engine)
        try settings.update { $0.restWeekday = 3 }
        let object = try #require(store.object(id: SettingsStore.objectID))
        for stored in [0.0, 8.0] {
            try store.set("restWeekday", to: .number(stored), on: object)
            #expect(settings.read().restWeekday == nil)
        }
    }

    @Test func aSoftDeletedSettingsObjectIsBroughtBackOnWrite() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let settings = SettingsStore(engine: engine)
        try settings.update { $0.lookDay = "Porcelain" }
        // Undoing the first settings op deletes the object it created.
        try engine.undo(#require(engine.history(limit: 1).first))
        #expect(settings.read() == TesseraSettings())
        try settings.update { $0.lookDay = "Obsidian" }
        #expect(settings.read().lookDay == "Obsidian")
    }

    @Test func tessEyesIsOffUntilTurnedOnAndRollsBack() throws {
        let store = ObjectStore.open(inMemory: true)
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let settings = SettingsStore(engine: engine)
        // Motion item 1: nil means no; one op turns it on; UNDO takes it back.
        try settings.update { $0.lookDay = "Porcelain" }
        #expect(settings.read().tessEyes == nil && !settings.read().showsTessEyes)
        try settings.update { $0.tessEyes = true }
        #expect(settings.read().showsTessEyes)
        let record = try #require(engine.history(limit: 1).first)
        engine.undo(record)
        #expect(settings.read().tessEyes == nil && settings.read().lookDay == "Porcelain")
        // An old backup's settings (encoded before the field existed) decode with it nil.
        let old = #"{"lookDay":"Porcelain","restWeekday":1}"#
        let decoded = try JSONDecoder().decode(TesseraSettings.self, from: Data(old.utf8))
        #expect(decoded.tessEyes == nil && decoded.lookDay == "Porcelain")
        // An older build ignores the key: a newer settings payload still decodes into the old field set.
        struct OlderSettings: Decodable {
            var lookDay: String?
            var restWeekday: Int?
        }
        try settings.update { $0.tessEyes = true }
        let newer = try JSONEncoder().encode(settings.read())
        let olderRead = try JSONDecoder().decode(OlderSettings.self, from: newer)
        #expect(olderRead.lookDay == "Porcelain" && olderRead.restWeekday == nil)
        // In the store, an older catalog (v8) reseeded at v9 gains the field and keeps the value.
        for classDef in store.context.all(ClassDef.self) where classDef.systemKey != nil {
            classDef.packageVersion = 8
        }
        _ = try store.prepareCatalog()
        #expect(settings.read().tessEyes == true)
    }

    @Test func aClassFromANewerCatalogIsLeftAlone() throws {
        // Rolling back to an older build: the store still opens and seeds, a class it doesn't know (as v3 doesn't
        // know Settings) is skipped, not dropped, and its objects survive a copy.
        let store = ObjectStore.open(inMemory: true)
        _ = try store.prepareCatalog()
        let future = ClassDef(name: "From the future", parent: nil, symbolName: "sparkle", colorRole: "neutral",
                              traits: [], systemKey: "system.fromTheFuture")
        future.packageVersion = 99
        store.context.insert(future)
        let object = store.create(future, title: "Kept")
        let classes = try store.prepareCatalog()
        #expect(!classes.values.contains { $0.id == future.id })
        #expect(future.packageVersion == 99 && store.object(id: object.id) != nil)
    }
}
