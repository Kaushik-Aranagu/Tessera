import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// QA M1: "Tess asks Claude" has one home, the settings object. Migrate runs on every launch, and a "no" left in the
/// old key must never turn the switch back off after he turns it on again.
@MainActor
struct TessAsksClaudeTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel
    let defaults: UserDefaults

    init() throws {
        model = AppModel(context: container.mainContext)
        let suite = "TessAsksClaudeTests.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suite))
    }

    private func launch() {
        SettingsStore(engine: model.engine).migrateAtLaunch(looks: defaults, standard: defaults, folderName: nil)
    }

    private var asks: Bool {
        SettingsStore(engine: model.engine).read().sendsMissesToClaude
    }

    @Test func offThenOnSurvivesEveryLaunch() throws {
        // An old install that said no.
        defaults.set(false, forKey: SettingsStore.legacyMissesKey)
        launch()
        #expect(!asks)
        #expect(defaults.object(forKey: SettingsStore.legacyMissesKey) == nil)

        // He turns it back on, then off, then on, relaunching between each.
        for value in [true, false, true] {
            try SettingsStore(engine: model.engine).update { $0.missesGoToClaude = value }
            launch()
            launch()
            #expect(asks == value)
        }
    }

    @Test func aFreshInstallAsks() {
        launch()
        #expect(asks)
    }

    /// QA F1: on a throwaway store (memory fallback, failed seed) the empty settings must not read as yes.
    @Test func aThrowawayStoreNeverAsksClaude() {
        model.settingsAreReal = false
        #expect(!model.asksClaude)
        model.settingsAreReal = true
        #expect(model.asksClaude)
    }
}
