import SwiftUI
@testable import Tessera
import TesseraCore
import TesseraTess
import Testing

/// Batch 3 (CL31): the Ask says "Asking Claude." only once a request leaves, and clears when the capture lands.
@MainActor
struct AskingClaudeTests {
    let container = TesseraSchema.makeContainer(inMemory: true)

    @Test func theLineIsOneElementSpokenOnce() {
        #expect(AskingClaudeCopy.line == "Asking Claude")
        #expect(AskingClaudeCopy.spoken == "Asking Claude. Cancel")
    }

    /// A grammar answer never reaches Claude, so the line never shows and nothing is left set.
    @Test func aGrammarAnswerNeverAsks() async {
        let model = AppModel(context: container.mainContext)
        #expect(!model.isAskingClaude)
        _ = await model.ask("bench 60 for 8")
        #expect(!model.isAskingClaude)
    }

    /// Core's signal sets the line; the capture landing clears it.
    @Test func theSignalShowsTheLineUntilTheAnswer() async throws {
        let model = AppModel(context: container.mainContext)
        // The real Claude model is wired to the flags at launch (QA on #1123): its signal is set, and it sets the line.
        let willSend = try #require(model.claudeFlags.willSend)
        willSend()
        #expect(model.isAskingClaude)
        _ = await model.ask("buy milk")
        #expect(!model.isAskingClaude)
    }

    /// Design on #1143: only Return's own newline sends; a pasted line break is a space and sends nothing.
    @Test func onlyReturnSends() {
        #expect(AskDraft.read(old: "buy milk", new: "buy milk\n") == ("buy milk", true))
        #expect(AskDraft.read(old: "", new: "milk\neggs") == ("milk eggs", false))
        #expect(AskDraft.read(old: "buy", new: "buy milk\nand eggs").send == false)
    }

    /// Design on #1170: five lines, four at the largest size, so only whole lines ever show.
    @Test func theFieldShowsWholeLinesOnly() {
        #expect(AskDraft.maxLines(at: .large) == 5)
        #expect(AskDraft.maxLines(at: .accessibility4) == 5)
        #expect(AskDraft.maxLines(at: .accessibility5) == 4)
    }
}
