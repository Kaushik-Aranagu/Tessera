import Foundation
#if canImport(Security)
    import Security
#endif
import TesseraCore

// The Claude key: kept in the Keychain only, checked with one free call, and counted against the $50 month
// (docs/research/claude-key-test.md). The key is read once per call into a local and put only in that request's
// Authorization header. It never reaches UserDefaults, the op log, objects, backups, exports, logs or errors.

// MARK: - Key store

/// Where the key lives. The app uses the Keychain; tests use the in-memory one.
public protocol TessKeychain: Sendable {
    func read() -> String?
    func save(_ key: String) -> Bool
    func delete()
}

#if canImport(Security)
    /// The real store: a generic password, this device only, unlocked only, never synced.
    public struct SystemKeychain: TessKeychain {
        public static let service = "com.kaushikaranagu.tessera.anthropic"
        public static let account = "api-key"

        public init() {}

        private var query: [String: Any] {
            [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: Self.service,
             kSecAttrAccount as String: Self.account, kSecAttrSynchronizable as String: false]
        }

        public func read() -> String? {
            var lookup = query
            lookup[kSecReturnData as String] = true
            lookup[kSecMatchLimit as String] = kSecMatchLimitOne
            var item: CFTypeRef?
            guard SecItemCopyMatching(lookup as CFDictionary, &item) == errSecSuccess, let data = item as? Data else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }

        public func save(_ key: String) -> Bool {
            delete()
            var item = query
            item[kSecValueData as String] = Data(key.utf8)
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
        }

        public func delete() {
            SecItemDelete(query as CFDictionary)
        }
    }
#endif

/// For tests and previews.
public final class InMemoryKeychain: TessKeychain, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: String?

    public init(_ key: String? = nil) {
        stored = key
    }

    public func read() -> String? {
        lock.withLock { stored }
    }

    public func save(_ key: String) -> Bool {
        lock.withLock { stored = key }
        return true
    }

    public func delete() {
        lock.withLock { stored = nil }
    }
}

// MARK: - Ledger

/// The $50 month, in nano-dollars (one Haiku input token is 100 n$). The month turns at 04:00 on the 1st in the
/// phone's calendar, his house day (Product 8:24 PM PT Oct 17), not midnight and not Anthropic's UTC.
@MainActor
public struct TessUsageLedger {
    /// The month's cap: $50 (Kaushik, decisions.md Oct 16). Settings' spend line and the paused copy read this.
    public static let capNano: Int64 = 50_000_000_000
    /// The cap in whole dollars, for the words ("of 50 dollars this month").
    public static let capDollars = Int(capNano / 1_000_000_000)

    /// Per-token prices in nano-dollars: (input, output, cache read, cache write).
    public static let prices: [String: (input: Int64, output: Int64, cacheRead: Int64, cacheWrite: Int64)] = [
        "claude-haiku-5-5": (100, 500, 10, 125),
        "claude-sonnet-5-5": (2000, 10000, 200, 2500),
    ]

    public let store: ObjectStore
    public let classes: [SystemCatalog.Key: ClassDef]

    public init(store: ObjectStore, classes: [SystemCatalog.Key: ClassDef]) {
        self.store = store
        self.classes = classes
    }

    public func calls() -> [ObjectRecord] {
        classes[.tessCall].map { store.objects(of: $0) } ?? []
    }

    /// The month a moment belongs to, with 04:00 edges: 3:59 AM on the 1st is still last month, 4:00 AM is the new one.
    /// The cap, the spend line and every "paused until" date read this one rule.
    public nonisolated static func monthInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        TesseraDay(calendar: calendar).month(containing: date)
    }

    /// Spent this month, in nano-dollars.
    public func monthTotal(now: Date = .now, calendar: Calendar = .current) -> Int64 {
        let month = Self.monthInterval(containing: now, calendar: calendar)
        let rows = calls().filter { $0.createdAt >= month.start && $0.createdAt < month.end }
            .reduce(0) { $0 + Int64(store.number("costNano", of: $1) ?? 0) }
        // The file beside the store survives what the rows do not (a restore, a reset): the higher total wins.
        let kept = TessSpendFile(store: store)?.total(month: TessSpendFile.monthKey(now, calendar: calendar)) ?? 0
        return max(rows, kept)
    }

    func canSpend(_ estimateNano: Int64, now: Date = .now, calendar: Calendar = .current) -> Bool {
        monthTotal(now: now, calendar: calendar) + pendingNano + estimateNano <= Self.capNano
    }

    /// Money promised to calls still in flight (a call's row is only written after its response), per store: every
    /// ledger on the app's one store shares it, and a test's own store never sees another test's calls in flight.
    private static var pending: [ObjectIdentifier: Int64] = [:]

    var pendingNano: Int64 {
        get { Self.pending[ObjectIdentifier(store.context)] ?? 0 }
        nonmutating set { Self.pending[ObjectIdentifier(store.context)] = newValue }
    }

    /// A hold on part of the month, taken before a call and released after it.
    public struct Reservation: Sendable {
        let nano: Int64
    }

    /// Checks and holds `estimateNano` in one step on the main actor, so two concurrent calls can't both fit under
    /// the cap. Nil when it doesn't fit. Estimate from `max_tokens` (Haiku 5.5 may think).
    public func reserve(_ estimateNano: Int64, now: Date = .now, calendar: Calendar = .current) -> Reservation? {
        // A model with no price row estimates 0: refused, so it can never spend outside the cap (QA A6).
        guard estimateNano > 0, canSpend(estimateNano, now: now, calendar: calendar) else { return nil }
        pendingNano += estimateNano
        return Reservation(nano: estimateNano)
    }

    /// Releases a hold once the call's own row (its real cost) is written.
    public func settle(_ reservation: Reservation) {
        pendingNano = max(0, pendingNano - reservation.nano)
    }

    /// Haiku 5.5 costs more once a prompt passes 100K tokens ($0.50 in and $2.50 out per million, from $0.10 and
    /// $0.50). Cache prices scale with it (a read at a tenth of the input price, a 5-minute write at 1.25x, a 1-hour
    /// write at 2x).
    public static let stepTokens = 100_000
    static let steppedPrices: [String: (input: Int64, output: Int64, cacheRead: Int64, cacheWrite: Int64)] = [
        "claude-haiku-5-5": (500, 2500, 50, 625),
    ]

    /// $10 per 1,000 searches. A web fetch costs only its tokens.
    public static let webSearchNano: Int64 = 10_000_000

    /// The price row for a prompt of this many tokens.
    static func price(model: String, promptTokens: Int) -> (input: Int64, output: Int64, cacheRead: Int64,
                                                            cacheWrite: Int64)?
    {
        if promptTokens > stepTokens, let stepped = steppedPrices[model] {
            return stepped
        }
        return prices[model]
    }

    /// Before a call: bytes / 4 + 10 tokens in, `maxTokens` out (at the stepped price past 100K tokens).
    public static func estimate(text: String, maxTokens: Int, model: String) -> Int64 {
        let tokens = (text.utf8.count + 3) / 4 + 10
        guard let price = price(model: model, promptTokens: tokens) else { return 0 }
        return Int64(tokens) * price.input + Int64(maxTokens) * price.output
    }

    /// `cacheWrite` is all tokens written to the cache; `cacheWrite1h` is the part of them written with the 1-hour
    /// lifetime, which costs 2x the input price instead of 1.25x.
    public static func cost(model: String, input: Int, output: Int, cacheRead: Int = 0, cacheWrite: Int = 0,
                            cacheWrite1h: Int = 0, webSearches: Int = 0) -> Int64
    {
        guard let price = price(model: model, promptTokens: input + cacheRead + cacheWrite) else { return 0 }
        let longWrites = min(max(cacheWrite1h, 0), cacheWrite)
        return Int64(input) * price.input + Int64(output) * price.output + Int64(cacheRead) * price.cacheRead
            + Int64(cacheWrite - longWrites) * price.cacheWrite + Int64(longWrites) * 2 * price.input
            + Int64(webSearches) * webSearchNano
    }

    /// One row per call, written straight to the store (no op: it isn't something he did, and undo shouldn't see it).
    /// A request that never left (offline) writes no row at all. `sent` is what went out, as sent: it also writes the
    /// request's Tess Sent row (G653), "Held back on this phone" for a payload too large to keep.
    @discardableResult
    public func record(use: TessUse, model: String, input: Int, output: Int, costNano: Int64, latency: TimeInterval,
                       outcome: String, requestID: String?, at date: Date = .now, sent: String? = nil)
        -> ObjectRecord?
    {
        guard outcome != "offline" else { return nil }
        if let sent {
            TessSentLog(store: store, classes: classes).record(words: sent, use: use, requestID: requestID, at: date)
        }
        guard let classDef = classes[.tessCall], let call = try? store.create(classDef, title: "\(use.rawValue) call")
        else { return nil }
        TessSpendFile(store: store)?.add(costNano, month: TessSpendFile.monthKey(date, calendar: Calendar.current))
        call.createdAt = date
        try? store.set("use", to: .text(use.rawValue), on: call)
        try? store.set("model", to: .text(model), on: call)
        try? store.set("inputTokens", to: .number(Double(input)), on: call)
        try? store.set("outputTokens", to: .number(Double(output)), on: call)
        try? store.set("costNano", to: .number(Double(costNano)), on: call)
        try? store.set("latencyMs", to: .number((latency * 1000).rounded()), on: call)
        try? store.set("outcome", to: .text(outcome), on: call)
        try? store.set("requestID", to: requestID.map(FieldValue.text), on: call)
        return call
    }
}

// MARK: - The key Test

/// Saves a pasted key, then proves it with one free `count_tokens` call (a 1-token message only if that endpoint has
/// moved). Every outcome has one Tess line.
@MainActor
public struct ClaudeKeyCheck {
    public enum Outcome: String, Sendable {
        case works, badKey, notAllowed, offline, timeout, capReached, busy, accountPaused, notAKey, notSaved, other
    }

    public struct Result: Sendable {
        public let outcome: Outcome
        public let line: String
        /// Whether a key was kept. No part of the key travels in a result.
        public let saved: Bool
    }

    public static let model = "claude-haiku-5-5"
    static let base = URL(string: "https://api.anthropic.com/v1/messages")!

    public let keys: any TessKeychain
    public let ledger: TessUsageLedger
    public let session: URLSession
    public var now: () -> Date = { .now }
    public var calendar: Calendar = .current

    public init(keys: any TessKeychain, ledger: TessUsageLedger,
                session: URLSession = URLSession(configuration: .ephemeral))
    {
        self.keys = keys
        self.ledger = ledger
        self.session = session
    }

    public func test(pasted: String) async -> Result {
        // A key pasted from a wrapped line can carry spaces or breaks inside it: a key never has any.
        let key = String(pasted.filter { !$0.isWhitespace })
        guard key.hasPrefix("sk-ant-"), key.count > 12 else {
            return Result(outcome: .notAKey, line: "That doesn't look like a Claude key. Paste it again?", saved: false)
        }
        // Only say "saved" when it was.
        guard keys.save(key) else {
            return Result(outcome: .notSaved, line: "I couldn't save that key. Try again?", saved: false)
        }
        let started = Date.now
        var outcome: Outcome
        var requestID: String?
        var cost: Int64 = 0
        var used = (input: 0, output: 0)
        do {
            var (status, body, id) = try await send(key: key, path: "/count_tokens", body: [
                "model": Self.model, "messages": [["role": "user", "content": "Hi"]],
            ])
            requestID = id
            // The endpoint moved (404/405, or a 200 that doesn't read): one 1-token message, if the cap allows.
            let readable = (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["input_tokens"] != nil
            if status == 404 || status == 405 || status == 200 && !readable {
                let estimate = TessUsageLedger.estimate(text: "Hi", maxTokens: 1, model: Self.model)
                // Reserve before the await, so two calls can't both pass the cap (QA K11).
                guard let reservation = ledger.reserve(estimate, now: now(), calendar: calendar) else {
                    return finish(.capReached, started: started, requestID: id, cost: 0, used: used)
                }
                defer { ledger.settle(reservation) }
                (status, body, id) = try await send(key: key, path: "", body: [
                    "model": Self.model, "max_tokens": 1, "thinking": ["type": "disabled"],
                    "messages": [["role": "user", "content": "Hi"]],
                ])
                requestID = id
                if status == 200,
                   let usage = (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["usage"]
                   as? [String: Any]
                {
                    used = (usage["input_tokens"] as? Int ?? 0, usage["output_tokens"] as? Int ?? 0)
                    cost = TessUsageLedger.cost(model: Self.model, input: used.input, output: used.output)
                }
            }
            outcome = Self.outcome(status: status, body: body)
        } catch let error as URLError {
            switch error.code {
            case .timedOut: outcome = .timeout
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost,
                 .cannotConnectToHost: outcome = .offline
            default: outcome = .other
            }
        } catch {
            outcome = .other
        }
        // A 401 keeps the key: a header or network mistake on our side must never destroy a good key. He removes
        // it himself, or pastes again.
        if outcome == .works,
           ledger.monthTotal(now: now(), calendar: calendar) >= TessUsageLedger.capNano
        {
            outcome = .capReached
        }
        return finish(outcome, started: started, requestID: requestID, cost: cost, used: used)
    }

    private func finish(_ outcome: Outcome, started: Date, requestID: String?, cost: Int64,
                        used: (input: Int, output: Int)) -> Result
    {
        ledger.record(use: .keyCheck, model: Self.model, input: used.input, output: used.output, costNano: cost,
                      latency: Date.now.timeIntervalSince(started), outcome: outcome.rawValue, requestID: requestID,
                      at: now(), sent: "Key check")
        return Result(outcome: outcome, line: Self.line(outcome, now: now(), calendar: calendar),
                      saved: true)
    }

    /// One request; the key goes only into this request's header.
    private func send(key: String, path: String, body: [String: Any]) async throws -> (Int, Data, String?) {
        // An empty path is the messages endpoint itself (appending "" would add a trailing slash; QA K12).
        var request = URLRequest(url: path.isEmpty ? Self.base : Self.base.appendingPathComponent(path),
                                 timeoutInterval: 10)
        request.httpMethod = "POST"
        // x-api-key: checked against the live API (a fake key gets "invalid x-api-key" either way; no header gets
        // "x-api-key header is required").
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request, delegate: NoRedirects.shared)
        let http = response as? HTTPURLResponse
        return (http?.statusCode ?? 0, data, http?.value(forHTTPHeaderField: "request-id"))
    }

    /// The status (and the error JSON's `type` and `error_code`, never its message, except the documented prefix).
    static func outcome(status: Int, body: Data) -> Outcome {
        let error = (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["error"] as? [String: Any]
        let code = (error?["details"] as? [String: Any])?["error_code"] as? String
        let message = error?["message"] as? String ?? ""
        switch status {
        case 200: return .works
        case 401: return .badKey
        case 403: return .notAllowed
        case 402: return .accountPaused
        case 400 where message.hasPrefix("You have reached your specified"): return .accountPaused
        case 429 where code == "enforced_spend_limit_reached": return .accountPaused
        case 429, 500, 529: return .busy
        case 504: return .timeout
        default: return .other
        }
    }

    /// Tess's line for each outcome (tess-voice.md: one line, under 12 words, no "!").
    static func line(_ outcome: Outcome, now: Date, calendar: Calendar) -> String {
        switch outcome {
        case .works: return "Key saved."
        case .badKey: return "That key didn't work. Paste it again?"
        case .notAllowed: return "That key can't use Claude yet. Check it in the Console?"
        // No promise of a retry: nothing retries yet. The key is kept; Test again checks it.
        case .offline: return "No connection. I kept the key; test it again later."
        case .timeout: return "Claude didn't answer in time."
        case .busy: return "Claude is busy right now. I kept the key."
        case .accountPaused: return "Key saved. Your Anthropic account is paused for now."
        case .notAKey: return "That doesn't look like a Claude key. Paste it again?"
        case .notSaved: return "I couldn't save that key. Try again?"
        case .other: return "I couldn't check that key. Try again?"
        case .capReached:
            let next = TessUsageLedger.monthInterval(containing: now, calendar: calendar).end
            return "Key saved. Claude paused until \(next.formatted(.dateTime.month(.abbreviated).day()))."
        }
    }
}
