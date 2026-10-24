import Foundation
import TesseraCore

/// The Claude Messages API as a Brain (harness H1a): raw HTTP, `stream: true` (SSE), one long-lived URLSession per
/// app run. Models are Haiku 5.5 and Sonnet 5.5 only. No temperature, top_p or top_k (they are removed). The key is
/// read from the keychain inside each call into a local that only the `x-api-key` header sees: it is never logged,
/// printed, traced, stored or put in an error. Every redirect is refused (`NoRedirects`).
public final class ClaudeBrain: Brain, @unchecked Sendable {
    public enum Model: String, Sendable {
        case haiku = "claude-haiku-5-5"
        case sonnet = "claude-sonnet-5-5"
        /// Escalation only (Opus 5.5).
        case opus = "claude-opus-5-5"
    }

    public static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    public let model: Model
    fileprivate let keys: any TessKeychain
    fileprivate let session: URLSession
    fileprivate let url: URL

    public var id: BrainID {
        switch model {
        case .haiku: .haiku
        case .sonnet: .sonnet
        case .opus: .opus
        }
    }

    /// One session for the app run: connections stay warm between calls. Ephemeral: no cookies or disk cache.
    public static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = false
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    public init(
        model: Model,
        keys: any TessKeychain = SystemKeychain(),
        session: URLSession = ClaudeBrain.makeSession(),
        url: URL = ClaudeBrain.endpoint
    ) {
        self.model = model
        self.keys = keys
        self.session = session
        self.url = url
    }

    public var isAvailable: Bool {
        get async { keys.read() != nil }
    }

    // MARK: Request body

    /// The JSON body for a request. Pure and key-free, so a test can read exactly what would be sent. A `.raw` block is
    /// spliced in as the exact bytes the API sent. Throws when a 1-hour cache mark comes after a 5-minute one, or when
    /// there are more than four marks.
    public static func body(for request: BrainRequest, model: Model, stream: Bool,
                            maxTokens: Int? = nil) throws -> Data
    {
        let marks = request.cacheAfter.sorted { $0.index < $1.index }
        guard marks.count <= 4 else { throw BrainRequestError.tooManyBreakpoints }
        var seenShort = false
        for mark in marks {
            if mark.ttl == .fiveMinutes {
                seenShort = true
            } else if seenShort {
                throw BrainRequestError.cacheOrder
            }
        }
        var raws: [Data] = []
        // A token no message can contain: new for every body.
        let token = "__RAW_\(UUID().uuidString)_"
        var cacheIndex = 0
        func cacheControl() -> [String: Any]? {
            defer { cacheIndex += 1 }
            guard let mark = marks.first(where: { $0.index == cacheIndex }) else { return nil }
            return mark.ttl == .oneHour ? ["type": "ephemeral", "ttl": "1h"] : ["type": "ephemeral"]
        }
        var body: [String: Any] = ["model": model.rawValue, "max_tokens": maxTokens ?? request.maxTokens]
        if stream {
            body["stream"] = true
        }
        if !request.system.isEmpty {
            body["system"] = request.system.map { block -> [String: Any] in
                var item: [String: Any] = ["type": "text", "text": block.text]
                if let control = cacheControl() {
                    item["cache_control"] = control
                }
                return item
            }
        }
        body["messages"] = try request.messages.map { message -> [String: Any] in
            let content = try message.content.map { piece -> Any in
                switch piece {
                case let .raw(data):
                    raws.append(data)
                    return "\(token)\(raws.count - 1)__"
                case let .text(text):
                    var item: [String: Any] = ["type": "text", "text": text]
                    if let control = cacheControl() {
                        item["cache_control"] = control
                    }
                    return item
                case let .toolUse(id, name, input):
                    let object = try JSONSerialization.jsonObject(with: input.isEmpty ? Data("{}".utf8) : input)
                    return ["type": "tool_use", "id": id, "name": name, "input": object] as [String: Any]
                case let .toolResult(id, content, isError):
                    var item: [String: Any] = ["type": "tool_result", "tool_use_id": id, "content": content]
                    if isError {
                        item["is_error"] = true
                    }
                    return item
                }
            }
            return ["role": message.role.rawValue, "content": content]
        }
        if !request.tools.isEmpty {
            body["tools"] = try request.tools.map { tool -> [String: Any] in
                var item: [String: Any] = try [
                    "name": tool.name, "description": tool.description,
                    "input_schema": JSONSerialization.jsonObject(with: tool.schema),
                ]
                if tool.strict {
                    item["strict"] = true
                }
                if stream {
                    item["eager_input_streaming"] = true
                }
                return item
            }
            switch request.toolChoice {
            case .auto: body["tool_choice"] = ["type": "auto"]
            case .none: body["tool_choice"] = ["type": "none"]
            // Sonnet 5.5 and Opus 5.5 refuse forced tool use (a 400): auto, and the prompt names the tool.
            case .any: body["tool_choice"] = ["type": model == .haiku ? "any" : "auto"]
            case let .tool(name):
                body["tool_choice"] = model == .haiku ? ["type": "tool", "name": name] : ["type": "auto"]
            }
        }
        if let effort = request.effort {
            body["output_config"] = ["effort": effort.rawValue]
        }
        // Thinking is adaptive and on, except for a forced tool (Haiku only: it takes "disabled" at effort high or
        // below). Sonnet 5.5 refuses "disabled", and "between_tools" is its off; Opus 5.5 cannot switch it off at all.
        let forced: Bool = switch request.toolChoice {
        case .any, .tool: !request.tools.isEmpty && model == .haiku
        default: false
        }
        if forced {
            body["thinking"] = ["type": "disabled"]
        } else if request.thinking {
            body["thinking"] = ["type": "adaptive"]
        } else if model == .sonnet {
            body["thinking"] = ["type": "between_tools"]
        } else if model == .haiku {
            body["thinking"] = ["type": "disabled"]
        }
        let data = try JSONSerialization.data(withJSONObject: body)
        guard !raws.isEmpty, var text = String(data: data, encoding: .utf8) else { return data }
        for (index, raw) in raws.enumerated() {
            text = text.replacingOccurrences(of: "\"\(token)\(index)__\"",
                                             with: String(decoding: raw, as: UTF8.self))
        }
        return Data(text.utf8)
    }

    private func urlRequest(body: Data, key: String, timeout: TimeInterval) -> URLRequest {
        var http = URLRequest(url: url, timeoutInterval: timeout)
        http.httpMethod = "POST"
        http.setValue(key, forHTTPHeaderField: "x-api-key")
        http.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        http.setValue("application/json", forHTTPHeaderField: "content-type")
        http.httpBody = body
        return http
    }

    private static func seconds(_ duration: Duration) -> TimeInterval {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    // MARK: Stream

    public func stream(_ request: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error> {
        AsyncThrowingStream { continuation in
            let timer = Task {
                try? await Task.sleep(for: request.deadline)
                guard !Task.isCancelled else { return }
                continuation.yield(.failed(.timeout))
                continuation.finish()
            }
            let work = Task {
                await self.run(request, continuation: continuation)
                // The deadline is only for a call that hangs: once the work is done it goes.
                timer.cancel()
            }
            continuation.onTermination = { _ in
                work.cancel()
                timer.cancel()
            }
        }
    }

    private func run(_ request: BrainRequest, continuation: AsyncThrowingStream<BrainEvent, Error>.Continuation) async {
        guard let key = keys.read() else {
            continuation.yield(.failed(.badKey))
            continuation.finish()
            return
        }
        let body: Data
        do {
            body = try Self.body(for: request, model: model, stream: true)
        } catch {
            continuation.yield(.failed(.other))
            continuation.finish()
            return
        }
        do {
            let http = urlRequest(body: body, key: key, timeout: Self.seconds(request.deadline))
            let (bytes, response) = try await session.bytes(for: http, delegate: NoRedirects.shared)
            guard let status = (response as? HTTPURLResponse)?.statusCode else {
                continuation.yield(.failed(.other))
                continuation.finish()
                return
            }
            continuation.yield(.status(status))
            guard status == 200 else {
                var data = Data()
                for try await byte in bytes {
                    data.append(byte)
                    if data.count > 8192 {
                        break
                    }
                }
                let outcome = await MainActor.run { ClaudeKeyCheck.outcome(status: status, body: data) }
                continuation.yield(.failed(ClaudeOutcome(outcome)))
                continuation.finish()
                return
            }
            var parser = SSEParser(model: model)
            for try await line in bytes.lines {
                guard line.hasPrefix("data:") else { continue }
                let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                for event in await parser.feed(Data(payload.utf8)) {
                    continuation.yield(event)
                }
            }
            continuation.finish()
        } catch is CancellationError {
            continuation.finish()
        } catch let error as URLError {
            switch error.code {
            case .timedOut: continuation.yield(.failed(.timeout))
            case .cancelled: break
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost,
                 .cannotConnectToHost: continuation.yield(.failed(.offline))
            default: continuation.yield(.failed(.other))
            }
            continuation.finish()
        } catch {
            continuation.yield(.failed(.other))
            continuation.finish()
        }
    }

    // MARK: Warm

    /// The same system, tools and effort with `max_tokens: 0`, so the prefix is cached and the connection is open
    /// before the real call. If the API refuses 0, one token (`max_tokens: 1`). Returns the status and what worked.
    public func warm(_ prefix: BrainRequest) async -> BrainWarm? {
        guard let key = keys.read() else { return nil }
        var last: BrainWarm?
        for limit in [0, 1] {
            guard let body = try? Self.body(for: prefix, model: model, stream: false, maxTokens: limit) else {
                return last
            }
            let http = urlRequest(body: body, key: key, timeout: 10)
            guard let (data, response) = try? await session.data(for: http, delegate: NoRedirects.shared),
                  let status = (response as? HTTPURLResponse)?.statusCode else { return last }
            var usage = BrainUsage()
            if let used =
                ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["usage"] as? [String: Any]
            {
                usage = BrainUsage(
                    inTokens: used["input_tokens"] as? Int ?? 0,
                    outTokens: used["output_tokens"] as? Int ?? 0,
                    cacheReadTokens: used["cache_read_input_tokens"] as? Int ?? 0,
                    cacheWriteTokens: used["cache_creation_input_tokens"] as? Int ?? 0
                )
                let model = model.rawValue, counted = usage
                usage.costNano = await MainActor.run {
                    TessUsageLedger.cost(model: model, input: counted.inTokens, output: counted.outTokens,
                                         cacheRead: counted.cacheReadTokens, cacheWrite: counted.cacheWriteTokens)
                }
            }
            last = BrainWarm(status: status, maxTokens: limit, usage: usage)
            // Only a 400 for the zero sends the one-token form.
            if status != 400 {
                return last
            }
        }
        return last
    }
}

extension ClaudeBrain {
    /// `POST /v1/messages/count_tokens` (free): the same body as the request, minus `stream` and `max_tokens`. Used
    /// only by the meter's weekly calibration, and only through `Door.countTokens` (which applies the switch, the key
    /// scan, the policy scan and the sent log). Nil on any failure or with no key.
    func countTokens(_ request: BrainRequest) async -> Int? {
        guard let key = keys.read(),
              var body = (try? JSONSerialization.jsonObject(with: Self.body(for: request, model: model, stream: false)))
              as? [String: Any] else { return nil }
        body["max_tokens"] = nil
        body["stream"] = nil
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        var http = URLRequest(url: url.deletingLastPathComponent().appendingPathComponent("messages/count_tokens"),
                              timeoutInterval: 10)
        http.httpMethod = "POST"
        http.setValue(key, forHTTPHeaderField: "x-api-key")
        http.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        http.setValue("application/json", forHTTPHeaderField: "content-type")
        http.httpBody = data
        guard let (reply, response) = try? await session.data(for: http, delegate: NoRedirects.shared),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let object = (try? JSONSerialization.jsonObject(with: reply)) as? [String: Any] else { return nil }
        return object["input_tokens"] as? Int
    }
}

/// Reads the Messages API stream: text goes out as it arrives, a tool call goes out the moment its content block
/// closes (so its tool can start), every content block is kept as the API sent it, and the end carries the usage and
/// the stop reason.
struct SSEParser {
    let model: ClaudeBrain.Model
    private var usage = BrainUsage()
    private var stop = "end_turn"
    private var builders: [Int: Builder] = [:]
    private var finished: [Int: Data] = [:]

    /// One content block while it streams.
    private struct Builder {
        var type: String
        var id = ""
        var name = ""
        var text = ""
        var thinking = ""
        var signature = ""
        var json = ""
        var citations: [Any] = []
        /// The block's bytes from `content_block_start`, for types that arrive whole.
        var startRaw: Data?
    }

    init(model: ClaudeBrain.Model) {
        self.model = model
    }

    /// Block types that stream in pieces; every other type arrives whole in `content_block_start`.
    private static let streamed: Set<String> = ["text", "thinking", "tool_use", "server_tool_use"]

    mutating func feed(_ data: Data) async -> [BrainEvent] {
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let type = object["type"] as? String else { return [] }
        switch type {
        case "message_start":
            let message = object["message"] as? [String: Any]
            if let used = message?["usage"] as? [String: Any] {
                usage.inTokens = used["input_tokens"] as? Int ?? 0
                usage.cacheReadTokens = used["cache_read_input_tokens"] as? Int ?? 0
                usage.cacheWriteTokens = used["cache_creation_input_tokens"] as? Int ?? 0
                usage
                    .cacheWrite1hTokens =
                    (used["cache_creation"] as? [String: Any])?["ephemeral_1h_input_tokens"] as? Int ?? 0
                usage.outTokens = used["output_tokens"] as? Int ?? 0
                readSearches(used)
            }
            return []
        case "content_block_start":
            let index = object["index"] as? Int ?? 0
            guard let block = object["content_block"] as? [String: Any], let kind = block["type"] as? String else {
                return []
            }
            var builder = Builder(type: kind)
            builder.id = block["id"] as? String ?? ""
            builder.name = block["name"] as? String ?? ""
            builder.text = block["text"] as? String ?? ""
            builder.thinking = block["thinking"] as? String ?? ""
            builder.signature = block["signature"] as? String ?? ""
            if !Self.streamed.contains(kind) {
                builder.startRaw = Self.rawValue(of: "content_block", in: data)
            }
            builders[index] = builder
            return []
        case "content_block_delta":
            let index = object["index"] as? Int ?? 0
            guard let delta = object["delta"] as? [String: Any] else { return [] }
            switch delta["type"] as? String {
            case "text_delta":
                let piece = delta["text"] as? String ?? ""
                builders[index]?.text += piece
                return piece.isEmpty ? [] : [.text(piece)]
            case "input_json_delta":
                builders[index]?.json += delta["partial_json"] as? String ?? ""
            case "thinking_delta":
                builders[index]?.thinking += delta["thinking"] as? String ?? ""
            case "signature_delta":
                builders[index]?.signature += delta["signature"] as? String ?? ""
            case "citations_delta":
                if let citation = delta["citation"] {
                    builders[index]?.citations.append(citation)
                }
            default:
                break
            }
            return []
        case "content_block_stop":
            let index = object["index"] as? Int ?? 0
            guard let builder = builders.removeValue(forKey: index) else { return [] }
            let json = builder.json.isEmpty ? "{}" : builder.json
            let input = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any]
            switch builder.type {
            case "tool_use", "server_tool_use":
                // Eager input streaming can leave a cut-off or invalid input: validated before any tool runs.
                guard let input else { return [.failed(.other)] }
                finished[index] = Self.encode(["type": builder.type, "id": builder.id, "name": builder.name,
                                               "input": input])
                // A server tool (web search) runs on Anthropic's side: nothing for the phone to start.
                return builder.type == "tool_use" ? [.toolUse(id: builder.id, name: builder.name,
                                                              input: Data(json.utf8))] : []
            case "text":
                var block: [String: Any] = ["type": "text", "text": builder.text]
                if !builder.citations.isEmpty {
                    block["citations"] = builder.citations
                }
                finished[index] = Self.encode(block)
            case "thinking":
                finished[index] = Self.encode(["type": "thinking", "thinking": builder.thinking,
                                               "signature": builder.signature])
            default:
                finished[index] = builder.startRaw
            }
            return []
        case "message_delta":
            if let delta = object["delta"] as? [String: Any], let reason = delta["stop_reason"] as? String {
                stop = reason
            }
            if let used = object["usage"] as? [String: Any] {
                if let out = used["output_tokens"] as? Int {
                    usage.outTokens = out
                }
                readSearches(used)
            }
            return []
        case "message_stop":
            let model = model.rawValue
            let used = usage
            usage.costNano = await MainActor.run {
                TessUsageLedger.cost(model: model, input: used.inTokens, output: used.outTokens,
                                     cacheRead: used.cacheReadTokens, cacheWrite: used.cacheWriteTokens,
                                     cacheWrite1h: used.cacheWrite1hTokens, webSearches: used.webSearches)
            }
            if stop == "refusal" {
                return [.failed(.refused)]
            }
            let blocks = finished.keys.sorted().compactMap { finished[$0] }
            return (blocks.isEmpty ? [] : [.assistant(blocks)]) + [.done(usage, stop: stop)]
        case "error":
            let error = object["error"] as? [String: Any]
            let kind = error?["type"] as? String
            return [.failed(kind == "overloaded_error" ? .busy : kind == "rate_limit_error" ? .busy : .other)]
        default:
            return []
        }
    }

    private mutating func readSearches(_ used: [String: Any]) {
        if let server = used["server_tool_use"] as? [String: Any],
           let searches = server["web_search_requests"] as? Int
        {
            usage.webSearches = max(usage.webSearches, searches)
        }
    }

    /// A block rebuilt from its streamed pieces, with sorted keys so the bytes are the same every time.
    static func encode(_ block: [String: Any]) -> Data? {
        try? JSONSerialization.data(withJSONObject: block, options: [.sortedKeys, .withoutEscapingSlashes])
    }

    /// The exact bytes of a top-level key's value in a JSON text (an object, array or string), so a block that arrives
    /// whole (a search result with its encrypted content) is replayed byte for byte.
    static func rawValue(of key: String, in data: Data) -> Data? {
        let bytes = [UInt8](data)
        let needle = Array("\"\(key)\"".utf8)
        var start = 0
        // The key's first occurrence at the top level of the event: the event is a flat object whose nested values
        // come after, and the key is unique among them.
        guard let at = bytes.indices.first(where: { index in
            index + needle.count <= bytes.count && Array(bytes[index ..< index + needle.count]) == needle
        }) else { return nil }
        start = at + needle.count
        while start < bytes.count, bytes[start] == 0x20 || bytes[start] == 0x3A || bytes[start] == 0x0A {
            start += 1
        }
        guard start < bytes.count else { return nil }
        var depth = 0, inString = false, escaped = false
        var end = start
        while end < bytes.count {
            let byte = bytes[end]
            if inString {
                if escaped {
                    escaped = false
                } else if byte == 0x5C {
                    escaped = true
                } else if byte == 0x22 {
                    inString = false
                    if depth == 0 {
                        return Data(bytes[start ... end])
                    }
                }
            } else if byte == 0x22 {
                inString = true
            } else if byte == 0x7B || byte == 0x5B {
                depth += 1
            } else if byte == 0x7D || byte == 0x5D {
                depth -= 1
                if depth == 0 {
                    return Data(bytes[start ... end])
                }
            }
            end += 1
        }
        return nil
    }
}
