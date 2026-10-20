@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// Batch 3 (CL31): the Ask says "Asking Claude." only once a request leaves, and clears when the capture lands.
@MainActor
struct AskingClaudeTests {
    let container = TesseraSchema.makeContainer(inMemory: true)

    @Test func theLineIsOneElementSpokenOnce() {
        #expect(AskingClaudeCopy.line == "Asking Claude.")
        #expect(AskingClaudeCopy.spoken == "Asking Claude. Cancel.")
    }

    /// A grammar answer never reaches Claude, so the line never shows and nothing is left set.
    @Test func aGrammarAnswerNeverAsks() async {
        let model = AppModel(context: container.mainContext)
        #expect(!model.isAskingClaude)
        _ = await model.ask("bench 60 for 8")
        #expect(!model.isAskingClaude)
    }

    /// Core's signal sets the line; the capture landing clears it.
    @Test func theSignalShowsTheLineUntilTheAnswer() async {
        let model = AppModel(context: container.mainContext)
        model.claudeFlags.willSend?()
        _ = await model.ask("buy milk")
        #expect(!model.isAskingClaude)
    }
}
