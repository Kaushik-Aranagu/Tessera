import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Memory and context spec M0: verbatim assistant content, search cost, the Haiku price step, cache TTL marks and
/// token counting.
@Suite(.serialized) @MainActor
struct HarnessM0Tests {
    static let searchResult = #"{"type":"web_search_tool_result","tool_use_id":"srvtoolu_1","content":[{"type":"web_search_result","url":"https://x.test/a","title":"A","encrypted_content":"EqgfCioIAhgB/+=="}]}"#

    /// The stream of one assistant message: thinking, a server web search with its result, and text.
    static let events: [String] = [
        #"{"type":"message_start","message":{"usage":{"input_tokens":100,"output_tokens":1}}}"#,
        #"{"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":"","signature":""}}"#,
        #"{"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"Let me search."}}"#,
        #"{"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"sig+/abc=="}}"#,
        #"{"type":"content_block_stop","index":0}"#,
        #"{"type":"content_block_start","index":1,"content_block":{"type":"server_tool_use","id":"srvtoolu_1","name":"web_search","input":{}}}"#,
        #"{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"query\":\"bench\"}"}}"#,
        #"{"type":"content_block_stop","index":1}"#,
        #"{"type":"content_block_start","index":2,"content_block":\#(searchResult)}"#,
        #"{"type":"content_block_stop","index":2}"#,
        #"{"type":"content_block_start","index":3,"content_block":{"type":"text","text":""}}"#,
        #"{"type":"content_block_delta","index":3,"delta":{"type":"text_delta","text":"Done."}}"#,
        #"{"type":"content_block_stop","index":3}"#,
        #"{"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":40,"server_tool_use":{"web_search_requests":1}}}"#,
        #"{"type":"message_stop"}"#,
    ]

    func parse(_ lines: [String]) async -> [BrainEvent] {
        var parser = SSEParser(model: .sonnet)
        var out: [BrainEvent] = []
        for line in lines {
            out += await parser.feed(Data(line.utf8))
        }
        return out
    }

    @Test func everyAssistantBlockIsKeptAndTheSearchResultIsByteForByte() async throws {
        let events = await parse(Self.events)
        guard case let .assistant(blocks)? = events.first(where: {
            if case .assistant = $0 {
                true
            } else {
                false
            }
        })
        else { Issue.record("no assistant event"); return }
        #expect(blocks.count == 4)
        let types = blocks
            .compactMap { (try? JSONSerialization.jsonObject(with: $0) as? [String: Any])?["type"] as? String }
        #expect(types == ["thinking", "server_tool_use", "web_search_tool_result", "text"])
        // A block that arrives whole is replayed as the exact bytes the API sent.
        #expect(String(decoding: blocks[2], as: UTF8.self) == Self.searchResult)
        // Thinking keeps its text and its signature.
        let thinking = try #require(try JSONSerialization.jsonObject(with: blocks[0]) as? [String: Any])
        #expect(thinking["thinking"] as? String == "Let me search." && thinking["signature"] as? String == "sig+/abc==")
        // The message ends with its assistant event before done.
        let tail = events.suffix(2)
        #expect(tail.first.map {
            if case .assistant = $0 {
                true
            } else {
                false
            }
        } == true)
    }

    @Test func theNextRequestSendsThoseBlocksBackUnchanged() async throws {
        let events = await parse(Self.events)
        guard case let .assistant(blocks)? = events.first(where: {
            if case .assistant = $0 {
                true
            } else {
                false
            }
        })
        else { Issue.record("no assistant event"); return }
        let request = BrainRequest(messages: [
            BrainMessage(.user, text: "search"),
            BrainMessage(.assistant, blocks.map(BrainContent.raw)),
            BrainMessage(.user, text: "and?"),
        ])
        let body = try String(decoding: ClaudeBrain.body(for: request, model: .sonnet, stream: true), as: UTF8.self)
        for block in blocks {
            #expect(body.contains(String(decoding: block, as: UTF8.self)))
        }
        #expect(body.contains(Self.searchResult) && !body.contains("__RAW_"))
        let parsed = try #require(JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])
        #expect((parsed["messages"] as? [[String: Any]])?.count == 3)
    }

    @Test func oneSearchAddsOneCentAndAFetchAddsNothing() async {
        let events = await parse(Self.events)
        guard case let .done(usage, _)? = events.last else { Issue.record("no done"); return }
        let tokens = TessUsageLedger.cost(model: "claude-sonnet-5-5", input: 100, output: 40)
        #expect(usage.webSearches == 1 && usage.costNano == tokens + 10_000_000)
        #expect(TessUsageLedger.cost(model: "claude-sonnet-5-5", input: 100, output: 40, webSearches: 0) == tokens)
    }

    @Test func aHaikuPromptOverAHundredThousandTokensIsCostedAtTheHigherRate() {
        let model = "claude-haiku-5-5"
        #expect(TessUsageLedger.cost(model: model, input: 100_000, output: 1000) == 100_000 * 100 + 1000 * 500)
        #expect(TessUsageLedger.cost(model: model, input: 120_000, output: 1000) == 120_000 * 500 + 1000 * 2500)
        // Cached tokens count toward the step too.
        #expect(TessUsageLedger
            .cost(model: model, input: 10000, output: 0, cacheRead: 95000) == 10000 * 500 + 95000 * 50)
        let big = String(repeating: "x", count: 480_000)
        #expect(TessUsageLedger.estimate(text: big, maxTokens: 1000, model: model) > 120_000 * 500)
        #expect(TessUsageLedger.estimate(text: "short", maxTokens: 10, model: model) < 100_000)
        // Sonnet has no step.
        #expect(TessUsageLedger.cost(model: "claude-sonnet-5-5", input: 120_000, output: 0) == 120_000 * 2000)
    }

    @Test func aOneHourMarkAfterAFiveMinuteMarkIsRejected() throws {
        func request(_ marks: [CacheMark]) -> BrainRequest {
            BrainRequest(
                system: [TextBlock("a"), TextBlock("b"), TextBlock("c")],
                messages: [BrainMessage(.user, text: "q")],
                cacheAfter: marks
            )
        }
        #expect(throws: BrainRequestError.cacheOrder) {
            try ClaudeBrain.body(for: request([CacheMark(0), CacheMark(1, .oneHour)]), model: .haiku, stream: true)
        }
        #expect(throws: BrainRequestError.tooManyBreakpoints) {
            try ClaudeBrain.body(for: request([0, 1, 2, 3, 4]), model: .haiku, stream: true)
        }
        let text = try String(decoding: ClaudeBrain.body(for: request([CacheMark(0, .oneHour), CacheMark(1, .oneHour),
                                                                       CacheMark(2)]),
                                                         model: .haiku, stream: true), as: UTF8.self)
        #expect(text.components(separatedBy: #""ttl":"1h""#).count == 3)
        #expect(text.components(separatedBy: "ephemeral").count == 4)
    }
}

/// These two use the shared URL stub, so they live in its serialized suite.
extension ClaudeBrainTests {
    @Test func countTokensSendsTheSameBodyMinusStreamAndMaxTokens() async throws {
        BrainStub.script([.init(body: #"{"input_tokens":1234}"#)])
        let brain = ClaudeBrain(
            model: .haiku,
            keys: InMemoryKeychain("sk-" + "ant-" + "COUNT-key-" + UUID().uuidString),
            session: BrainStub.session()
        )
        let request = BrainRequest(system: [TextBlock("Be brief.")], messages: [BrainMessage(.user, text: "Hello")],
                                   effort: .low)
        let counted = await brain.countTokens(request)
        #expect(counted == 1234)
        let sent = try #require(BrainStub.requests.first)
        #expect(sent.url?.path == "/v1/messages/count_tokens")
        let body = try #require(JSONSerialization.jsonObject(with: BrainStub.bodies[0]) as? [String: Any])
        #expect(body["stream"] == nil && body["max_tokens"] == nil && body["model"] as? String == "claude-haiku-5-5")
        #expect(body["system"] != nil && body["messages"] != nil)
        // No key, no call.
        BrainStub.script([])
        let none = ClaudeBrain(model: .haiku, keys: InMemoryKeychain(nil), session: BrainStub.session())
        #expect(await none.countTokens(request) == nil && BrainStub.requests.isEmpty)
    }

    @Test func aStreamedAnswerThroughTheBrainEndsWithItsAssistantBlocksBeforeDone() async {
        BrainStub.script([.init(body: HarnessM0Tests.events.map { "event: x\ndata: \($0)\n\n" }.joined())])
        let brain = ClaudeBrain(model: .sonnet, keys: InMemoryKeychain("sk-" + "ant-" + "M0-" + UUID().uuidString),
                                session: BrainStub.session())
        var kinds: [String] = []
        do {
            for try await event in brain.stream(BrainRequest(messages: [BrainMessage(.user, text: "hi")])) {
                switch event {
                case .assistant: kinds.append("assistant")
                case .done: kinds.append("done")
                case .text: kinds.append("text")
                default: break
                }
            }
        } catch {}
        #expect(kinds == ["text", "assistant", "done"])
    }
}
