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
    }

    public static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    public let model: Model
    private let keys: any TessKeychain
    private let session: URLSession
    private let url: URL

    public var id: BrainID {
        model == .haiku ? .haiku : .sonnet
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

    /// The JSON body for a request. Pure and key-free, so a test can read exactly what would be sent.
    public static func body(for request: BrainRequest, model: Model, stream: Bool,
                            maxTokens: Int? = nil) throws -> Data
    {
        var cacheIndex = 0
        func cacheControl() -> [String: Any]? {
            defer { cacheIndex += 1 }
            return request.cacheAfter.contains(cacheIndex) ? ["type": "ephemeral"] : nil
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
            let content = try message.content.map { piece -> [String: Any] in
                switch piece {
                case let .text(text):
                    var item: [String: Any] = ["type": "text", "text": text]
                    if let control = cacheControl() {
                        item["cache_control"] = control
                    }
                    return item
                case let .toolUse(id, name, input):
                    let object = try JSONSerialization.jsonObject(with: input.isEmpty ? Data("{}".utf8) : input)
                    return ["type": "tool_use", "id": id, "name": name, "input": object]
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
            // Sonnet 5.5 refuses forced tool use (a 400): auto, and the prompt names the tool.
            case .any: body["tool_choice"] = ["type": model == .sonnet ? "auto" : "any"]
            case let .tool(name):
                body["tool_choice"] = model == .sonnet ? ["type": "auto"] : ["type": "tool", "name": name]
            }
        }
        if let effort = request.effort {
            body["output_config"] = ["effort": effort.rawValue]
        }
        // Thinking: Haiku 5.5 may be switched off; Sonnet 5.5 refuses "disabled", and "between_tools" is its off.
        if !request.thinking {
            body["thinking"] = ["type": model == .sonnet ? "between_tools" : "disabled"]
        }
        return try JSONSerialization.data(withJSONObject: body)
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
            let work = Task {
                await self.run(request, continuation: continuation)
            }
            let timer = Task {
                try? await Task.sleep(for: request.deadline)
                guard !work.isCancelled else { return }
                work.cancel()
                continuation.yield(.failed(.timeout))
                continuation.finish()
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
    /// before the real call. If the API refuses 0, one token (`max_tokens: 1`).
    public func warm(_ prefix: BrainRequest) async {
        guard let key = keys.read() else { return }
        for limit in [0, 1] {
            guard let body = try? Self.body(for: prefix, model: model, stream: false, maxTokens: limit) else { return }
            let http = urlRequest(body: body, key: key, timeout: 10)
            guard let (data, response) = try? await session.data(for: http, delegate: NoRedirects.shared),
                  let status = (response as? HTTPURLResponse)?.statusCode else { return }
            if status == 200 || status != 400 {
                return
            }
            // A 400 for the zero: try the one-token form, once.
            _ = data
        }
    }
}

/// Reads the Messages API stream: text goes out as it arrives, a tool call goes out the moment its content block
/// closes (so its tool can start), and the end carries the usage and the stop reason.
struct SSEParser {
    let model: ClaudeBrain.Model
    private var usage = BrainUsage()
    private var stop = "end_turn"
    private var tools: [Int: (id: String, name: String, json: String)] = [:]

    init(model: ClaudeBrain.Model) {
        self.model = model
    }

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
                usage.outTokens = used["output_tokens"] as? Int ?? 0
            }
            return []
        case "content_block_start":
            let index = object["index"] as? Int ?? 0
            if let block = object["content_block"] as? [String: Any], block["type"] as? String == "tool_use" {
                tools[index] = (block["id"] as? String ?? "", block["name"] as? String ?? "", "")
            }
            return []
        case "content_block_delta":
            let index = object["index"] as? Int ?? 0
            guard let delta = object["delta"] as? [String: Any] else { return [] }
            switch delta["type"] as? String {
            case "text_delta":
                return (delta["text"] as? String).map { [.text($0)] } ?? []
            case "input_json_delta":
                tools[index]?.json += delta["partial_json"] as? String ?? ""
                return []
            default:
                return []
            }
        case "content_block_stop":
            let index = object["index"] as? Int ?? 0
            guard let tool = tools.removeValue(forKey: index) else { return [] }
            let json = tool.json.isEmpty ? "{}" : tool.json
            let valid = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any]
            // Eager input streaming can leave a cut-off or invalid input: validated before any tool runs.
            guard valid != nil else { return [.failed(.other)] }
            return [.toolUse(id: tool.id, name: tool.name, input: Data(json.utf8))]
        case "message_delta":
            if let delta = object["delta"] as? [String: Any], let reason = delta["stop_reason"] as? String {
                stop = reason
            }
            if let used = object["usage"] as? [String: Any], let out = used["output_tokens"] as? Int {
                usage.outTokens = out
            }
            return []
        case "message_stop":
            let model = model.rawValue
            let used = usage
            usage.costNano = await MainActor.run {
                TessUsageLedger.cost(model: model, input: used.inTokens, output: used.outTokens,
                                     cacheRead: used.cacheReadTokens, cacheWrite: used.cacheWriteTokens)
            }
            return [stop == "refusal" ? .failed(.refused) : .done(usage, stop: stop)]
        case "error":
            let error = object["error"] as? [String: Any]
            let kind = error?["type"] as? String
            return [.failed(kind == "overloaded_error" ? .busy : kind == "rate_limit_error" ? .busy : .other)]
        default:
            return []
        }
    }
}
