import Foundation
import os
import TesseraCore

/// The app's one door to the test-store stamp (docs/ai/harness/test-world.md section 2). Stamping is simulator-only:
/// the flag is read through `LaunchFlags.has`, never `#if DEBUG`, so a build on the phone has no path that stamps a
/// store, and the app's own store file (which always counts as his) is never stamped or replaced.
@MainActor
enum TestStoreGate {
    /// The launch flag that asks the simulator for a fresh test store.
    static let flag = "-testStore"

    /// What a launch did about the flag. Logged by name only: no contents, no paths.
    enum Outcome: String {
        case notAsked, stamped, refused
    }

    /// Stamps `store` when the simulator flag is on, and says whether it did. `TestStore.stamp` still refuses his own
    /// store and any store with his history.
    @discardableResult
    static func stampIfFlagged(_ store: ObjectStore,
                               arguments: [String] = ProcessInfo.processInfo.arguments) -> Outcome
    {
        guard LaunchFlags.has(flag, in: arguments) else { return .notAsked }
        do {
            try TestStore.stamp(store)
            return .stamped
        } catch {
            return .refused
        }
    }

    /// A fresh store under the temporary folder, stamped, when the simulator flag is on; nil otherwise (the caller
    /// opens the real store, untouched). It opens before anything is seeded, so the stamp lands on an empty catalog.
    static func flaggedContainer(arguments: [String] = ProcessInfo.processInfo.arguments) -> TesseraContainer? {
        guard LaunchFlags.has(flag, in: arguments) else { return nil }
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("tessera-test-store-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let container = TesseraSchema.makeContainer(url: folder.appendingPathComponent("tessera.sqlite"))
        let store = ObjectStore(context: container.mainContext)
        _ = try? store.prepareCatalog()
        let outcome = stampIfFlagged(store, arguments: arguments)
        Logger(subsystem: "com.kaushikaranagu.tessera", category: "testStore")
            .info("Test store: \(outcome.rawValue, privacy: .public)")
        return container
    }

    /// Whether the Claude rungs may open on this store because it is a stamped test store (the stamp AND not his file).
    static func allowsClaude(_ store: ObjectStore) -> Bool {
        TestStore.allowsClaude(store)
    }
}
