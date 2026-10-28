import Foundation
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// QA M1: "Tess asks Claude" has one home, the settings object. Migrate runs on every launch, and a "no" left in the
/// old key must never turn the switch back off after he turns it on again.
@MainActor
struct TessAsksClaudeTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel
    let defaults: UserDefaults

    init() throws {
        model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
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

    @Test func aFreshInstallAsksClaudeByDefault() {
        // Kaushik, Oct 26: "set them on by default. Tess needs to use AI."
        launch()
        #expect(asks)
    }

    /// QA F1: on a throwaway store (memory fallback, failed seed) the empty settings never let Claude in.
    @Test func aThrowawayStoreNeverAsksClaude() {
        model.settingsAreReal = false
        #expect(!model.asksClaude)
        model.settingsAreReal = true
        #expect(model.asksClaude) // never chosen reads as yes (Oct 26)
        try? SettingsStore(engine: model.engine).update { $0.missesGoToClaude = false }
        #expect(!model.asksClaude)
        model.settingsAreReal = false
        try? SettingsStore(engine: model.engine).update { $0.missesGoToClaude = true }
        #expect(!model.asksClaude)
    }

    @Test func theKeyQuestionStillShowsButClaudeIsAlreadyOn() {
        model.settingsAreReal = true
        let settings = SettingsStore(engine: model.engine)
        #expect(settings.claudeQuestionDue(keyPresent: true) && model.asksClaude)
        try? settings.answerClaudeQuestion(false)
        #expect(!settings.claudeQuestionDue(keyPresent: true) && !model.asksClaude)
    }

    /// Sample data is the stamped test world: it may ask Claude (Kaushik, Oct 24), following his own choice, which it
    /// reads from his model and never writes.
    @Test func sampleDataAsksClaudeAndFollowsHisChoice() throws {
        model.settingsAreReal = true
        let sampleContainer = TesseraSchema.makeContainer(inMemory: true)
        let sample = AppModel(context: sampleContainer.mainContext, launchDefaults: .testSuite(), isSample: true)
        #expect(!sample.settingsAreReal)
        #expect(sample.asksClaude, "a sample with no owner reads the default")
        sample.claudeOwner = model
        #expect(sample.asksClaude)
        try SettingsStore(engine: model.engine).update { $0.missesGoToClaude = false }
        #expect(!sample.asksClaude, "his Off holds in the sample too")
        #expect(SettingsStore(engine: sample.engine).read().missesGoToClaude == nil, "nothing was written there")
    }

    /// Demos and the simulator flags keep Claude off (`isDemo`); a test run has none of them.
    @Test func noDemoFlagInATestRun() {
        #expect(!AppModel.isDemo)
    }

    /// Her sheet says who answered each reply: Claude, or this phone (the grammar, the on-device model, a miss kept).
    @Test func eachReplyNamesWhoAnswered() {
        #expect(TessLayerModel.AnswerSource(.claude) == .claude)
        for source: TessCapture.Source? in [.grammar, .model, TessCapture.Source.none, nil] {
            #expect(TessLayerModel.AnswerSource(source) == .phone)
        }
        #expect(TessLayerModel.AnswerSource.claude.line == "Answered by Claude")
        #expect(TessLayerModel.AnswerSource.phone.line == "Answered on this phone")
        #expect(TessLayerModel.AnswerSource(.none, keyPresent: false) == .phoneNoKey)
        #expect(TessLayerModel.AnswerSource(.none, keyPresent: true, failure: .authFailed) == .phoneFailed(.authFailed))
        #expect(TessLayerModel.AnswerSource.phoneFailed(.authFailed).line
            == "Your Claude key didn't work. Check it in Settings > Claude")
        #expect(TessLayerModel.AnswerSource(.none, keyPresent: true, failure: .other) == .phone)
        #expect(TessLayerModel.AnswerSource(.claude, keyPresent: false, failure: .network) == .claude)
        let layer = TessLayerModel()
        layer.say("Logged.", names: [], answeredBy: .claude)
        #expect(layer.lines.last?.answeredBy == .claude)
    }
}
