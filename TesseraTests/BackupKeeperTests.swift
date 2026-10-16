import Foundation
@testable import Tessera
@testable import TesseraCore
import Testing

/// QA T11, B8 and B9 on #211: the daily copy's folder side, with its UserDefaults and bookmark resolver injected.
@Suite(.serialized) @MainActor
struct BackupKeeperTests {
    let defaults: UserDefaults
    let context: TesseraContext

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "backup-keeper-\(UUID().uuidString)"))
        BackupKeeper.defaults = defaults
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try ActionEngine(store: store, classes: classes).perform(CreateNote(body: "Bench felt heavy"), by: .user)
        context = store.context
    }

    func reset() {
        BackupKeeper.defaults = .standard
        BackupKeeper.resolve = { data in
            var stale = false
            guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale) else { return nil }
            return (url, stale)
        }
    }

    @Test func aBookmarkThatWontResolveIsAFolderFailureAndForgetClearsIt() {
        defer { reset() }
        BackupKeeper.bookmark = Data("a bookmark".utf8)
        BackupKeeper.resolve = { _ in nil }
        BackupKeeper.runDaily(context)
        #expect(BackupKeeper.failures.map(\.place) == [.folder])
        BackupKeeper.forget()
        #expect(BackupKeeper.failures.isEmpty && BackupKeeper.bookmark == nil)
    }

    @Test func aFolderInTheTrashIsNeverWrittenTo() throws {
        defer { reset() }
        let trash = FileManager.default.temporaryDirectory.appendingPathComponent(".Trash/Tessera-QA")
        try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
        BackupKeeper.bookmark = Data("a bookmark".utf8)
        BackupKeeper.resolve = { _ in (trash, false) }
        #expect(BackupKeeper.pickedFolder == nil)
        BackupKeeper.runDaily(context)
        #expect(BackupKeeper.failures.map(\.place) == [.folder])
        #expect(try FileManager.default.contentsOfDirectory(atPath: trash.path).isEmpty)
        #expect(BackupKeeper.isInTrash(URL(fileURLWithPath: "/private/var/mobile/Library/Mobile Documents/"
                + "com~apple~CloudDocs/Recently Deleted/Tessera")))
        #expect(!BackupKeeper.isInTrash(URL(fileURLWithPath: "/var/mobile/Library/Mobile Documents/Tessera")))
    }

    @Test func aResolvingFolderGetsTodaysCopy() throws {
        defer { reset() }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        BackupKeeper.bookmark = Data("a bookmark".utf8)
        BackupKeeper.resolve = { _ in (folder, false) }
        BackupKeeper.runDaily(context)
        #expect(BackupKeeper.failures.isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).count == 1)
    }
}
