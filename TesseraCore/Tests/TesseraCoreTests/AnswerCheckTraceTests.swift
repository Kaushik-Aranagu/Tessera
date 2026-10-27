import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// C6 in shadow (m3-wiring.md): every finished reply's verdict is on the run's trace for the live runner, with a count
/// and never the numbers, and nothing retries.
@MainActor
struct AnswerCheckTraceTests {
    func checkSpan(_ ask: String, reply: String) async throws -> (span: TraceSpan, json: String, rounds: Int) {
        let helper = TessRunTests()
        let haiku = ScriptedBrain(.haiku, rounds: [[.text(reply)]])
        let r = try helper.rig([.haiku: haiku])
        _ = await helper.collect(r.run.ask(ask))
        let spans = await r.rig.trace.all()
        let span = try #require(spans.first { $0.kind == .check })
        let runID = try #require(TessRunStore(url: r.url).all().first?.id)
        #expect(span.name == TessRun.answerCheck && span.runID == runID)
        let json = try String(decoding: JSONEncoder().encode(span), as: UTF8.self)
        return (span, json, haiku.requestsSeen.count)
    }

    @Test func aReplyWhoseNumbersHeGavePasses() async throws {
        let checked = try await checkSpan("how many tasks 4321", reply: "4321")
        #expect(checked.span.outcome == "passed" && checked.span.unsupported == 0)
    }

    @Test func anUnsupportedNumberFailsInShadowAndNeverReachesTheTrace() async throws {
        let checked = try await checkSpan("how many tasks do I have", reply: "You have 9876 tasks")
        #expect(checked.span.outcome == "failed" && checked.span.unsupported == 1)
        #expect(!checked.json.contains("9876"))
        // Shadow: one request, no retry.
        #expect(checked.rounds == 1)
    }

    @Test func searchResultsCountAsEvidenceAndHerOwnWordsDoNot() {
        let found = Data(#"{"type":"web_search_tool_result","content":"About 650 kcal"}"#.utf8)
        let said = Data(#"{"type":"text","text":"I think 999"}"#.utf8)
        let evidence = TessRun.evidence(system: [TextBlock("voice")], fragments: [PackFragment("Today: 3 sets")],
                                        messages: [BrainMessage(.user, text: "ask"),
                                                   BrainMessage(.assistant, [.raw(found), .raw(said), .text("12")]),
                                                   BrainMessage(.user, [.toolResult(id: "t", content: "42",
                                                                                    isError: false)])])
        #expect(evidence.contains { $0.contains("650") } && !evidence.contains { $0.contains("999") })
        #expect(evidence.contains("Today: 3 sets") && evidence.contains("42") && evidence.contains("ask"))
        #expect(!evidence.contains("12"))
    }
}
