import Foundation
import TesseraCore

/// The app's one door to the test-store stamp (docs/ai/harness/test-world.md section 2). Stamping is simulator-only:
/// it goes through `LaunchFlags`, never `#if DEBUG`, so a build on the phone has no path that stamps a store.
@MainActor
enum TestStoreGate {
    /// The launch flag that asks the simulator to make the store a test store.
    static let flag = "-testStore"

    /// Stamps `store` when the simulator flag is on, and says whether it did. `allowed` is `LaunchFlags.allowed`,
    /// a parameter only so the phone's answer can be tested. `TestStore.stamp` itself still refuses his own store.
    @discardableResult
    static func stampIfFlagged(_ store: ObjectStore,
                               arguments: [String] = ProcessInfo.processInfo.arguments,
                               allowed: Bool = LaunchFlags.allowed) -> Bool
    {
        guard allowed, arguments.contains(flag) else { return false }
        do {
            try TestStore.stamp(store)
            return true
        } catch {
            return false
        }
    }

    /// Whether the Claude rungs may open on this store because it is a stamped test store (the stamp AND not his file).
    static func allowsClaude(_ store: ObjectStore) -> Bool {
        TestStore.allowsClaude(store)
    }
}
