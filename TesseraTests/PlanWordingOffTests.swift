import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// AI architecture, Oct 16: Plan my day's Claude wording ships off. With "Tess asks Claude" on, the plan still
/// shows the rules wording and makes no Claude call.
@MainActor
struct PlanWordingOffTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext, launchDefaults: .testSuite())
        DemoData.prepare(model)
        model.settingsAreReal = true
    }

    @Test func thePlanMakesNoClaudeCall() throws {
        #expect(model.asksClaude)
        #expect(!AppModel.planWordingReady)
        let plan = HomePlanModel()
        let morning = try #require(Calendar.current.date(bySettingHour: 8, minute: 10, second: 0, of: .now))
        plan.refresh(model: model, now: morning, calendar: .current, restDay: false, pulled: true)
        #expect(plan.isShowing)
        #expect(plan.wordingCalls == 0)
        #expect(!plan.viaClaude)
    }
}
