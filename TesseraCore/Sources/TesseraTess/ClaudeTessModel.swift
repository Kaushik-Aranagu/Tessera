import Foundation
import TesseraCore

/// The Claude step of capture (docs/research/tess-model-layer.md, T3): after the grammar and the on-device model miss,
/// Haiku gets the phrase and the same tools (`TessTools`), and every tool call runs the typed action as Tess, pending,
/// so it lands as a ghost row with undo. Runs only with a key, "Misses go to Claude" on, no "Not today" pause, and
/// money left in the month. The key goes only in this request's header.
@MainActor
public struct ClaudeTessModel: TessModel {
    public static let model = "claude-haiku-5-5"
    static let maxTokens = 512
    /// Tool rounds before Tess gives up on a phrase.
    static let maxRounds = 3

    public let keys: any TessKeychain
    public let ledger: TessUsageLedger
    public let session: URLSession
    public let flags: ClaudeMissFlags
    /// "Misses go to Claude" (`SettingsStore.read().sendsMissesToClaude`), read at each call.
    public var sendsMisses: () -> Bool
    public var timeout: TimeInterval = 8
    /// Set while reading the waiting phrases, so a retry that's offline again doesn't queue twice.
    var retrying = false
    public var now: () -> Date = { .now }
    public var calendar: Calendar = .current

    public init(keys: any TessKeychain, ledger: TessUsageLedger, flags: ClaudeMissFlags,
                session: URLSession = URLSession(configuration: .ephemeral), sendsMisses: @escaping () -> Bool)
    {
        self.keys = keys
        self.ledger = ledger
        self.flags = flags
        self.session = session
        self.sendsMisses = sendsMisses
    }

    public var route: OpRoute {
        .claude
    }

    public var modelName: String? {
        Self.model
    }

    public func isAvailable(for use: TessUse) -> Bool {
        use == .capture && keys.read() != nil && sendsMisses() && !flags.isPaused(now: now())
    }

    public func run(_ request: TessRequest, engine: ActionEngine) async -> TessResult {
        // Siri and Shortcuts commit at once (no ghost, no UNDO): Claude never writes for them (QA R3 on #283).
        guard !request.context.commitImmediately, let key = keys.read() else { return .missed }
        // The switch and the key shape are checked here too, not only in `isAvailable` and the router: a direct
        // caller must not skip them (a4-bypass item 3).
        guard sendsMisses(), !looksLikeClaudeKey(request.text) else { return .missed }
        // The second wall (MU2, Research 138 MW4 and 139): a secret, money or body phrase never leaves, even from the
        // inbox or a direct caller. The inbox drains through here, so an old item queued before the wall is dropped.
        guard !SecretWords.mentions(request.text), !PrivateFacts.isWalled(
            request.text,
            lastWeightKg: request.lastWeightKg(engine)
        ) else { return .missed }
        // Every round resends the system prompt and the tool definitions with the phrase (QA on #283).
        let system = system(request.context, engine: engine, lastWeightKg: request.lastWeightKg(engine))
        guard !looksLikeClaudeKey(system) else { return .missed }
        let tools = (try? TessTools.definitionsJSON()).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let estimate = TessUsageLedger.estimate(text: request.text + system + tools,
                                                maxTokens: Self.maxTokens, model: Self.model) * Int64(Self.maxRounds)
        guard let reservation = ledger.reserve(estimate, now: now(), calendar: calendar) else {
            // At the cap: the rules and on-device paths go on; Tess says so if nothing else caught it.
            let reset = (calendar.dateInterval(of: .month, for: now())?.end ?? now())
                .formatted(.dateTime.month(.abbreviated).day())
            return .asked(TessCapture(records: [], line: "Claude paused until \(reset).", source: .none))
        }
        defer { ledger.settle(reservation) }
        let started = Date()
        var conversation: [[String: Any]] = [["role": "user", "content": request.text]]
        var records: [OpRecord] = []
        var usage = Usage()
        var requestID: String?
        var reply = ""
        do {
            for _ in 0 ..< Self.maxRounds {
                let response = try await send(conversation, system: system, key: key)
                usage.add(response.usage)
                requestID = response.requestID ?? requestID
                reply = response.text
                // Cut off or refused: no ghosts, the plain miss line (QA L1 on #283).
                if ["max_tokens", "refusal"].contains(response.stopReason) {
                    throw Failure.other
                }
                guard !response.toolCalls.isEmpty else { break }
                conversation.append(["role": "assistant", "content": response.content])
                var results: [[String: Any]] = []
                for call in response.toolCalls {
                    // One phrase leaves at most `maxRecordsPerPhrase` ghosts, however many calls Claude makes.
                    guard records.count < TessTools.maxRecordsPerPhrase else {
                        results.append(["type": "tool_result", "tool_use_id": call.id, "content": TessTools.capLine,
                                        "is_error": true])
                        continue
                    }
                    do {
                        let done = try TessTools.run(call.name, arguments: call.input, engine: engine,
                                                     pending: true, now: request.context.now,
                                                     calendar: request.context.calendar,
                                                     budget: TessTools.maxRecordsPerPhrase - records.count)
                        records += done
                        trim(&records, engine: engine)
                        results.append(["type": "tool_result", "tool_use_id": call.id, "content": "Done"])
                    } catch let answer as TessToolAnswer {
                        results.append(["type": "tool_result", "tool_use_id": call.id, "content": answer.line])
                    } catch {
                        // A fixed line per case, never an internal error's text (QA on #283).
                        let said = error is TessToolError ? "Error: that name or value didn't fit. Try another."
                            : "Error: that didn't work."
                        results.append(["type": "tool_result", "tool_use_id": call.id, "content": said,
                                        "is_error": true])
                    }
                }
                conversation.append(["role": "user", "content": results])
            }
        } catch {
            // Every call writes its row, an unreadable reply included (QA on #283).
            let failure = error as? Failure ?? .other
            usage.add(failure.used)
            ledger.record(use: .capture, model: Self.model, input: usage.input, output: usage.output,
                          costNano: usage.cost, latency: Date().timeIntervalSince(started),
                          outcome: failure.outcome, requestID: requestID, at: now())
            discard(records, engine: engine)
            // Offline: the phrase waits for Claude instead of being lost (section 7), unless it's already a retry.
            if failure.outcome == "offline", !retrying,
               TessInbox(store: engine.store, classes: engine.classes).add(request.text, at: now()) != nil
            {
                return .asked(TessCapture(records: [], line: "No connection. Saved it for Claude.", source: .none))
            }
            return error is Failure ? .asked(TessCapture(records: [], line: failure.line, source: .none)) : .missed
        }
        ledger.record(use: .capture, model: Self.model, input: usage.input, output: usage.output,
                      costNano: usage.cost, latency: Date().timeIntervalSince(started),
                      outcome: records.isEmpty ? "nothing" : "works", requestID: requestID, at: now())
        guard !records.isEmpty else { return .missed }
        // Never claim more than was done: Claude's own line only if it passes Tess's voice checks.
        var line = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty || !TessVoice.violations(in: line).isEmpty {
            // Thing first when the action has a spoken form (RC23); the log summary is never read aloud raw.
            line = records.count == 1 ? (records[0].receipt ?? records[
                0
            ].summary) + "." : "\(records.count) things done."
        }
        // The first miss ever sent says where it went, once (Product 8:28 PM PT Oct 15).
        if !flags.noticeShown {
            flags.noticeShown = true
            line = "Sent \u{201C}\(request.text)\u{201D} to Claude. Turn this off in Settings: Claude."
        }
        return .handled(TessCapture(records: records, line: line, source: .claude))
    }

    /// Takes back any ghost past the per-phrase cap (a single call may write several).
    private func trim(_ records: inout [OpRecord], engine: ActionEngine) {
        guard records.count > TessTools.maxRecordsPerPhrase else { return }
        discard(Array(records[TessTools.maxRecordsPerPhrase...]), engine: engine)
        records.removeLast(records.count - TessTools.maxRecordsPerPhrase)
    }

    private func discard(_ records: [OpRecord], engine: ActionEngine) {
        for record in records.reversed() {
            if record.state == .pending {
                _ = try? engine.discard(record)
            } else {
                engine.undo(record)
            }
        }
    }

    /// The capture pack: today, the workout and last set in focus, and Tess's rules. Never notes, health or history.
    /// The exercise name is his free text: a name that trips the wall (a secret word, money, a body fact, a key) sends
    /// "no workout in focus" and no last set (a4-bypass item 1).
    func system(_ context: TessContext, engine: ActionEngine, lastWeightKg: Double?) -> String {
        let walled = Self.exerciseIsWalled(context, engine: engine, lastWeightKg: lastWeightKg)
        return TessVoice.instructions(
            today: TessModelCapture.today(context),
            currentWorkout: walled ? "no workout in focus" : TessModelCapture.workout(context, engine: engine),
            lastSet: walled ? "no last set" : TessModelCapture.lastSet(context, engine: engine)
        )
    }

    /// Whether the exercise in focus has a name that must not leave the phone.
    static func exerciseIsWalled(_ context: TessContext, engine: ActionEngine, lastWeightKg: Double?) -> Bool {
        guard let entry = context.entry.flatMap({ engine.store.object(id: $0) }),
              let exercise = engine.store.linkedClass("exercise", of: entry) else { return false }
        return HomeDonePack.isWalled(exercise.name, lastWeightKg: lastWeightKg)
    }

    // MARK: The request

    struct Usage {
        var input = 0
        var output = 0
        var cacheRead = 0
        var cacheWrite = 0

        mutating func add(_ other: Usage) {
            input += other.input
            output += other.output
            cacheRead += other.cacheRead
            cacheWrite += other.cacheWrite
        }

        @MainActor var cost: Int64 {
            TessUsageLedger.cost(model: ClaudeTessModel.model, input: input, output: output, cacheRead: cacheRead,
                                 cacheWrite: cacheWrite)
        }
    }

    struct ToolCall {
        let id: String
        let name: String
        let input: Data
    }

    struct Response {
        let content: [[String: Any]]
        let text: String
        let toolCalls: [ToolCall]
        let stopReason: String?
        let usage: Usage
        let requestID: String?
    }

    /// A call that ended without an answer, with its Tess line.
    struct Failure: Error {
        let outcome: String
        let line: String
        /// Tokens billed before it failed (a 200 with no content).
        var used = Usage()

        static let offline = Failure(outcome: "offline", line: "No connection, so Claude didn't see that.")
        static let timeout = Failure(outcome: "timeout", line: "Claude didn't answer in time.")
        static let busy = Failure(outcome: "busy", line: "Claude is busy right now.")
        static let badKey = Failure(
            outcome: "badKey",
            line: "Claude didn't take the key. Check it in Settings: Claude."
        )
        static let other = Failure(outcome: "other", line: "Didn't catch that.")
    }

    func send(_ messages: [[String: Any]], system: String, key: String) async throws -> Response {
        var http = URLRequest(url: ClaudeKeyCheck.base, timeoutInterval: timeout)
        http.httpMethod = "POST"
        http.setValue(key, forHTTPHeaderField: "x-api-key")
        http.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        http.setValue("application/json", forHTTPHeaderField: "content-type")
        // Anything that isn't a clean answer becomes a Failure here, so the caller always writes its row (QA R1).
        guard let definitions = try? TessTools.definitionsJSON(),
              let tools = try? JSONSerialization.jsonObject(with: definitions),
              let body = try? JSONSerialization.data(withJSONObject: [
                  "model": Self.model, "max_tokens": Self.maxTokens, "system": system, "tools": tools,
                  "tool_choice": ["type": "auto"], "messages": messages,
              ] as [String: Any]) else { throw Failure.other }
        http.httpBody = body
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: http, delegate: NoRedirects.shared)
        } catch let error as URLError {
            throw error.code == .timedOut ? Failure.timeout : Failure.offline
        } catch {
            throw Failure.other // cancelled
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200: break
        case 401, 403: throw Failure.badKey
        case 429, 500 ... 599: throw status == 504 ? Failure.timeout : Failure.busy
        default: throw Failure.other
        }
        guard let body = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { throw Failure.other }
        let used = body["usage"] as? [String: Any] ?? [:]
        let usage = Usage(input: used["input_tokens"] as? Int ?? 0, output: used["output_tokens"] as? Int ?? 0,
                          cacheRead: used["cache_read_input_tokens"] as? Int ?? 0,
                          cacheWrite: used["cache_creation_input_tokens"] as? Int ?? 0)
        // A billed 200 with no content still counts toward the cap.
        guard let content = body["content"] as? [[String: Any]] else {
            throw Failure(outcome: "other", line: Failure.other.line, used: usage)
        }
        let text = content.compactMap { $0["type"] as? String == "text" ? $0["text"] as? String : nil }
            .joined(separator: " ")
        let calls = content.filter { $0["type"] as? String == "tool_use" }.compactMap { block -> ToolCall? in
            guard let id = block["id"] as? String, let name = block["name"] as? String,
                  let input = try? JSONSerialization.data(withJSONObject: block["input"] ?? [String: Any]())
            else { return nil }
            return ToolCall(id: id, name: name, input: input)
        }
        return Response(content: content, text: text, toolCalls: calls,
                        stopReason: body["stop_reason"] as? String, usage: usage,
                        requestID: (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "request-id"))
    }
}

/// Device-only switches for misses going to Claude, in UserDefaults (never in a backup): the "Not today" pause
/// Builder B sets from Settings: Claude, and whether the one-time "Sent … to Claude" line has shown.
@MainActor
public final class ClaudeMissFlags {
    let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    static let pausedKey = "tess.claudePausedUntil"
    static let noticeKey = "tess.claudeMissNoticeShown"

    /// "Not today": no misses go to Claude until his next day starts (04:00).
    public func pauseUntilTomorrow(now: Date = .now, calendar: Calendar = .current) {
        defaults.set(TesseraDay(calendar: calendar).end(of: now).timeIntervalSince1970, forKey: Self.pausedKey)
    }

    public func resume() {
        defaults.removeObject(forKey: Self.pausedKey)
    }

    /// When the pause ends, if one is on.
    public func pausedUntil(now: Date = .now) -> Date? {
        guard defaults.object(forKey: Self.pausedKey) != nil else { return nil }
        let until = Date(timeIntervalSince1970: defaults.double(forKey: Self.pausedKey))
        return until > now ? until : nil
    }

    public func isPaused(now: Date = .now) -> Bool {
        pausedUntil(now: now) != nil
    }

    public var noticeShown: Bool {
        get { defaults.bool(forKey: Self.noticeKey) }
        set { defaults.set(newValue, forKey: Self.noticeKey) }
    }
}
