import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Accuracy first (Oct 23, 6:14 PM PT): the $100 runaway guard, Opus as an escalation rung only, adaptive thinking
/// everywhere except a forced tool; and QA's #1375 lows (keys scanned, readable sent log).
@MainActor
struct HarnessAccuracyTests {
    func body(_ request: BrainRequest, _ model: ClaudeBrain.Model) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: ClaudeBrain.body(for: request, model: model, stream: true))
            as? [String: Any])
    }

    func thinking(_ body: [String: Any]) -> String? {
        (body["thinking"] as? [String: Any])?["type"] as? String
    }

    @Test func theCapIsOneHundredDollarsAsARunawayGuard() {
        #expect(TessUsageLedger.capNano == 100_000_000_000 && TessUsageLedger.capDollars == 100)
        #expect(TessUsageLedger.cost(model: "claude-opus-5-5", input: 1000, output: 100) == 1000 * 4000 + 100 * 20000)
    }

    @Test func thinkingIsAdaptiveUnlessAHaikuToolIsForced() throws {
        let tool = ToolSpec(name: "setPlaybook", description: "x", schema: Data(#"{"type":"object"}"#.utf8))
        var plain = BrainRequest(messages: [BrainMessage(.user, text: "hi")])
        for model in [ClaudeBrain.Model.haiku, .sonnet, .opus] {
            #expect(try thinking(body(plain, model)) == "adaptive", "\(model)")
        }
        plain.tools = [tool]
        plain.toolChoice = .tool("setPlaybook")
        // Haiku forces the tool and so thinks not at all; Sonnet and Opus get auto and think.
        #expect(try thinking(body(plain, .haiku)) == "disabled")
        #expect(try thinking(body(plain, .sonnet)) == "adaptive" && thinking(body(plain, .opus)) == "adaptive")
        #expect(try (body(plain, .opus)["tool_choice"] as? [String: Any])?["type"] as? String == "auto")
        #expect(try (body(plain, .haiku)["tool_choice"] as? [String: Any])?["type"] as? String == "tool")
        // Thinking can be asked off: Opus can't be told to stop at all.
        var off = BrainRequest(messages: [BrainMessage(.user, text: "hi")])
        off.thinking = false
        #expect(try thinking(body(off, .haiku)) == "disabled" && thinking(body(off, .sonnet)) == "between_tools")
        #expect(try thinking(body(off, .opus)) == nil)
    }

    @Test func opusIsNeverTheFirstRung() async throws {
        let opus = FakeBrain(.opus), haiku = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.opus: opus, .haiku: haiku])
        let job = DoorJob(name: "t", ladder: [.opus, .haiku], request: DoorTests.ask, estimateNano: 1000)
        let first = await rig.events(job)
        #expect(first.failure == .refused && opus.streamCount == 0 && haiku.streamCount == 0)
        // As the second try it runs, when the first failed.
        haiku.outcome = .busy
        let second = await rig.events(DoorJob(
            name: "t",
            ladder: [.haiku, .opus],
            request: DoorTests.ask,
            estimateNano: 1000
        ))
        #expect(second.text == "ok" && opus.streamCount == 1)
        #expect(BrainRouter.isClaude(.opus))
    }

    // MARK: #1375 lows

    @Test func aKeyInAToolInputIsScannedUnderStrict() {
        let input = Data(#"{"lexapro": 1}"#.utf8)
        #expect(Door.jsonStrings(input).contains("lexapro"))
        let rig = try? DoorRig(brains: [:], policy: .strict)
        var request = BrainRequest(messages: [BrainMessage(.user, text: "ok")])
        request.messages.append(BrainMessage(.assistant, [.toolUse(id: "1", name: "x", input: input)]))
        // A secret word as an object key is words too.
        #expect(Door.requestText(request).contains("lexapro"))
        _ = rig
    }

    @Test func theSentLogShowsWordsNotBracesSignaturesOrBlobs() {
        let thinking = Data(#"{"type":"thinking","thinking":"Counting sets.","signature":"SIGNATUREBLOB=="}"#.utf8)
        let result = Data(HarnessM0Tests.searchResult.utf8)
        let use = Data(#"{"type":"tool_use","id":"toolu_9","name":"answerQuery","input":{"from":"tasks"}}"#.utf8)
        let request = BrainRequest(messages: [BrainMessage(.assistant, [.raw(thinking), .raw(result), .raw(use)])])
        let words = Door.words(request)
        for noise in ["{", "}", "SIGNATUREBLOB", "EqgfCioIAhgB", "toolu_9", "srvtoolu_1", "tool_use"] {
            #expect(!words.contains(noise), "\(noise)")
        }
        #expect(words.contains("Counting sets.") && words.contains("answerQuery") && words.contains("tasks"))
        #expect(words.contains("https://x.test/a"))
    }
}
