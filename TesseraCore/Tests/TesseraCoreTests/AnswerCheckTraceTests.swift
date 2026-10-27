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
        // The span is written just after the reply is out, so nothing on the phone waits on it.
        var found: TraceSpan?
        for _ in 0 ..< 200 where found == nil {
            found = await r.rig.trace.all().first { $0.kind == .check }
            if found == nil {
                try await Task.sleep(for: .milliseconds(5))
            }
        }
        let span = try #require(found)
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
        // Only a result's readable words count: its id, URL and page age hold digits that would "support" a guess.
        let found = Data((#"{"type":"web_search_tool_result","tool_use_id":"srvtoolu_777","content":[{"#
                + #""type":"web_search_result","title":"About 650 kcal","url":"https://x.test/777","#
                + #""page_age":"777 days ago","encrypted_content":"777"}]}"#).utf8)
        let said = Data(#"{"type":"text","text":"I think 999"}"#.utf8)
        let evidence = TessRun.evidence(system: [TextBlock("voice")], fragments: [PackFragment("Today: 3 sets")],
                                        messages: [BrainMessage(.user, text: "ask"),
                                                   BrainMessage(.assistant, [.raw(found), .raw(said), .text("12")]),
                                                   BrainMessage(.user, [.toolResult(id: "t", content: "42",
                                                                                    isError: false)])])
        #expect(evidence.contains("About 650 kcal") && !evidence.contains { $0.contains("999") })
        #expect(!evidence.contains { $0.contains("777") })
        #expect(evidence.contains("Today: 3 sets") && evidence.contains("42") && evidence.contains("ask"))
        #expect(!evidence.contains("12"))
    }
}
