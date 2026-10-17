import Foundation
import GRDB
@testable import TesseraCore
import Testing

/// G28: the local Backup keeps every word, the iCloud copy leaves the private ones out, a shared export masks them.
@MainActor
struct PrivateWordsTests {
    /// Words that must never leave the phone, and words that may.
    static let secrets = ["hunter2zebra", "82.4", "120.50", "Dr Lee", "zebra99"]
    static let ordinary = ["Bench felt heavy", "Buy lemons", "Pasta night"]

    func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func storeWithEverything(at url: URL) throws -> ObjectStore {
        let store = try ObjectStore(context: TesseraContext(url: url))
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        try engine.perform(CreateNote(body: "Bench felt heavy"), by: .user)
        try engine.perform(CreateNote(body: "wifi password is hunter2zebra"), by: .user) // a private note
        try engine.perform(CreateNote(body: "weighed 82.4 kg this morning"), by: .user) // a weigh-in note
        try engine.perform(CreateNote(body: "paid 120.50 for shoes"), by: .user) // money
        try engine.perform(CreateTask(title: "Buy lemons"), by: .user)
        try engine.perform(CreateTask(title: "Pay Dr Lee"), by: .user) // a money task
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        try engine.perform(AddListItem(list: list.id, text: "Pasta night"), by: .user)
        try engine.perform(AddListItem(list: list.id, text: "reset router zebra99 pin"), by: .user) // a secret line
        store.save()
        return store
    }

    func text(of data: Data) -> String {
        String(decoding: data, as: UTF8.self)
    }

    @Test func anExportShowsOnlyTheLabelsNeverTheWords() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithEverything(at: dir.appendingPathComponent("tessera.sqlite"))
        let json = try text(of: TesseraExport(context: store.context, maskingPrivate: true).encoded())
        for word in Self.secrets {
            #expect(!json.contains(word), "\(word) leaked")
        }
        for word in Self.ordinary {
            #expect(json.contains(word), "\(word) lost")
        }
        #expect(json.contains("Private note") && json.contains("Private task") && json.contains("Private item"))
        // Unmasked, the same store still holds every word (the engine's own round trip).
        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let whole = try text(of: TesseraExport(context: store.context, maskingPrivate: false).encoded())
        #expect(Self.secrets.allSatisfy { whole.contains($0) })
    }

    @Test func anExportMasksTheOpLogOfAnObjectThatWasPrivateOnce() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithEverything(at: dir.appendingPathComponent("tessera.sqlite"))
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        let task = try engine.perform(CreateTask(title: "Buy lemons3"), by: .user).output
        try engine.perform(RenameObject(object: task.id, title: "Pay Dr Zed77"), by: .user)
        try engine.perform(RenameObject(object: task.id, title: "Buy lemons2"), by: .user)
        let json = try text(of: TesseraExport(context: store.context).encoded())
        #expect(!json.contains("Zed77") && !json.contains("Pay Dr Zed") && json.contains("Buy lemons2"))
    }

    @Test func aDefaultExportMasks() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithEverything(at: dir.appendingPathComponent("tessera.sqlite"))
        let json = try text(of: TesseraExport(context: store.context).encoded())
        #expect(Self.secrets.allSatisfy { !json.contains($0) } && json.contains("Private note"))
    }

    @Test func aRecipeWithASecretTitleMasksToPrivateRecipe() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        try engine.perform(CreateRecipe(text: "Stew\nIngredients\n1 onion\nMethod\n1. Cook it.", title: "Wifi password zebra99 stew"), by: .user)
        let json = try text(of: TesseraExport(context: store.context, maskingPrivate: true).encoded())
        #expect(!json.contains("zebra99"))
        #expect(json.contains("Private recipe"))
        #expect(!json.contains("stew") && !json.contains("onion")) // what is inside it is private with it
    }

    @Test func theLocalBackupKeepsEveryWordAndNeverAKey() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithEverything(at: dir.appendingPathComponent("tessera.sqlite"))
        let file = dir.appendingPathComponent("local.tessera")
        try TesseraBackup.write(from: store.context, to: file)
        let copy = try TesseraContext(url: file)
        let titles = copy.all(ObjectRecord.self).map(\.title)
        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let blob = try text(of: TesseraExport(context: copy, maskingPrivate: false).encoded())
        for word in Self.secrets + Self.ordinary {
            #expect(blob.contains(word), "\(word) missing from the local copy")
        }
        #expect(titles.contains("Pay Dr Lee"))
        // Built from pieces: a key shape never sits in a source file.
        let prefix = ["sk", "ant"].joined(separator: "-") + "-"
        #expect(!blob.contains(prefix))
    }

    @Test func theICloudCopyDropsThePrivateOnes() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithEverything(at: dir.appendingPathComponent("tessera.sqlite"))
        let file = dir.appendingPathComponent("icloud.tessera")
        try TesseraBackup.write(from: store.context, to: file, leavingOutPrivate: true)
        _ = try TesseraBackup.inspect(file) // still a good backup
        let copy = try TesseraContext(url: file)
        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let blob = try text(of: TesseraExport(context: copy, maskingPrivate: false).encoded())
        for word in Self.secrets {
            #expect(!blob.contains(word), "\(word) reached the iCloud copy")
        }
        for word in Self.ordinary {
            #expect(blob.contains(word), "\(word) lost from the iCloud copy")
        }
        // The rolling path takes the same flag.
        let iCloud = dir.appendingPathComponent("iCloud")
        let rolled = try #require(try TesseraBackup.writeRolling(from: store.context, in: iCloud, now: .now,
                                                                 leavingOutPrivate: true))
        // Test-only lossless export (maskingPrivate: false); the app never does this.
        let rolledBlob = try text(of: TesseraExport(context: TesseraContext(url: rolled), maskingPrivate: false).encoded())
        #expect(Self.secrets.allSatisfy { !rolledBlob.contains($0) })
    }

    /// QA on #707: SQLite keeps deleted rows in free pages, so the file's raw bytes are read, not its objects.
    @Test func theICloudCopyHoldsNoPrivateWordInItsRawBytes() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try storeWithEverything(at: dir.appendingPathComponent("tessera.sqlite"))
        let engine = try ActionEngine(store: store, classes: store.prepareCatalog())
        try engine.perform(CreateRecipe(text: "Stew\nIngredients\n1 onion\nMethod\n1. Cook it.",
                                        title: "Wifi password zebra99 stew"), by: .user)
        // Private once, plain now: the old words still sit in the op log.
        let renamed = try engine.perform(CreateTask(title: "Buy lemons3"), by: .user).output
        try engine.perform(RenameObject(object: renamed.id, title: "Pay Dr Zed77"), by: .user)
        try engine.perform(RenameObject(object: renamed.id, title: "Buy lemons2"), by: .user)
        store.save()
        let words = ["Zed77", "hunter2zebra", "zebra99", "Dr Lee", "120.50", "82.4", "Wifi password", "router zebra99"]
        let iCloud = dir.appendingPathComponent("iCloud")
        let direct = dir.appendingPathComponent("direct.tessera")
        try TesseraBackup.write(from: store.context, to: direct, leavingOutPrivate: true)
        let rolled = try #require(try TesseraBackup.writeRolling(from: store.context, in: iCloud, now: .now,
                                                                 leavingOutPrivate: true))
        for file in [direct, rolled] {
            for path in [file.path, file.path + "-wal", file.path + "-shm"] {
                guard let bytes = FileManager.default.contents(atPath: path) else {
                    #expect(path != file.path, "the copy is missing")
                    continue
                }
                for word in words {
                    #expect(bytes.range(of: Data(word.utf8)) == nil, "\(word) in the bytes of \(path)")
                }
            }
            #expect(bytes(of: file).range(of: Data("Bench felt heavy".utf8)) != nil) // ordinary words stay
            #expect(bytes(of: file).range(of: Data("Buy lemons2".utf8)) != nil) // the plain object itself stays
        }
        // Nothing but the finished copy ever sits in the iCloud folder.
        #expect(try FileManager.default.contentsOfDirectory(atPath: iCloud.path).count == 1)
    }

    func bytes(of url: URL) -> Data {
        FileManager.default.contents(atPath: url.path) ?? Data()
    }
}
