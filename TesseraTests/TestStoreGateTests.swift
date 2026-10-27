import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// The app side of the test-store stamp: a real store never takes the test path, a stamped temp store does, and the
/// stamp is unreachable without the simulator flag.
@MainActor
struct TestStoreGateTests {
    private func bareStore() throws -> ObjectStore {
        let store = ObjectStore.open(inMemory: true)
        _ = try store.prepareCatalog()
        return store
    }

    @Test func aRealStoreNeverAllowsTheTestPath() {
        let container = TesseraSchema.makeContainer(inMemory: true)
        let app = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        #expect(!TestStoreGate.allowsClaude(app.store))
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
        try SettingsStore(engine: app.engine).update { $0.missesGoToClaude = false }
        #expect(!app.asksClaude)
    }

    @Test func withoutTheFlagNothingIsStampedAndTheRealPathIsUntouched() throws {
        let store = try bareStore()
        #expect(TestStoreGate.stampIfFlagged(store, arguments: []) == .notAsked)
        #expect(!TestStore.isStamped(store.context))
        #expect(TestStoreGate.flaggedContainer(arguments: []) == nil)
    }

    @Test func theFlagOnlyStampsOnTheSimulator() throws {
        let store = try bareStore()
        let outcome = TestStoreGate.stampIfFlagged(store, arguments: [TestStoreGate.flag])
        #if targetEnvironment(simulator)
            #expect(outcome == .stamped && TestStore.isStamped(store.context))
        #else
            #expect(outcome == .notAsked && !TestStore.isStamped(store.context))
        #endif
    }

    @Test func aFlaggedLaunchOpensAFreshTempStoreAndStampsIt() throws {
        let container = TestStoreGate.flaggedContainer(arguments: [TestStoreGate.flag])
        #if targetEnvironment(simulator)
            let made = try #require(container)
            let store = ObjectStore(context: made.mainContext)
            #expect(TestStore.isStamped(store.context))
            #expect(!TestStore.isHisStore(store.context))
            #expect(TestStore.allowsClaude(store))
            let url = try #require(made.mainContext.url)
            #expect(url != TesseraSchema.defaultURL)
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        #else
            #expect(container == nil)
        #endif
    }

    @Test func hisStoreFileIsRefusedEvenWithTheFlag() {
        // The app's own store counts as his, so the stamp refuses it (the reason a flagged launch opens a temp store).
        #expect(TestStore.isHisStore(url: TesseraSchema.defaultURL))
    }
}
