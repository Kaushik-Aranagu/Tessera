import Foundation
@testable import Tessera
import TesseraCore
import Testing

/// Sample data: example content on its own store, his own untouched.
@MainActor
struct SampleDataTests {
    @Test func theRowIsLiveOffByDefaultOnShown() throws {
        let row = try #require(ReviewChoices.all.first { $0.id == SampleData.choiceID })
        #expect(row.defaultValue == "Off" && row.readiness == .live && !row.needsClaude)
        let shown = try #require(ReviewChoices.facets.first { $0.word == "Shown" })
        #expect(shown.ids.contains(SampleData.choiceID))
    }

    @Test func theSampleFillsItsOwnStoreAndLeavesHisAlone() throws {
        let real = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                            launchDefaults: .testSuite())
        let before = try real.store.objects(of: #require(real.classes[.task])).count
        let sample = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                              launchDefaults: .testSuite())
        DemoData.prepareSample(sample)
        #expect(try real.store.objects(of: #require(real.classes[.task])).count == before)
        #expect(!sample.objects(of: .spend).isEmpty)
        #expect(sample.objects(of: .task).contains { $0.title == "Pay the utility bill" })
        #expect(!NoteList(store: sample.store, classes: sample.classes).recent().isEmpty)
        #expect(!RecipeBook(store: sample.store, classes: sample.classes).recipes().isEmpty)
    }

    @Test func spendsAreInDollars() {
        #expect(SampleText.notes.allSatisfy { !$0.contains("€") && !$0.contains("£") })
    }
}
