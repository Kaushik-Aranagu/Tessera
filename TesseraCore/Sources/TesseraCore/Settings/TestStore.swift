import Foundation
import GRDB

/// A store the test world made (docs/ai/harness/test-world.md section 2). The stamp is the database's own
/// `application_id`, set once, outside the object graph: no settings write, reset or delete can add it or clear it,
/// and a restored backup of his store never carries it. A stamped store may call Claude (the key, the ask gate and the
/// cap still apply) and is never backed up. Only `stamp` sets it, and it refuses his store.
@MainActor
public enum TestStore {
    public enum Refusal: Error, Equatable {
        /// The file is his: the app's own folder, or anywhere outside the temporary folder.
        case isHisStore
        /// The store holds rows he or Tess made (an op by anyone but the system): it is someone's data.
        case hasHisHistory
        /// The store holds a row the built-in catalog doesn't (the class it is of): it is someone's data, even a copy
        /// of his made in memory with no op by him in it.
        case hasHisRows(String)
    }

    /// "TEST" as the SQLite application id.
    nonisolated static let applicationID: Int32 = 0x5445_5354

    /// Whether the database carries the stamp.
    public static func isStamped(_ context: TesseraContext) -> Bool {
        (try? context.database.read { try Int32.fetchOne($0, sql: "PRAGMA application_id") }) == applicationID
    }

    /// In memory, or a file under the temporary folder. The app's own store file is never one.
    public static func isHisStore(_ context: TesseraContext) -> Bool {
        isHisStore(url: context.url)
    }

    public static func isHisStore(url: URL?) -> Bool {
        guard let url else { return false }
        let temp = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().standardizedFileURL.path
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        let own = TesseraSchema.defaultURL.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL
            .path
        if path.hasPrefix(own.hasSuffix("/") ? own : own + "/") {
            return true
        }
        return !path.hasPrefix(temp.hasSuffix("/") ? temp : temp + "/")
    }

    /// Whether anyone but the system has written to the store.
    public static func hasHisHistory(_ context: TesseraContext) -> Bool {
        context.operations.values.contains { $0.actor != .system }
    }

    /// Stamps the store, once, before anything of his is in it. Throws on his own store, or one with his history.
    public static func stamp(_ store: ObjectStore) throws {
        let context = store.context
        guard !isStamped(context) else { return }
        guard !isHisStore(context) else { throw Refusal.isHisStore }
        guard !hasHisHistory(context) else { throw Refusal.hasHisHistory }
        if let row = try firstRowOfHis(in: store) {
            throw Refusal.hasHisRows(row)
        }
        try context.database.write { try $0.execute(sql: "PRAGMA application_id = \(applicationID)") }
    }

    /// The class name of the first row, deleted ones included, that a fresh catalog doesn't install (the built-in
    /// plan, equipment and the Groceries list are expected), or nil when the store holds nothing but the catalog. A
    /// store holding only his deleted rows is still his.
    public static func firstRowOfHis(in store: ObjectStore) throws -> String? {
        let fresh = ObjectStore.open(inMemory: true)
        _ = try fresh.prepareCatalog()
        var catalog: [String: Int] = [:]
        for object in fresh.context.objects.values {
            catalog[rowKey(object), default: 0] += 1
        }
        for object in store.context.objects.values {
            let key = rowKey(object)
            guard let left = catalog[key], left > 0 else { return object.classDef?.name ?? "object" }
            catalog[key] = left - 1
        }
        return nil
    }

    private static func rowKey(_ object: ObjectRecord) -> String {
        "\(object.classDef?.id.uuidString ?? "none")|\(object.title)"
    }

    /// Puts the stamp on a copy of a stamped store's database (a rehearsal's fork), so the copy is a test store too.
    public static func carry(from context: TesseraContext, to database: any DatabaseWriter) throws {
        guard isStamped(context) else { return }
        try database.write { try $0.execute(sql: "PRAGMA application_id = \(applicationID)") }
    }

    /// Whether the Claude rungs may open for this store: it carries the stamp AND is not his (the store is checked as
    /// well as the stamp, so a stamp that somehow landed on his file opens nothing).
    public static func allowsClaude(_ store: ObjectStore) -> Bool {
        isStamped(store.context) && !isHisStore(store.context)
    }
}
