import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// StubProtocol for ClaudeRouteTests: its own state, so the two suites can run side by side.
final class RouteStub: URLProtocol, @unchecked Sendable {
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
        configuration.protocolClasses = [RouteStub.self]
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

/// The Claude step of capture (tess-model-layer.md T3; Product 8:28 PM PT Oct 15): misses go to Claude when the key
/// is saved, the switch is on, there's no "Not today" pause and money is left; tool calls land as pending ghosts.
@Suite(.serialized) @MainActor
struct ClaudeRouteTests {
    static let key = "sk-ant-TEST-" + UUID().uuidString
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let defaults: UserDefaults
    let flags: ClaudeMissFlags
    var ledger: TessUsageLedger {
        TessUsageLedger(store: store, classes: classes)
    }

    /// Thursday 15 October 2026, 18:10 in Los Angeles.
    let context = TessContext(now: TesseraDayTests.at(10, 15, 18, 10), calendar: TesseraDayTests.calendar)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        defaults = try #require(UserDefaults(suiteName: "claude-route-\(UUID().uuidString)"))
        flags = ClaudeMissFlags(defaults: defaults)
        RouteStub.reply = (200, Self.answer("Logged."))
        RouteStub.queue = []
        RouteStub.failure = nil
        RouteStub.requests = []
        RouteStub.redirect = nil
        RouteStub.bodies = []
    }

    static func answer(_ text: String) -> String {
        #"{"content":[{"type":"text","text":"\#(text)"}],"stop_reason":"end_turn","#
            + #""usage":{"input_tokens":900,"output_tokens":20}}"#
    }

    static let logBench = #"{"content":[{"type":"tool_use","id":"toolu_1","name":"logSet","input":"#
        + #"{"exercise":"Bench Press","weight":80,"reps":8,"sets":1,"unit":"kg"}}],"stop_reason":"tool_use","#
        + #""usage":{"input_tokens":1200,"output_tokens":60}}"#

    func tess(sends: Bool = true, key: String? = Self.key) -> TessCaptureEngine {
        let capture = TessCaptureEngine(engine: engine)
        var claude = ClaudeTessModel(keys: InMemoryKeychain(key), ledger: ledger, flags: flags,
                                     session: RouteStub.session(), sendsMisses: { sends })
        claude.now = { TesseraDayTests.at(10, 15, 18, 10) }
        claude.calendar = TesseraDayTests.calendar
        capture.claude = claude
        return capture
    }

    /// A question: the grammar never writes it, and there's no on-device model in tests.
    let miss = "could you log bench 80 for 8 from earlier?"

    @Test func aRedirectIsNeverFollowedFromTess() async {
        // Product 9:53 PM PT: Tess's call refuses a 301; nothing is sent to the other host and nothing is written.
        RouteStub.redirect = "https://" + "evil" + ".example/v1/messages"
        let capture = await tess().capture(miss, context: context)
        #expect(capture.source != .claude && capture.records.isEmpty)
        #expect(!RouteStub.requests.contains { $0.url?.host()?.contains("evil") == true })
    }

    @Test func aWalledMissIsNeverSpokenBack() async {
        // His "All but the key": a sum goes whole, but neither the one-time notice nor Claude's own line echo it
        // (QA on #860). Claude's reply here repeats the phrase; what is spoken is the records' receipt.
        let phrase = "could you log that I paid 40 for gas earlier?"
        #expect(PrivateFacts.isWalled(phrase, lastWeightKg: nil))
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Noted, paid 40 for gas."))]
        let capture = await tess().capture(phrase, context: context)
        #expect(capture.source == .claude && capture.records.count == 1, "\(capture.line)")
        #expect(capture.line == "Sent that to Claude. Turn this off in Settings: Claude.", "\(capture.line)")
        // The next miss, no notice: still not Claude's words.
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Noted, wifi code 4821 and paid 40 for gas."))]
        let second = await tess().capture(phrase, context: context)
        #expect(!second.line.contains("4821") && !second.line.contains("gas") && !second.line.contains("40"),
                "\(second.line)")
    }

    @Test func aLongPhraseIsRefusedBeforeItLeaves() async {
        let long = String(repeating: "could you log the bench ", count: 40)
        let capture = await tess().capture(long, context: context)
        #expect(
            capture.line == "That's too long to send. Say it shorter." && capture.records.isEmpty,
            "\(capture.line)"
        )
        #expect(RouteStub.requests.isEmpty)
    }

    @Test func theReceiptsHoldNoWordOfAWalledPhrase() async {
        // "What was sent" lists the ledger's rows (time, job, model, cost): none holds the phrase, masked or not.
        let phrase = "could you log that I paid 40 for gas earlier?"
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Noted."))]
        _ = await tess().capture(phrase, context: context)
        let calls = ledger.calls()
        #expect(!calls.isEmpty)
        for call in calls {
            for value in call.values.storage.values {
                if case let .text(text) = value {
                    #expect(!text.lowercased().contains("gas") && !text.contains("40"), "\(text)")
                }
            }
            #expect(!call.title.lowercased().contains("gas"))
        }
    }

    @Test func aMissGoesToClaudeAndLandsAsAPendingGhost() async throws {
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Bench 80 × 8 logged."))]
        let capture = await tess().capture(miss, context: context)
        #expect(capture.source == .claude && capture.records.count == 1)
        #expect(capture.records.first?.state == .pending)
        #expect(capture.records.first?.route == .claude && capture.records.first?.model == ClaudeTessModel.model)
        // The first miss ever sent says so, once.
        #expect(capture.line == "Sent \u{201C}\(miss)\u{201D} to Claude. Turn this off in Settings: Claude.")
        #expect(flags.noticeShown)
        // Two rounds: the tool result went back.
        #expect(RouteStub.requests.count == 2)
        #expect(RouteStub.requests.allSatisfy { $0.value(forHTTPHeaderField: "x-api-key") == Self.key })
        let second = try #require(String(data: RouteStub.bodies[1], encoding: .utf8))
        #expect(second.contains("tool_result") && second.contains("toolu_1"))
        #expect(!RouteStub.bodies.contains { $0.range(of: Data(Self.key.utf8)) != nil }) // header only
        // One ledger row, priced.
        #expect(ledger.calls().count == 1)
        #expect(ledger.monthTotal(now: context.now, calendar: TesseraDayTests.calendar)
            == TessUsageLedger.cost(model: ClaudeTessModel.model, input: 2100, output: 80))
    }

    @Test func afterTheNoticeClaudesOwnLineShowsIfItPassesTheVoiceChecks() async {
        flags.noticeShown = true
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Bench 80 × 8 logged."))]
        #expect(await tess().capture(miss, context: context).line == "Bench 80 × 8 logged.")
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Great job, logged it all for you!"))]
        let loud = await tess().capture(miss, context: context)
        #expect(loud.records.count == 1 && TessVoice.violations(in: loud.line).isEmpty)
    }

    @Test func switchedOffPausedOrKeylessNothingIsSent() async {
        #expect(await tess(sends: false).capture(miss, context: context).line.hasPrefix("Didn't catch that."))
        #expect(await tess(key: nil).capture(miss, context: context).records.isEmpty)
        flags.pauseUntilTomorrow(now: context.now, calendar: TesseraDayTests.calendar)
        #expect(await tess().capture(miss, context: context).records.isEmpty)
        #expect(RouteStub.requests.isEmpty)
        // "Not today" ends at his next 04:00.
        #expect(flags.pausedUntil(now: context.now) == TesseraDayTests.at(10, 16, 4))
        #expect(!flags.isPaused(now: TesseraDayTests.at(10, 16, 4, 1)))
        flags.resume()
        #expect(!flags.isPaused(now: context.now))
    }

    @Test func atTheCapNothingIsSentAndTessSaysUntilWhen() async {
        ledger.record(use: .capture, model: ClaudeTessModel.model, input: 0, output: 0,
                      costNano: TessUsageLedger.capNano, latency: 0, outcome: "works", requestID: nil,
                      at: context.now)
        let capture = await tess().capture(miss, context: context)
        #expect(capture.records.isEmpty && capture.line == "Claude paused until Nov 1.")
        #expect(RouteStub.requests.isEmpty)
    }

    @Test func offlineOrSlowSaysSoAndWritesNothing() async {
        RouteStub.failure = .notConnectedToInternet
        let offline = await tess().capture(miss, context: context)
        #expect(offline.records.isEmpty && offline.line == "No connection. Saved it for Claude.")
        RouteStub.failure = .timedOut
        #expect(await tess().capture(miss, context: context).line == "Claude didn't answer in time.")
        #expect(ledger.calls().count == 2)
    }

    @Test(arguments: [
        "could you log that I paid 40 for gas earlier?",
        "could you note that I weighed 82.4 kg this morning please?",
    ])
    func aWalledMissOfflineIsNeitherQueuedNorLoggedAndSaysSo(_ phrase: String) async {
        // Money, body and secret words: the ruled line, nothing in the inbox, nothing logged, the other lines
        // unchanged.
        #expect(PrivateFacts.isWalled(phrase, lastWeightKg: nil) || SecretWords.mentions(phrase), "\(phrase)")
        RouteStub.failure = .notConnectedToInternet
        let capture = await tess().capture(phrase, context: context)
        #expect(capture.records.isEmpty && capture.line == "Couldn't read that offline. Try again online.",
                "\(capture.line)")
        #expect(capture.isRefusal)
        #expect(TessInbox(store: store, classes: classes).waiting().isEmpty)
        // A plain miss offline still waits for Claude.
        let plain = await tess().capture(miss, context: context)
        #expect(plain.line == "No connection. Saved it for Claude.")
        #expect(TessInbox(store: store, classes: classes).waiting().count == 1)
    }

    @Test func aSecretMissOfflineSaysTheSameWhenItReachesTheRoute() async {
        // The grammar keeps a secret phrase on the phone, so it rarely gets here; the route itself still holds.
        var claude = ClaudeTessModel(keys: InMemoryKeychain(Self.key), ledger: ledger, flags: flags,
                                     session: RouteStub.session(), sendsMisses: { true })
        claude.now = { TesseraDayTests.at(10, 15, 18, 10) }
        claude.calendar = TesseraDayTests.calendar
        RouteStub.failure = .notConnectedToInternet
        let phrase = "could you hold the wifi password zebra99 for me later?"
        #expect(SecretWords.mentions(phrase))
        let result = await claude.run(TessRequest(text: phrase, context: context, use: .capture), engine: engine)
        guard case let .asked(capture) = result else { Issue.record("expected the offline line"); return }
        #expect(capture.line == "Couldn't read that offline. Try again online." && capture.isRefusal)
        #expect(TessInbox(store: store, classes: classes).waiting().isEmpty)
    }

    @Test func aToolThatFailsMidwayLeavesNoGhost() async throws {
        // Claude asks for an exercise that doesn't exist, then gives up.
        RouteStub.queue = [
            (200, Self.logBench.replacingOccurrences(of: "Bench Press", with: "Underwater Bench")),
            (200, Self.answer("Couldn't find that exercise.")),
        ]
        let capture = await tess().capture(miss, context: context)
        #expect(capture.records.isEmpty)
        let second = try #require(String(data: RouteStub.bodies[1], encoding: .utf8))
        #expect(second.contains("is_error"))
    }

    @Test func everyFailedCallWritesItsRowAndAnEmptyBilledReplyCounts() async {
        // QA R1 on #283: not JSON, and a 200 with no content but billed tokens.
        RouteStub.queue = [(200, "not json")]
        _ = await tess().capture(miss, context: context)
        RouteStub.queue = [(200, #"{"usage":{"input_tokens":900,"output_tokens":5}}"#)]
        _ = await tess().capture(miss, context: context)
        RouteStub.queue = [(200, "{}")]
        _ = await tess().capture(miss, context: context)
        #expect(ledger.calls().count == 3)
        #expect(ledger.monthTotal(now: context.now, calendar: TesseraDayTests.calendar)
            == TessUsageLedger.cost(model: ClaudeTessModel.model, input: 900, output: 5))
    }

    @Test func siriAndShortcutsNeverReachClaude() async {
        // QA R3 on #283: they commit at once, with no ghost and no UNDO.
        var shortcut = context
        shortcut.commitImmediately = true
        let capture = await tess().capture(miss, context: shortcut)
        #expect(capture.records.isEmpty && RouteStub.requests.isEmpty)
    }

    @Test func aCutOffOrRefusedReplyMakesNoGhost() async {
        // QA L1 on #283.
        for reason in ["max_tokens", "refusal"] {
            RouteStub.queue = [(200, Self.logBench.replacingOccurrences(of: "\"tool_use\",\"usage\"",
                                                                        with: "\"\(reason)\",\"usage\""))]
            let capture = await tess().capture(miss, context: context)
            #expect(capture.records.isEmpty && capture.line == "Didn't catch that.", "\(reason)")
        }
    }

    @Test func toolErrorsGoBackAsFixedLines() async throws {
        RouteStub.queue = [
            (200, Self.logBench.replacingOccurrences(of: "Bench Press", with: "Underwater Bench")),
            (200, Self.answer("Couldn't find that.")),
        ]
        _ = await tess().capture(miss, context: context)
        let second = try #require(String(data: RouteStub.bodies[1], encoding: .utf8))
        #expect(second.contains("that name or value didn't fit") && !second.contains("Underwater Bench\\u"))
    }

    @Test func whatTheGrammarReadsNeverReachesClaude() async {
        _ = await tess().capture("buy milk", context: context)
        #expect(RouteStub.requests.isEmpty)
    }

    // MARK: Waiting for Tess (tess-model-layer.md section 7)

    @Test func anOfflineMissWaitsAndIsReadLater() async {
        RouteStub.failure = .notConnectedToInternet
        let tess = tess()
        let offline = await tess.capture(miss, context: context)
        #expect(offline.line == "No connection. Saved it for Claude." && tess.waitingCount == 1)
        // The same phrase twice still waits once.
        _ = await tess.capture(miss, context: context)
        #expect(tess.waitingCount == 1)
        // Still offline at the next open: it stays.
        #expect(await tess.readWaiting(context: context).isEmpty && tess.waitingCount == 1)
        // Busy on read (529): Claude never read it, so it stays (QA S1 on #305).
        RouteStub.failure = nil
        RouteStub.reply = (529, "{}")
        #expect(await tess.readWaiting(context: context).isEmpty && tess.waitingCount == 1)
        RouteStub.reply = (200, Self.answer("Logged."))
        // Online: read as a pending ghost, and gone from the inbox.
        RouteStub.failure = nil
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Bench 80 × 8 logged."))]
        let read = await tess.readWaiting(context: context)
        #expect(read.count == 1 && read.first?.records.first?.state == .pending && tess.waitingCount == 0)
    }

    @Test func phrasesQueuedBeforeTheWallsNeverLeave() async throws {
        // Research 139 and 138 MW4: items saved before the walls drain through them, unread, and only the rest go.
        let waiting = try #require(classes[.tessWaiting])
        for phrase in ["wifi password is tacocat", "$38.20 trader joe's", "182.4 this morning", miss] {
            store.create(waiting, title: phrase).createdAt = .now
        }
        let inbox = TessInbox(store: store, classes: classes)
        #expect(inbox.add("door code 4417", at: .now) == nil && inbox.add("took 2 advil", at: .now) == nil)
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Bench 80 × 8 logged."))]
        let tess = tess()
        _ = await tess.readWaiting(context: context)
        #expect(tess.waitingCount == 0)
        let sent = RouteStub.bodies.compactMap { String(data: $0, encoding: .utf8) }.joined()
        #expect(!sent.isEmpty && !sent.contains("tacocat") && !sent.contains("38.20") && !sent.contains("182.4"))
    }

    @Test func aPhraseUnsentAfterAWeekIsDeletedAndANewerOneStays() async {
        let inbox = TessInbox(store: store, classes: classes)
        let day: TimeInterval = 24 * 3600
        inbox.add("log bench from eight days ago", at: context.now - 8 * day)
        inbox.add("log bench from six days ago", at: context.now - 6 * day)
        #expect(tess().waitingCount == 2)
        // Offline again: nothing is sent, the old one goes, the newer one waits.
        RouteStub.failure = .notConnectedToInternet
        #expect(await tess().readWaiting(context: context).isEmpty)
        #expect(inbox.waiting().map(\.title) == ["log bench from six days ago"])
    }

    @Test func aWeekOldPhraseIsDeletedEvenWithClaudeOff() async {
        let inbox = TessInbox(store: store, classes: classes)
        inbox.add("log bench from earlier", at: context.now - 8 * 24 * 3600)
        inbox.add("log squat from earlier", at: context.now - 3600)
        let off = tess(sends: false)
        #expect(await off.readWaiting(context: context).isEmpty)
        #expect(inbox.waiting().map(\.title) == ["log squat from earlier"] && RouteStub.requests.isEmpty)
    }

    @Test func aCookRunningKeepsWaitingPhrasesHomeUntilItEnds() async throws {
        let inbox = TessInbox(store: store, classes: classes)
        inbox.add("stop the rice", at: context.now - 3600)
        inbox.add("how is the timer doing", at: context.now - 3600)
        let recipe = try engine.perform(
            CreateRecipe(text: "Dal\nIngredients\n1 cup lentils\nMethod\n1. Simmer 20 minutes."), by: .user
        ).output
        let cook = try engine.perform(StartCooking(recipe: recipe.id, time: context.now), by: .user).output
        let tess = tess()
        #expect(await tess.readWaiting(context: context).isEmpty)
        #expect(RouteStub.requests.isEmpty && tess.waitingCount == 2, "a cook phrase was sent")
        // The cook ends: "stop the rice" goes; a phrase about a timer is never sent.
        try engine.perform(FinishCooking(cook: cook.id, time: context.now), by: .user)
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Bench 80 × 8 logged."))]
        _ = await tess.readWaiting(context: context)
        let sent = RouteStub.bodies.compactMap { String(data: $0, encoding: .utf8) }.joined()
        #expect(sent.contains("stop the rice") && !sent.contains("timer doing"))
        #expect(inbox.waiting().map(\.title) == ["how is the timer doing"])
    }

    @Test func theFirstDrainedPhraseCarriesTheNoticeAndOnlyIt() async {
        let inbox = TessInbox(store: store, classes: classes)
        inbox.add(miss, at: context.now - 7200)
        inbox.add("could you log squat 100 for 5 from earlier?", at: context.now - 3600)
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Bench 80 × 8 logged.")),
                           (200, Self.logBench), (200, Self.answer("Squat logged."))]
        let read = await tess().readWaiting(context: context)
        #expect(read.map(\.isNotice) == [true, false], "\(read.map(\.line))")
        #expect(read.first?.line.contains("Turn this off in Settings: Claude.") == true)
    }

    @Test func aDrainLandsAtMostThreeGhostsAndTheRestKeepWaiting() async {
        let inbox = TessInbox(store: store, classes: classes)
        for index in 1 ... 5 {
            inbox.add("could you log bench \(70 + index) for 8 from earlier?", at: context.now - Double(6000 - index))
        }
        RouteStub.queue = Array(repeating: [(200, Self.logBench), (200, Self.answer("Logged."))], count: 5)
            .flatMap(\.self)
        let tess = tess()
        #expect(await tess.readWaiting(context: context).count == 3 && tess.waitingCount == 2)
        #expect(inbox.waiting().map(\.title) == ["could you log bench 74 for 8 from earlier?",
                                                 "could you log bench 75 for 8 from earlier?"])
    }

    @Test func nothingWaitsForSiriAndAKeyNeverWaits() async {
        RouteStub.failure = .notConnectedToInternet
        let tess = tess()
        var shortcut = context
        shortcut.commitImmediately = true
        _ = await tess.capture(miss, context: shortcut)
        #expect(tess.waitingCount == 0)
        #expect(TessInbox(store: store, classes: classes).add("sk-ant-abc", at: .now) == nil)
    }
}
