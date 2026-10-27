import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The app side of the test-store stamp: a real store never takes the test path, a stamped temp store does, and the
/// stamp is unreachable without the simulator flag.
@MainActor
struct TestStoreGateTests {
    /// A store with only the catalog in it (no launch writes), which is the only kind that may be stamped.
    private func bareStore() throws -> ObjectStore {
        let store = ObjectStore.open(inMemory: true)
        _ = try store.prepareCatalog()
        return store
    }

    @Test func aRealStoreNeverAllowsTheTestPath() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        #expect(!TestStoreGate.allowsClaude(app.store))
        // Unstamped: the old rule alone decides.
        app.settingsAreReal = false
        #expect(!app.asksClaude)
        app.settingsAreReal = true
        #expect(app.asksClaude)
    }

    @Test func aStampedTempStoreAllowsClaudeWithoutRealSettings() throws {
        // Stamp the context's store before the app launches into it (a stamp is refused once he has history).
        let container = TesseraSchema.makeContainer(inMemory: true)
        let first = ObjectStore(context: container.mainContext)
        _ = try first.prepareCatalog()
        try TestStore.stamp(first)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        app.settingsAreReal = false
        #expect(TestStoreGate.allowsClaude(app.store))
        #expect(app.asksClaude)
        // His own choice of Off still wins.
        try SettingsStore(engine: app.engine).update { $0.missesGoToClaude = false }
        #expect(!app.asksClaude)
    }

    @Test func stampIsUnreachableWithoutTheSimulatorFlag() throws {
        let store = try bareStore()
        // On the phone (not allowed) the flag does nothing.
        #expect(!TestStoreGate.stampIfFlagged(store, arguments: [TestStoreGate.flag], allowed: false))
        #expect(!TestStore.isStamped(store.context))
        // On the simulator without the flag, nothing either.
        #expect(!TestStoreGate.stampIfFlagged(store, arguments: [], allowed: true))
        #expect(!TestStore.isStamped(store.context))
        // Both: it stamps.
        #expect(TestStoreGate.stampIfFlagged(store, arguments: [TestStoreGate.flag], allowed: true))
        #expect(TestStore.isStamped(store.context))
    }
}
