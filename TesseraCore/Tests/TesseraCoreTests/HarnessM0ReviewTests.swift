import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// QA's #1375 review: 1-hour cache writes at 2x, citations kept, scans on decoded words, count_tokens through the Door.
@MainActor
struct HarnessM0ReviewTests {
    @Test func aOneHourCacheWriteIsChargedAtTwiceTheInputPrice() {
        // 10K tokens written: 4K with the 5-minute lifetime (1.25x), 6K with the 1-hour one (2x).
        let cost = TessUsageLedger.cost(model: "claude-sonnet-5-5", input: 0, output: 0, cacheWrite: 10000,
                                        cacheWrite1h: 6000)
        #expect(cost == 4000 * 2500 + 6000 * 2 * 2000)
        #expect(TessUsageLedger.cost(model: "claude-haiku-5-5", input: 0, output: 0, cacheWrite: 1000,
                                     cacheWrite1h: 1000) == 1000 * 2 * 100)
    }

    @Test func theParserReadsTheOneHourSplitAndKeepsCitations() async throws {
        let lines = [
            #"{"type":"message_start","message":{"usage":{"input_tokens":10,"output_tokens":1,"cache_creation_input_tokens":2000,"cache_creation":{"ephemeral_5m_input_tokens":500,"ephemeral_1h_input_tokens":1500}}}}"#,
            #"{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#,
            #"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Cited"}}"#,
            #"{"type":"content_block_delta","index":0,"delta":{"type":"citations_delta","citation":{"type":"char_location","cited_text":"x","document_index":0}}}"#,
            #"{"type":"content_block_stop","index":0}"#,
            #"{"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":5}}"#,
            #"{"type":"message_stop"}"#,
        ]
        let events = await HarnessM0Tests().parse(lines)
        guard case let .done(usage, _)? = events.last else { Issue.record("no done"); return }
        #expect(usage.cacheWriteTokens == 2000 && usage.cacheWrite1hTokens == 1500)
        #expect(usage.costNano == TessUsageLedger.cost(model: "claude-sonnet-5-5", input: 10, output: 5,
                                                       cacheWrite: 2000, cacheWrite1h: 1500))
        guard case let .assistant(blocks)? = events.first(where: {
            if case .assistant = $0 {
                true
            } else {
                false
            }
        })
        else { Issue.record("no assistant"); return }
        let block = try #require(JSONSerialization.jsonObject(with: blocks[0]) as? [String: Any])
        #expect((block["citations"] as? [[String: Any]])?.first?["cited_text"] as? String == "x")
    }

    @Test func aScanSeesDecodedWordsNotEscapedJSON() {
        // "kg" spelled with a unicode escape inside a replayed tool_use input: the raw text hides it, the decoded value
        // does not.
        let escape = "\\" + "u0067" // a backslash and u0067, written out so a formatter cannot fold it
        let block =
            Data(("{\"type\":\"tool_use\",\"id\":\"t\",\"name\":\"x\",\"input\":{\"note\":\"I weigh 82.4 k" + escape +
                    "\"}}").utf8)
        #expect(!String(decoding: block, as: UTF8.self).contains("82.4 kg"))
        #expect(Door.jsonStrings(block).contains("I weigh 82.4 kg"))
        #expect(Door.jsonStrings(Data("not json".utf8)) == ["not json"])
    }

    @Test func theSpliceTokenIsNewForEveryBody() throws {
        let request = BrainRequest(messages: [BrainMessage(
            .assistant,
            [.raw(Data(#"{"type":"text","text":"a"}"#.utf8))]
        )])
        let one = try String(decoding: ClaudeBrain.body(for: request, model: .haiku, stream: true), as: UTF8.self)
        // A message that happens to contain the old fixed token is left alone.
        let tricky = BrainRequest(messages: [BrainMessage(.user, text: "__TESSRAW_0__")])
        let two = try String(decoding: ClaudeBrain.body(for: tricky, model: .haiku, stream: true), as: UTF8.self)
        #expect(one.contains(#""text":"a""#) && two.contains("__TESSRAW_0__"))
    }
}

extension ClaudeBrainTests {
    @Test(.oldWalls) func countTokensGoesThroughTheDoorsGate() async throws {
        let key = "sk-" + "ant-" + "CT-" + UUID().uuidString
        let brain = ClaudeBrain(model: .haiku, keys: InMemoryKeychain(key), session: BrainStub.session())
        let plain = BrainRequest(system: [TextBlock("Be brief")], messages: [BrainMessage(.user, text: "Hello")])
        let walled = BrainRequest(messages: [BrainMessage(.user, text: "I weigh 82.4 kg")])
        // Lab: it is sent, and the exact words are in What was sent.
        BrainStub.script([.init(body: #"{"input_tokens":77}"#)])
        let lab = try DoorRig(brains: [.haiku: brain], policy: .lab)
        #expect(await lab.door.countTokens(.haiku, walled) == 77)
        #expect(lab.sent.entries().count == 1 && BrainStub.requests.count == 1)
        // Tess asks Claude off: nothing is sent.
        BrainStub.script([.init(body: #"{"input_tokens":1}"#)])
        let off = try DoorRig(brains: [.haiku: brain], asks: false)
        #expect(await off.door.countTokens(.haiku, plain) == nil && BrainStub.requests.isEmpty)
        // Strict with walled words: nothing is sent and nothing is logged.
        let strict = try DoorRig(brains: [.haiku: brain], policy: .strict)
        #expect(await strict.door.countTokens(.haiku, walled) == nil && BrainStub.requests.isEmpty)
        #expect(strict.sent.entries().isEmpty)
        // Strict with plain words goes, as an inexact row.
        BrainStub.script([.init(body: #"{"input_tokens":5}"#)])
        #expect(await strict.door.countTokens(.haiku, plain) == 5 && strict.sent.entries().count == 1)
        // A key-shaped string is refused, and so is a money action tool.
        let keyed = BrainRequest(messages: [BrainMessage(
            .user, text: "key " + "sk-" + "ant-" + "api03-" + String(repeating: "Ab3x", count: 8)
        )])
        BrainStub.script([.init(body: #"{"input_tokens":1}"#)])
        #expect(await lab.door.countTokens(.haiku, keyed) == nil && BrainStub.requests.isEmpty)
        var money = plain
        money.tools = [ToolSpec(name: "logSpend", description: "x", schema: Data("{}".utf8))]
        #expect(await lab.door.countTokens(.haiku, money) == nil && BrainStub.requests.isEmpty)
    }
}
