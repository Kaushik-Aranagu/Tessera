import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// A URLProtocol that answers Messages API calls from a script: it reads the request, replies with an SSE body or a
/// status, and can redirect. State is behind one lock.
final class BrainStub: URLProtocol, @unchecked Sendable {
    struct Reply {
        var status = 200
        var body = ""
        var redirect: String?
    }

    private struct State {
        var replies: [Reply] = []
        var requests: [URLRequest] = []
        var bodies: [Data] = []
    }

    private nonisolated(unsafe) static var state = State()
    private static let lock = NSLock()

    static func script(_ replies: [Reply]) {
        lock.withLock { state = State(replies: replies) }
    }

    static var requests: [URLRequest] {
        lock.withLock { state.requests }
    }

    static var bodies: [Data] {
        lock.withLock { state.bodies }
    }

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BrainStub.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        var data = Data()
        if let stream = request.httpBodyStream {
            stream.open()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                data.append(buffer, count: count)
            }
            stream.close()
        }
        let reply = Self.lock.withLock { () -> Reply in
            Self.state.requests.append(request)
            Self.state.bodies.append(data)
            return Self.state.replies.isEmpty ? Reply() : Self.state.replies.removeFirst()
        }
        if let target = reply.redirect, let url = URL(string: target) {
            let hop = HTTPURLResponse(url: request.url!, statusCode: 301, httpVersion: nil,
                                      headerFields: ["Location": target])!
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: url), redirectResponse: hop)
            client?.urlProtocol(self, didReceive: hop, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: nil,
                                       headerFields: ["request-id": "req_brain"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(reply.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// The ten-line stream of a short text answer.
private func sse(_ events: [[String: Any]]) -> String {
    events.map { event in
        let data = (try? JSONSerialization.data(withJSONObject: event, options: [.sortedKeys])) ?? Data()
        return "event: \(event["type"] as? String ?? "x")\ndata: \(String(data: data, encoding: .utf8) ?? "{}")\n\n"
    }.joined()
}

private func answer(_ text: String, input: Int = 300, output: Int = 12) -> String {
    sse([
        ["type": "message_start", "message": ["usage": ["input_tokens": input, "output_tokens": 1,
                                                        "cache_read_input_tokens": 100]]],
        ["type": "content_block_start", "index": 0, "content_block": ["type": "text", "text": ""]],
        ["type": "content_block_delta", "index": 0, "delta": ["type": "text_delta", "text": text]],
        ["type": "content_block_stop", "index": 0],
        ["type": "message_delta", "delta": ["stop_reason": "end_turn"], "usage": ["output_tokens": output]],
        ["type": "message_stop"],
    ])
}

@Suite(.serialized) @MainActor
struct ClaudeBrainTests {
    static let key = "sk-" + "ant-" + "BRAIN-" + UUID().uuidString
    let request = BrainRequest(system: [TextBlock("Be brief."), TextBlock("Big stable prefix.")],
                               messages: [BrainMessage(.user, text: "Hello")], effort: .low, cacheAfter: [1])

    func brain(_ model: ClaudeBrain.Model = .haiku, key: String? = ClaudeBrainTests.key) -> ClaudeBrain {
        ClaudeBrain(model: model, keys: InMemoryKeychain(key), session: BrainStub.session())
    }

    func collect(_ brain: ClaudeBrain, _ request: BrainRequest) async -> [BrainEvent] {
        var events: [BrainEvent] = []
        do {
            for try await event in brain.stream(request) {
                events.append(event)
            }
        } catch {}
        return events
    }

    // MARK: Body

    @Test func theBodyHasNoSamplingParametersAndTheRightShape() throws {
        let data = try ClaudeBrain.body(for: request, model: .haiku, stream: true)
        let text = String(decoding: data, as: UTF8.self)
        for banned in ["temperature", "top_p", "top_k"] {
            #expect(!text.contains(banned), "\(banned)")
        }
        let body = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(body["model"] as? String == "claude-haiku-5-5" && body["stream"] as? Bool == true)
        #expect((body["output_config"] as? [String: Any])?["effort"] as? String == "low")
        #expect((body["thinking"] as? [String: Any])?["type"] as? String == "disabled")
        let system = try #require(body["system"] as? [[String: Any]])
        #expect(system[0]["cache_control"] == nil && system[1]["cache_control"] != nil)
        let sonnet = try JSONSerialization.jsonObject(with: ClaudeBrain.body(
            for: request,
            model: .sonnet,
            stream: true
        ))
        #expect(((sonnet as? [String: Any])?["thinking"] as? [String: Any])?["type"] as? String == "between_tools")
    }

    @Test func forcedToolUseIsForSonnetOnlyAsAutoAndToolsAreStrictAndEager() throws {
        let tool = ToolSpec(name: "setPlaybook", description: "Sets it", schema: Data(#"{"type":"object"}"#.utf8))
        var forced = request
        forced.tools = [tool]
        forced.toolChoice = .tool("setPlaybook")
        func choice(_ model: ClaudeBrain.Model) throws -> [String: Any] {
            let body = try #require(JSONSerialization.jsonObject(
                with: ClaudeBrain.body(for: forced, model: model, stream: true)
            ) as? [String: Any])
            return try #require(body["tool_choice"] as? [String: Any])
        }
        #expect(try choice(.haiku)["type"] as? String == "tool" && choice(.haiku)["name"] as? String == "setPlaybook")
        #expect(try choice(.sonnet)["type"] as? String == "auto")
        let body = try #require(JSONSerialization.jsonObject(
            with: ClaudeBrain.body(for: forced, model: .haiku, stream: true)
        ) as? [String: Any])
        let item = try #require((body["tools"] as? [[String: Any]])?.first)
        #expect(item["strict"] as? Bool == true && item["eager_input_streaming"] as? Bool == true)
        let plain = try #require(JSONSerialization.jsonObject(
            with: ClaudeBrain.body(for: forced, model: .haiku, stream: false)
        ) as? [String: Any])
        #expect((plain["tools"] as? [[String: Any]])?.first?["eager_input_streaming"] == nil)
    }

    // MARK: Stream

    @Test func aTextAnswerStreamsAndEndsWithUsageAndCost() async {
        BrainStub.script([.init(body: answer("Hi there"))])
        let events = await collect(brain(), request)
        var text = "", usage: BrainUsage?
        for event in events {
            switch event {
            case let .text(piece): text += piece
            case let .done(used, stop: stop): usage = used; #expect(stop == "end_turn")
            default: break
            }
        }
        #expect(text == "Hi there")
        #expect(usage?.inTokens == 300 && usage?.outTokens == 12 && usage?.cacheReadTokens == 100)
        #expect((usage?.costNano ?? 0) > 0)
        let sent = BrainStub.requests[0]
        #expect(sent.value(forHTTPHeaderField: "x-api-key") == Self.key)
        #expect(sent.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(!String(decoding: BrainStub.bodies[0], as: UTF8.self).contains(Self.key))
    }

    @Test func aToolCallIsHandedOverTheMomentItsBlockCloses() async {
        let stream = sse([
            ["type": "message_start", "message": ["usage": ["input_tokens": 10, "output_tokens": 1]]],
            ["type": "content_block_start", "index": 0,
             "content_block": ["type": "tool_use", "id": "toolu_1", "name": "setPlaybook", "input": [:]]],
            [
                "type": "content_block_delta",
                "index": 0,
                "delta": ["type": "input_json_delta", "partial_json": "{\"a\":"],
            ],
            ["type": "content_block_delta", "index": 0, "delta": ["type": "input_json_delta", "partial_json": "1}"]],
            ["type": "content_block_stop", "index": 0],
            ["type": "message_delta", "delta": ["stop_reason": "tool_use"], "usage": ["output_tokens": 9]],
            ["type": "message_stop"],
        ])
        BrainStub.script([.init(body: stream)])
        let events = await collect(brain(), request)
        guard case let .toolUse(id, name, input)? = events.first(where: {
            if case .toolUse = $0 {
                true
            } else {
                false
            }
        }) else { Issue.record("no tool call"); return }
        #expect(id == "toolu_1" && name == "setPlaybook" && String(decoding: input, as: UTF8.self) == #"{"a":1}"#)
    }

    @Test func aCutOffToolInputFailsInsteadOfRunning() async {
        let stream = sse([
            ["type": "content_block_start", "index": 0,
             "content_block": ["type": "tool_use", "id": "t", "name": "x", "input": [:]]],
            [
                "type": "content_block_delta",
                "index": 0,
                "delta": ["type": "input_json_delta", "partial_json": "{\"a\":"],
            ],
            ["type": "content_block_stop", "index": 0],
        ])
        BrainStub.script([.init(body: stream)])
        let events = await collect(brain(), request)
        #expect(!events.contains {
            if case .toolUse = $0 {
                true
            } else {
                false
            }
        })
        #expect(events.contains {
            if case .failed(.other) = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func aRefusalIsAFailureAndStatusesMapToOutcomes() async {
        BrainStub.script([.init(body: sse([
            ["type": "message_start", "message": ["usage": ["input_tokens": 1, "output_tokens": 1]]],
            ["type": "message_delta", "delta": ["stop_reason": "refusal"], "usage": ["output_tokens": 1]],
            ["type": "message_stop"],
        ]))])
        let refused = await collect(brain(), request)
        #expect(refused.contains {
            if case .failed(.refused) = $0 {
                true
            } else {
                false
            }
        })
        BrainStub.script([.init(status: 401, body: #"{"error":{"type":"authentication_error","message":"x"}}"#)])
        let bad = await collect(brain(), request)
        #expect(bad.contains {
            if case .failed(.badKey) = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func noKeyMeansNoRequest() async {
        BrainStub.script([])
        let events = await collect(brain(key: nil), request)
        #expect(events.contains {
            if case .failed(.badKey) = $0 {
                true
            } else {
                false
            }
        })
        #expect(BrainStub.requests.isEmpty)
        let without = await brain(key: nil).isAvailable, with = await brain().isAvailable
        #expect(!without && with)
    }

    @Test func aRedirectIsNeverFollowed() async {
        BrainStub.script([.init(redirect: "https://evil.example/steal"), .init(body: answer("leak"))])
        let events = await collect(brain(), request)
        #expect(BrainStub.requests.count == 1)
        #expect(!events.contains {
            if case .text = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func warmUsesZeroTokensAndFallsBackToOne() async throws {
        BrainStub.script([
            .init(status: 400, body: #"{"error":{"type":"invalid_request_error","message":"max_tokens"}}"#),
            .init(body: answer("")),
        ])
        await brain().warm(request)
        #expect(BrainStub.bodies.count == 2)
        let limits = try BrainStub.bodies.map {
            try #require((JSONSerialization.jsonObject(with: $0) as? [String: Any])?["max_tokens"] as? Int)
        }
        #expect(limits == [0, 1])
        BrainStub.script([.init(body: answer(""))])
        await brain().warm(request)
        #expect(BrainStub.bodies.count == 1)
    }

    @Test func theKeyIsNeverInAnEventOrAnError() async {
        BrainStub.script([.init(status: 500, body: "boom \(Self.key)")])
        let events = await collect(brain(), request)
        #expect(!"\(events)".contains(Self.key))
    }
}
