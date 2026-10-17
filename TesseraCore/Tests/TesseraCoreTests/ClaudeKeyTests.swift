import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// A canned reply for every request, and the last request seen.
final class StubProtocol: URLProtocol, @unchecked Sendable {
    /// Where every request is redirected, when set.
    nonisolated(unsafe) static var redirect: String?
    nonisolated(unsafe) static var reply: (status: Int, body: String)? = (200, #"{"input_tokens": 8}"#)
    nonisolated(unsafe) static var failure: URLError.Code?
    nonisolated(unsafe) static var requests: [URLRequest] = []
    /// Replies used in order before `reply` (a tool round, then the answer).
    nonisolated(unsafe) static var queue: [(status: Int, body: String)] = []
    /// Each request's JSON body (URLProtocol sees it as a stream).
    nonisolated(unsafe) static var bodies: [Data] = []

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requests.append(request)
        if let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                data.append(buffer, count: count)
            }
            stream.close()
            Self.bodies.append(data)
        } else {
            Self.bodies.append(request.httpBody ?? Data())
        }
        if let failure = Self.failure {
            client?.urlProtocol(self, didFailWithError: URLError(failure))
            return
        }
        // A 301 to another host (Product 9:53 PM PT): the client must never take it.
        if let target = Self.redirect, request.url?.host() != URL(string: target)?.host(),
           let url = URL(string: target)
        {
            let hop = HTTPURLResponse(url: request.url!, statusCode: 301, httpVersion: nil,
                                      headerFields: ["Location": target])!
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: url), redirectResponse: hop)
            client?.urlProtocol(self, didReceive: hop, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let (status, body) = Self.queue.isEmpty ? Self.reply ?? (200, "{}") : Self.queue.removeFirst()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                       headerFields: ["request-id": "req_test"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite(.serialized) @MainActor
struct ClaudeKeyTests {
    static let key = "sk-ant-TEST-" + UUID().uuidString

    let dir: URL
    let store: ObjectStore
    let classes: [SystemCatalog.Key: ClassDef]
    let keys = InMemoryKeychain()

    init() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        store = try ObjectStore(context: TesseraContext(url: dir.appendingPathComponent("tessera.sqlite")))
        classes = try store.prepareCatalog()
        StubProtocol.reply = (200, #"{"input_tokens": 8}"#)
        StubProtocol.failure = nil
        StubProtocol.requests = []
        StubProtocol.redirect = nil
    }

    var ledger: TessUsageLedger {
        TessUsageLedger(store: store, classes: classes)
    }

    func check() -> ClaudeKeyCheck {
        ClaudeKeyCheck(keys: keys, ledger: ledger, session: StubProtocol.session())
    }

    @Test func aRedirectIsNeverFollowedWithTheKey() async {
        // Product 9:53 PM PT: a 301 from the API host is refused, so the key never reaches the other host.
        StubProtocol.redirect = "https://" + "evil" + ".example/v1/messages/count_tokens"
        let result = await check().test(pasted: Self.key)
        #expect(result.outcome != .works)
        #expect(!StubProtocol.requests.contains { $0.url?.host()?.contains("evil") == true })
    }

    @Test func noResultOrLineCarriesAnyPartOfTheKey() async {
        // Built at run time from pieces; no 4-character run of it may show in any field or line.
        let secret = "sk-" + "ant-" + "Qz9w" + "Kv3m" + "Xt6r" + "Hb2n"
        let runs = (0 ... secret.count - 4).map { index -> String in
            let start = secret.index(secret.startIndex, offsetBy: index)
            return String(secret[start ..< secret.index(start, offsetBy: 4)])
        }.filter { $0 != "sk-a" && $0 != "k-an" && $0 != "-ant" && $0 != "ant-" }
        func clean(_ result: ClaudeKeyCheck.Result) {
            let text = "\(result)"
            for run in runs {
                #expect(!text.contains(run), "\(run) in \(text)")
            }
        }
        for row in [(200, #"{"input_tokens": 8}"#), (401, "{}"), (403, "{}"), (429, "{}"), (500, "{}")] {
            StubProtocol.reply = (row.0, row.1)
            await clean(check().test(pasted: secret))
        }
        StubProtocol.failure = .notConnectedToInternet
        await clean(check().test(pasted: secret))
        StubProtocol.failure = nil
        await clean(check().test(pasted: "sk-ant-"))
        let outcomes: [ClaudeKeyCheck.Outcome] = [
            .works, .badKey, .notAllowed, .offline, .timeout, .capReached, .busy, .accountPaused,
            .notAKey, .notSaved, .other,
        ]
        for outcome in outcomes {
            let line = ClaudeKeyCheck.line(outcome, now: .now, calendar: .current)
            for run in runs {
                #expect(!line.contains(run))
            }
        }
    }

    @Test func aWorkingKeyIsSavedCheckedForFreeAndNeverLeaves() async throws {
        let result = await check().test(pasted: "  \(Self.key)\n")
        #expect(result.outcome == .works && result.line == "Key saved.")
        #expect(keys.read() == Self.key)
        let request = try #require(StubProtocol.requests.last)
        #expect(request.url?.path == "/v1/messages/count_tokens")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == Self.key) // the one place
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        // Counted, at $0.
        #expect(ledger.calls().count == 1 && ledger.monthTotal() == 0)

        // Pasted into the Ask bar: refused before any route, nothing written.
        let engine = ActionEngine(store: store, classes: classes)
        let pasted = await TessCaptureEngine(engine: engine).capture(Self.key, context: TessContext())
        #expect(pasted.records.isEmpty && pasted.line == TessRouter.keyLine)

        // Nowhere on disk or in defaults.
        let backup = dir.appendingPathComponent("leak.tessera")
        try TesseraBackup.write(from: store.context, to: backup)
        let haystacks: [(String, Data)] = try [
            ("backup", Data(contentsOf: backup)),
            ("export", TesseraExport(context: store.context).encoded()),
            ("op log", Data(engine.history(limit: 1000).map { "\($0.summary)\($0.ops)" }.joined().utf8)),
            ("defaults", Data("\(UserDefaults.standard.dictionaryRepresentation())".utf8)),
            ("misses", (try? Data(contentsOf: dir.appendingPathComponent("capture-misses.jsonl"))) ?? Data()),
        ]
        for (name, bytes) in haystacks {
            #expect(bytes.range(of: Data(Self.key.utf8)) == nil, "key found in \(name)")
            #expect(bytes.range(of: Data("sk-ant-".utf8)) == nil, "key prefix found in \(name)")
        }
    }

    struct StatusRow: Sendable, CustomTestStringConvertible {
        let status: Int
        let body: String
        let outcome: ClaudeKeyCheck.Outcome
        var testDescription: String {
            "\(status) \(outcome)"
        }
    }

    nonisolated static let statuses: [StatusRow] = [
        .init(status: 401, body: #"{"error":{"type":"authentication_error"}}"#, outcome: .badKey),
        .init(status: 403, body: #"{"error":{"type":"permission_error"}}"#, outcome: .notAllowed),
        .init(status: 529, body: #"{"error":{"type":"overloaded_error"}}"#, outcome: .busy),
        .init(status: 500, body: #"{"error":{"type":"api_error"}}"#, outcome: .busy),
        .init(status: 429, body: #"{"error":{"type":"rate_limit_error"}}"#, outcome: .busy),
        .init(
            status: 429,
            body: #"{"error":{"type":"rate_limit_error","details":{"error_code":"enforced_spend_limit_reached"}}}"#,
            outcome: .accountPaused
        ),
        .init(status: 402, body: #"{"error":{"type":"billing_error"}}"#, outcome: .accountPaused),
        .init(
            status: 400,
            body: #"{"error":{"type":"invalid_request_error","message":"You have reached your specified API usage limits"}}"#,
            outcome: .accountPaused
        ),
        .init(status: 504, body: #"{"error":{"type":"timeout_error"}}"#, outcome: .timeout),
        .init(status: 418, body: "{}", outcome: .other),
    ]

    @Test(arguments: statuses) func statusMapsToOutcome(_ row: StatusRow) async {
        StubProtocol.reply = (row.status, row.body)
        let result = await check().test(pasted: Self.key)
        #expect(result.outcome == row.outcome)
        #expect(TessVoice.violations(in: result.line).isEmpty)
        // Every outcome keeps the key, a 401 included: a mistake on our side must never destroy a good key.
        #expect(keys.read() == Self.key)
        #expect(ledger.calls().count == 1)
    }

    @Test(arguments: [URLError.Code.notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .timedOut])
    func networkFailuresKeepTheKey(_ code: URLError.Code) async {
        StubProtocol.failure = code
        let result = await check().test(pasted: Self.key)
        #expect(result.outcome == (code == .timedOut ? .timeout : .offline))
        #expect(keys.read() == Self.key && ledger.monthTotal() == 0)
    }

    @Test func aWrappedPasteIsJoinedAndAFailedSaveSaysSo() async {
        let result = await check().test(pasted: "sk-ant-TEST-abc\n def-1234")
        #expect(result.outcome == .works && keys.read() == "sk-ant-TEST-abcdef-1234")
        let broken = ClaudeKeyCheck(keys: RefusingKeychain(), ledger: ledger, session: StubProtocol.session())
        let refused = await broken.test(pasted: Self.key)
        #expect(refused.outcome == .notSaved && refused.line == "I couldn't save that key. Try again?")
        #expect(StubProtocol.requests.count == 1) // nothing sent for the refused save
    }

    @Test func theGuardIgnoresCase() async {
        #expect(looksLikeClaudeKey("Sk-Ant-abc") && looksLikeClaudeKey("my key is SK-ANT-123"))
        #expect(!looksLikeClaudeKey("skant") && !looksLikeClaudeKey("sk-and-x"))
        let engine = ActionEngine(store: store, classes: classes)
        let pasted = await TessCaptureEngine(engine: engine).capture("Sk-ant-Mixed-Case-Key", context: TessContext())
        #expect(pasted.records.isEmpty && pasted.line == TessRouter.keyLine)
    }

    @Test func twoCallsAtOnceCannotBothPassTheCap() {
        let remaining = TessUsageLedger.capNano - ledger.monthTotal()
        let share = remaining / 10 * 6
        let first = ledger.reserve(share)
        let second = ledger.reserve(share)
        #expect(first != nil && second == nil)
        if let first {
            ledger.settle(first)
        }
        #expect(ledger.reserve(share).map { ledger.settle($0) } != nil)
    }

    @Test func notAKeyIsNeverSent() async {
        let result = await check().test(pasted: "hello there")
        #expect(result.outcome == .notAKey && StubProtocol.requests.isEmpty && keys.read() == nil)
    }

    @Test func aMovedEndpointFallsBackToOneTokenAndIsPriced() async {
        StubProtocol.reply = (404, "{}")
        let result = await check().test(pasted: Self.key)
        // Both requests got the same canned 404 here, so the outcome is "other" and nothing was billed.
        #expect(result.outcome == .other)
        // The fallback posts to the messages endpoint itself, no trailing slash (QA K12).
        #expect(StubProtocol.requests.map { $0.url?.absoluteString } == [
            "https://api.anthropic.com/v1/messages/count_tokens", "https://api.anthropic.com/v1/messages",
        ])
        #expect(TessUsageLedger.cost(model: ClaudeKeyCheck.model, input: 8, output: 1) == 1300)
    }

    @Test func atTheCapAWorkingKeySaysPaused() async throws {
        ledger.record(use: .capture, model: ClaudeKeyCheck.model, input: 0, output: 0,
                      costNano: TessUsageLedger.capNano, latency: 0, outcome: "works", requestID: nil)
        var checker = check()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        checker.calendar = calendar
        checker.now = { calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 9))! }
        ledger.calls().forEach { $0.createdAt = checker.now() }
        let result = await checker.test(pasted: Self.key)
        #expect(result.outcome == .capReached && result.line == "Key saved. Claude paused until Nov 1.")
        #expect(keys.read() == Self.key)
    }

    @Test func theMonthStartsAtMidnightOnTheFirst() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let lastMonth = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 30,
            hour: 23,
            minute: 59
        )))
        let thisMonth = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        ledger.record(use: .capture, model: ClaudeKeyCheck.model, input: 0, output: 0, costNano: 500,
                      latency: 0, outcome: "works", requestID: nil, at: lastMonth)
        ledger.record(use: .capture, model: ClaudeKeyCheck.model, input: 0, output: 0, costNano: 700,
                      latency: 0, outcome: "works", requestID: nil, at: thisMonth)
        #expect(ledger.monthTotal(now: thisMonth.addingTimeInterval(3600), calendar: calendar) == 700)
        #expect(ledger.canSpend(TessUsageLedger.capNano - 700, now: thisMonth, calendar: calendar))
        #expect(!ledger.canSpend(TessUsageLedger.capNano - 699, now: thisMonth, calendar: calendar))
    }
}

/// A Keychain that refuses every save.
struct RefusingKeychain: TessKeychain {
    func read() -> String? {
        nil
    }

    func save(_: String) -> Bool {
        false
    }

    func delete() {}
}
