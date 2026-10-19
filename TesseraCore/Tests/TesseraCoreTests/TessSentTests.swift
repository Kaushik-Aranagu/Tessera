import Foundation
import GRDB
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// G653: what was sent to Claude, on the phone only.
@MainActor
struct TessSentTests {
    let route: ClaudeRouteTests

    init() throws {
        route = try ClaudeRouteTests()
    }

    func sentLog() -> TessSentLog {
        TessSentLog(store: route.store, classes: route.classes, flags: route.flags)
    }

    @Test func whatWasSentHoldsWordsAsSentWithHandles() async throws {
        let tess = route.tess()
        RouteStub.queue = [(200, ClaudeRouteTests.logBench), (200, ClaudeRouteTests.answer("Bench 80 × 8 logged."))]
        _ = await tess.capture(route.miss, context: route.context)
        let entries = sentLog().entries()
        #expect(entries.count == 1 && sentLog().words(of: entries[0]) == route.miss)
        // Beside its Tess Call row, linked by the request id.
        let call = try #require(TessUsageLedger(store: route.store, classes: route.classes).calls().first)
        let callID = store(call, "requestID")
        #expect(callID == "req_test" && store(entries[0], "requestID") == callID)
    }

    func store(_ object: ObjectRecord, _ key: String) -> String? {
        route.store.value(key, of: object)?.stringValue
    }

    @Test func walledPhraseIsStoredAsPrivatePhrase() async {
        let tess = route.tess()
        RouteStub.queue = [(200, ClaudeRouteTests.logBench), (200, ClaudeRouteTests.answer("Logged."))]
        // A walled miss goes whole (his "all but the key"), and the log keeps only "Private phrase".
        let walled = "could you log that I paid 40 for gas earlier?"
        _ = await tess.capture(walled, context: route.context)
        let entries = sentLog().entries()
        #expect(entries.map { sentLog().words(of: $0) } == ["Private phrase"])
        let all = route.store.context.all(ObjectRecord.self).map { sentLog().words(of: $0) + $0.title }
        #expect(!all.contains { $0.contains("gas") || $0.contains("sk-ant") })
    }

    @Test func clearEmptiesPayloadsKeepsSpend() async {
        let tess = route.tess()
        RouteStub.queue = [(200, ClaudeRouteTests.logBench), (200, ClaudeRouteTests.answer("Logged."))]
        _ = await tess.capture(route.miss, context: route.context)
        let ledger = TessUsageLedger(store: route.store, classes: route.classes)
        let spent = ledger.monthTotal(now: route.context.now, calendar: route.context.calendar)
        #expect(spent > 0 && sentLog().count == 1)
        let receipt = sentLog().clear()
        #expect(receipt == "Cleared what was sent." && sentLog().count == 0)
        #expect(ledger.monthTotal(now: route.context.now, calendar: route.context.calendar) == spent)
        #expect(ledger.calls().count == 1)
        // No UNDO: clearing writes no op.
        #expect(route.engine.history().allSatisfy { $0.action != "clearSent" })
    }

    @Test func heldBackRequestsAreCounted() async {
        let tess = route.tess()
        #expect(sentLog().heldBackCount == 0)
        // A timer phrase stays home even though Claude is on.
        _ = await tess.capture("could you check on the timer for me please?", context: route.context)
        #expect(sentLog().heldBackCount == 1 && RouteStub.requests.isEmpty)
    }
}
