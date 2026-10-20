import Foundation
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// G687 (reinstall-key-and-restore-spec 1.8): a key found on a fresh store asks once; Later writes nothing; no key,
/// no question. Fake keys only, built at run time.
@MainActor
struct ClaudeKeyQuestionTests {
    let container = TesseraSchema.makeContainer(inMemory: true)
    private let fake = "sk-" + "ant-" + String(repeating: "x", count: 32)

    @Test func keyQuestionReadsExactlyAndOffersYesNoLater() {
        #expect(ClaudeKeyQuestionCopy.question == "Use the Claude key still on this phone?")
        #expect([ClaudeKeyQuestionCopy.yes, ClaudeKeyQuestionCopy.no, ClaudeKeyQuestionCopy.later]
            == ["Yes", "No", "Later"])
        #expect(ClaudeKeyQuestionCopy.yesReceipt == "Using the Claude key.")
    }

    @Test func keyQuestionIsAbsentWithoutAKey() {
        let model = AppModel(context: container.mainContext)
        model.settingsAreReal = true
        model.refreshKeyQuestion(keys: InMemoryKeychain(nil))
        #expect(!model.keyQuestionDue)
    }

    @Test func laterWritesNothingAndYesAnswersOnce() {
        let model = AppModel(context: container.mainContext)
        model.settingsAreReal = true
        model.refreshKeyQuestion(keys: InMemoryKeychain(fake))
        #expect(model.keyQuestionDue)
        let ops = model.engine.history(limit: 50).count
        #expect(model.answerKeyQuestion(nil) == nil)
        #expect(model.engine.history(limit: 50).count == ops)
        #expect(model.keyQuestionQuietOnNow && model.keyQuestionDue)
        #expect(model.answerKeyQuestion(true) == ClaudeKeyQuestionCopy.yesReceipt)
        #expect(!model.keyQuestionDue)
        model.refreshKeyQuestion(keys: InMemoryKeychain(fake))
        #expect(!model.keyQuestionDue)
    }
}
