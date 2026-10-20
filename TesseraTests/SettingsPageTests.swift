import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Batch 0 and AI-9: Settings' Review marks and What Tess knows' words.
@MainActor
struct SettingsPageTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    let model: AppModel

    init() {
        model = AppModel(context: container.mainContext)
    }

    private func choice(_ id: String) throws -> ReviewChoices.Choice {
        try #require(ReviewChoices.all.first { $0.id == id })
    }

    /// Needs Claude wins over every other mark; Later for an entitlement; Soon for a feature on its way.
    @Test func reviewRowsSayWhatTheyWaitFor() throws {
        #expect(try ReviewSwitchCopy.mark(choice("planMyDay")) == "Needs Claude")
        #expect(try ReviewSwitchCopy.mark(choice("calendar")) == "Later")
        #expect(try ReviewSwitchCopy.mark(choice("pageTurn")) == "Soon")
        var live = try choice("pageTurn")
        live.readiness = .live
        #expect(ReviewSwitchCopy.mark(live) == nil)
        #expect(ReviewSwitchCopy.hint(live, value: "Today") == "Pages change as they do now.")
        #expect(try ReviewSwitchCopy.hint(choice("calendar"), value: "Off") == "Later: this needs a build with access.")
        #expect(ReviewSwitchCopy.pageOf(2, 3) == "2 of 3")
    }

    @Test func theMemoryDoorCountsInThirdPerson() {
        #expect(TessKnowsCopy.door("Nothing yet") == "Tess remembers nothing yet.")
        #expect(TessKnowsCopy.door("12 things") == "Tess remembers 12 things.")
    }

    /// A told line shows on the page in its group; forgetting it takes it off and the receipt names the thing.
    @Test func aForgottenLineLeavesThePage() throws {
        let store = TessMemoryStore(engine: model.engine, forgetLogURL: nil)
        let kept = try model.engine.perform(RememberFact(text: "You rest on Sundays", area: .training), by: .user)
        #expect(store.grouped().flatMap(\.lines).contains { $0.id == kept.output.id })
        let forgotten = try model.engine.perform(ForgetMemory(memory: kept.output.id), by: .user)
        #expect(!store.grouped().flatMap(\.lines).contains { $0.id == kept.output.id })
        let receipt = forgotten.record.receipt ?? forgotten.record.summary
        #expect(receipt.hasSuffix("forgotten."))
        #expect(store.countLine() == "Nothing kept yet.")
    }
}
