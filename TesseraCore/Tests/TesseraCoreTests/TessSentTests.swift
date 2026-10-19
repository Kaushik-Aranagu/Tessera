import Foundation
import GRDB
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// G653: what was sent to Claude, on the phone only.
extension ClaudeRouteTests {
    func sentLog() -> TessSentLog {
        TessSentLog(store: store, classes: classes, flags: flags)
    }

    @Test func whatWasSentHoldsWordsAsSentWithHandles() async throws {
        let tess = tess()
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Bench 80 × 8 logged."))]
        _ = await tess.capture(miss, context: context)
        let entries = sentLog().entries()
        // The phrase first, then what rode with it (his date, the workout and last set in focus).
        let sent = sentLog().words(of: entries[0]).split(separator: "\n").map(String.init)
        #expect(entries.count == 1 && sent.first == miss && sent.count == 4, "\(sent)")
        #expect(sent.dropFirst().map { $0.prefix(5) } == ["Today", "Worko", "Last "])
        // Beside its Tess Call row, linked by the request id.
        let call = try #require(TessUsageLedger(store: store, classes: classes).calls().first)
        let callID = store(call, "requestID")
        #expect(callID == "req_test" && store(entries[0], "requestID") == callID)
    }

    func store(_ object: ObjectRecord, _ key: String) -> String? {
        store.value(key, of: object)?.stringValue
    }

    @Test func walledPhraseIsStoredAsPrivatePhrase() async {
        let tess = tess()
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Logged."))]
        // A walled miss goes whole (his "all but the key"), and the log keeps only "Private phrase".
        let walled = "could you log that I paid 40 for gas earlier?"
        _ = await tess.capture(walled, context: context)
        let entries = sentLog().entries()
        #expect(entries
            .map { sentLog().words(of: $0).split(separator: "\n").first.map(String.init) } == ["Private phrase"])
        let all = store.context.all(ObjectRecord.self).map { sentLog().words(of: $0) + $0.title }
        #expect(!all.contains { $0.contains("gas") || $0.contains("sk-ant") })
    }

    @Test func clearEmptiesPayloadsKeepsSpend() async {
        let tess = tess()
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Logged."))]
        _ = await tess.capture(miss, context: context)
        let ledger = TessUsageLedger(store: store, classes: classes)
        let spent = ledger.monthTotal(now: context.now, calendar: context.calendar)
        #expect(spent > 0 && sentLog().count == 1)
        let receipt = sentLog().clear()
        #expect(receipt == "Cleared what was sent." && sentLog().count == 0)
        #expect(ledger.monthTotal(now: context.now, calendar: context.calendar) == spent)
        #expect(ledger.calls().count == 1)
        // No UNDO: clearing writes no op.
        #expect(engine.history().allSatisfy { $0.action != "clearSent" })
    }

    @Test func heldBackRequestsAreCounted() async {
        let tess = tess()
        #expect(sentLog().heldBackCount == 0)
        // A timer phrase stays home even though Claude is on.
        _ = await tess.capture("could you check on the timer for me please?", context: context)
        #expect(sentLog().heldBackCount == 1 && RouteStub.requests.isEmpty)
    }

    @Test func offlineAttemptWritesNoSentRow() async {
        RouteStub.failure = .notConnectedToInternet
        let tess = tess()
        let capture = await tess.capture(miss, context: context)
        #expect(capture.line == "No connection. Saved it for Claude.")
        #expect(sentLog().count == 0 && ledger.calls().isEmpty, "an offline attempt wrote a row")
    }

    @Test func drainedPhraseWritesOneSentRow() async {
        RouteStub.failure = .notConnectedToInternet
        let tess = tess()
        _ = await tess.capture(miss, context: context)
        #expect(sentLog().count == 0)
        RouteStub.failure = nil
        RouteStub.queue = [(200, Self.logBench), (200, Self.answer("Logged."))]
        _ = await tess.readWaiting(context: context)
        #expect(sentLog().count == 1 && ledger.calls().count == 1)
        let first = sentLog().entries()[0]
        #expect(sentLog().words(of: first).hasPrefix(miss))
    }

    @Test func aRequestThatLeftAndTimedOutKeepsItsOneRow() async throws {
        RouteStub.hang = true
        var claude = try #require(self.tess().claude)
        claude.timeout = 0.3
        let tess = TessCaptureEngine(engine: engine)
        tess.claude = claude
        let capture = await tess.capture(miss, context: context)
        #expect(capture.line == "Claude didn't answer in time.", "\(capture.line)")
        #expect(sentLog().count == 1 && ledger.calls().count == 1)
    }

    @Test func theLogKeepsThirtyDaysAndFiveHundredRows() {
        let log = sentLog()
        let now = context.now
        log.record(words: "old words", use: .capture, requestID: nil, at: now - 31 * 24 * 3600)
        for index in 0 ..< 505 {
            log.record(words: "row \(index)", use: .capture, requestID: nil, at: now - Double(600 - index))
        }
        #expect(log.count == TessSentLog.maxRows)
        let words = log.entries().map { log.words(of: $0) }
        #expect(!words.contains("old words") && words.first == "row 504" && !words.contains("row 0"))
    }

    @Test func everyClaudeJobWritesASentRow() {
        let ledger = ledger
        let at = context.now
        for use in [TessUse.lines, .plan, .recipeLink, .keyCheck] {
            ledger.record(use: use, model: ClaudeTessModel.model, input: 10, output: 5, costNano: 1, latency: 0.1,
                          outcome: "works", requestID: "req_\(use.rawValue)", at: at,
                          sent: use == .recipeLink ? TessSentLog.heldBackPayload : "payload for \(use.rawValue)")
        }
        let entries = sentLog().entries()
        #expect(entries.count == 4 && ledger.calls().count == 4)
        let byRequest = Dictionary(uniqueKeysWithValues: entries.map { (
            self.store.value("requestID", of: $0)?.stringValue ?? "",
            sentLog().words(of: $0)
        ) })
        #expect(byRequest["req_recipeLink"] == "Held back on this phone")
        #expect(byRequest["req_keyCheck"] == "payload for keyCheck")
        // An offline attempt of any job writes nothing at all.
        ledger.record(use: .plan, model: ClaudeTessModel.model, input: 0, output: 0, costNano: 0, latency: 0,
                      outcome: "offline", requestID: nil, at: at, sent: "never left")
        #expect(sentLog().count == 4 && ledger.calls().count == 4)
    }

    @Test func willSendFiresOnlyWhenARequestLeavesAndCancelStopsIt() async throws {
        var sends = 0
        self.flags.willSend = { sends += 1 }
        let tess = tess()
        // A grammar-only answer never leaves, so the line never shows.
        _ = await tess.capture("buy milk", context: context)
        #expect(sends == 0)
        // A request that leaves fires it, and Cancel ends the call with "Cancelled.".
        RouteStub.hang = true
        let flags = flags
        let task = Task { @MainActor in await tess.capture(self.miss, context: self.context).line }
        for _ in 0 ..< 200 where sends == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(sends >= 1)
        flags.cancelAsking()
        let line = await task.value
        #expect(line == "Cancelled.", "\(line)")
    }
}
