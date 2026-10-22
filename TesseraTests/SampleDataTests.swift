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

    @Test func backupsAndCopiesRefuseTheSample() async throws {
        let real = AppModel(context: TesseraSchema.makeContainer(inMemory: true).mainContext,
                            launchDefaults: .testSuite())
        let sample = SampleData.shared.model(over: real, on: true)
        defer { SampleData.shared.release() }
        #expect(SampleData.shared.holds(sample.context) && !SampleData.shared.holds(real.context))
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(throws: BackupKeeper.SampleRefused.self) {
            try BackupKeeper.pick(folder, context: sample.context, engine: sample.engine)
        }
        await #expect(throws: BackupKeeper.SampleRefused.self) {
            _ = try await BackupKeeper.savedCopy(sample.context)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
        // A sample "Forget" has no log file to reach, and the sample never counts as his settings.
        #expect(sample.isSample && sample.forgetLogURL == nil && !sample.settingsAreReal)
        #expect(!real.isSample)
    }

    @Test func spendsAreInDollars() {
        #expect(SampleText.notes.allSatisfy { !$0.contains("€") && !$0.contains("£") })
    }
}
