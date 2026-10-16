import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The canned Claude for PlanWordingTests.
final class PlanStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var reply: (status: Int, body: String)? = (200, #"{"input_tokens": 8}"#)
    nonisolated(unsafe) static var failure: URLError.Code?
    nonisolated(unsafe) static var requests: [URLRequest] = []
    /// Replies used in order before `reply` (a tool round, then the answer).
    nonisolated(unsafe) static var queue: [(status: Int, body: String)] = []
    /// Each request's JSON body (URLProtocol sees it as a stream).
    nonisolated(unsafe) static var bodies: [Data] = []

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PlanStub.self]
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
        let (status, body) = Self.queue.isEmpty ? Self.reply ?? (200, "{}") : Self.queue.removeFirst()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                       headerFields: ["request-id": "req_test"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Plan my day through Claude (plan-my-day-prompt.md; fixtures/plan-my-day-claude.md d01): the pack, the checks,
/// and every way back to the rules plan.
@Suite(.serialized) @MainActor
struct PlanWordingTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    var ledger: TessUsageLedger {
        TessUsageLedger(store: store, classes: classes)
    }

    let now = DayPlanTests.at(2, "08:00")

    init() throws {
        classes = try store.prepareCatalog()
        PlanStub.reply = (200, "{}")
        PlanStub.queue = []
        PlanStub.failure = nil
        PlanStub.requests = []
        PlanStub.bodies = []
    }

    /// d01: three tasks in one run, three meetings, Push A at 6 pm.
    var d01: DayPlan {
        var day = PlanInput(now: now, calendar: DayPlanTests.calendar)
        let at = { DayPlanTests.at(2, $0) }
        day.events = [PlanInput.Event(title: "Standup", start: at("09:30"), end: at("09:45")),
                      PlanInput.Event(title: "Design review", start: at("11:00"), end: at("12:00")),
                      PlanInput.Event(title: "1:1 Priya", start: at("15:00"), end: at("15:30"))]
        day.workout = PlanInput.Workout(title: "Push A", scheduledFor: at("18:00"))
        day.today = [
            PlanInput.Task(title: "Reply to landlord", minutes: 15, rolls: 1, rolledFrom: DayPlanTests.at(30, "09:00",
                                                                                                          month: 10),
                           updatedAt: DayPlanTests.at(30, "09:00", month: 10)),
            PlanInput.Task(title: "Book physio", due: at("00:00"), dueIsDateOnly: true, minutes: 20,
                           updatedAt: DayPlanTests.at(29, "09:00", month: 10)),
            PlanInput.Task(title: "Expense report", due: at("17:00"), minutes: 45,
                           updatedAt: DayPlanTests.at(27, "09:00", month: 10)),
        ]
        return DayPlanner.plan(day)
    }

    var pack: PlanPack? {
        PlanPack(plan: d01, now: now, calendar: DayPlanTests.calendar, calendarKnown: true, restDay: false)
    }

    static let ideal = #"""
    {"blocks":[{"id":"t1","start":"08:00","end":"08:15","lineText":""},
    {"id":"t3","start":"08:15","end":"08:35","lineText":""},{"id":"t2","start":"08:35","end":"09:20","lineText":""},
    {"id":"e1","start":"09:30","end":"09:45","lineText":""},{"id":"e2","start":"11:00","end":"12:00","lineText":""},
    {"id":"e3","start":"15:00","end":"15:30","lineText":""},{"id":"w1","start":"18:00","end":"19:00","lineText":""}],
    "startWith":{"id":"t1","line":"Landlord reply first, then physio, then the report."},
    "ghostLines":[{"id":"t1","line":"15 min, a quick one to open with."},
    {"id":"t3","line":"20 min, while the morning is quiet."},{"id":"t2","line":"45 min, done before Standup. Due 5 pm."}],
    "note":null}
    """#

    func proposal(_ json: String = Self.ideal) throws -> ProposePlan {
        try JSONDecoder().decode(ProposePlan.self, from: Data(json.utf8))
    }

    static func reply(_ proposal: String) -> String {
        #"{"content":[{"type":"tool_use","id":"toolu_1","name":"proposePlan","input":"#
            + proposal.replacingOccurrences(of: "\n", with: "")
            + #"}],"stop_reason":"tool_use","usage":{"input_tokens":1000,"output_tokens":270}}"#
    }

    @Test func thePackIsTheFixtureLine() throws {
        // fixtures/plan-my-day-claude.md d01, byte for byte: handles, no ids, no notes or health.
        let expected = #"{"allDay":[],"blocks":[{"end":"08:15","id":"t1","kind":"task","min":15,"run":1,"#
            + #""start":"08:00","title":"Reply to landlord"},{"due":"17:00","end":"09:00","id":"t2","kind":"task","#
            + #""min":45,"run":1,"start":"08:15","title":"Expense report"},{"end":"09:20","id":"t3","kind":"task","#
            + #""min":20,"run":1,"start":"09:00","title":"Book physio"},{"end":"09:45","fixed":true,"id":"e1","#
            + #""kind":"event","min":15,"start":"09:30","title":"Standup"},{"end":"12:00","fixed":true,"id":"e2","#
            + #""kind":"event","min":60,"start":"11:00","title":"Design review"},{"end":"15:30","fixed":true,"#
            + #""id":"e3","kind":"event","min":30,"start":"15:00","title":"1:1 Priya"},{"end":"19:00","fixed":true,"#
            + #""id":"w1","kind":"workout","min":60,"start":"18:00","title":"Push A"}],"cap":3,"light":false,"#
            + #""now":"08:00","weekday":"Mon","window":["08:00","21:00"]}"#
        #expect(try #require(pack).json == expected)
        // No task lines, no call (d14); no calendar adds "cal":false.
        var empty = PlanInput(now: now, calendar: DayPlanTests.calendar)
        empty.workout = PlanInput.Workout(title: "Push A", scheduledFor: DayPlanTests.at(2, "18:00"))
        #expect(PlanPack(plan: DayPlanner.plan(empty), now: now, calendar: DayPlanTests.calendar, calendarKnown: true,
                         restDay: false) == nil)
        let unknown = PlanPack(plan: d01, now: now, calendar: DayPlanTests.calendar, calendarKnown: false,
                               restDay: true)
        #expect(unknown?.json.contains(#""cal":false"#) == true && unknown?.json.contains(#""rest":true"#) == true)
    }

    @Test func theIdealReplyPassesAndApplies() throws {
        let pack = try #require(pack)
        #expect(try PlanProposalValidator.violations(proposal(), against: pack).isEmpty)
        let worded = try d01.applying(proposal(), pack: pack, calendar: DayPlanTests.calendar, now: now)
        #expect(worded.plan.ghosts.map(\.title) == ["Reply to landlord", "Book physio", "Expense report"])
        #expect(worded.plan.ghosts.map(\.start) == ["08:00", "08:15", "08:35"].map { DayPlanTests.at(2, $0) })
        #expect(worded.lines[1] == "20 min, while the morning is quiet.")
        #expect(worded.startLine == "Landlord reply first, then physio, then the report.")
    }

    @Test(arguments: [
        ("V3", #""id":"e1","start":"09:30""#, #""id":"e1","start":"09:35""#),
        ("V4", #""id":"t2","start":"08:35","end":"09:20""#, #""id":"t2","start":"08:40","end":"09:25""#),
        ("V7", #"{"id":"t2","line":"45 min, done before Standup. Due 5 pm."}"#, #"{"id":"e1","line":"Standup."}"#),
        ("V8", #""startWith":{"id":"t1""#, #""startWith":{"id":"t3""#),
        ("V9", #""id":"t1","start":"08:00","end":"08:15","lineText":"""#,
         #""id":"t1","start":"08:00","end":"08:15","lineText":"Quick.""#),
        ("V10", "a quick one to open with.", "late but quick."),
        ("V11", "Landlord reply first, then physio, then the report.", "Two quick ones, then the report."),
        ("V11", "Due 5 pm.", "Due 17:00."),
        ("V11", "Due 5 pm.", "Due 4 pm."),
        ("V12", "while the morning is quiet.", "while you're not tired."),
    ])
    func eachBadReplyIsCaught(_ code: String, _ from: String, _ to: String) throws {
        let bad = Self.ideal.replacingOccurrences(of: from, with: to)
        #expect(bad != Self.ideal)
        #expect(try PlanProposalValidator.violations(proposal(bad), against: #require(pack)).contains(code))
    }

    func wording() -> ClaudePlanWording {
        let wording = ClaudePlanWording(keys: InMemoryKeychain("sk-ant-TEST-plan"), ledger: ledger,
                                        session: PlanStub.session())
        wording.now = { DayPlanTests.at(2, "08:00") }
        wording.calendar = DayPlanTests.calendar
        return wording
    }

    @Test func claudeWordsItOnceAndTheSamePackIsReused() async throws {
        PlanStub.queue = [(200, Self.reply(Self.ideal))]
        let wording = wording()
        guard case let .worded(worded) = await wording.word(d01, pack: pack) else {
            Issue.record("not worded")
            return
        }
        #expect(worded.startLine == "Landlord reply first, then physio, then the report.")
        let body = try #require(String(data: PlanStub.bodies[0], encoding: .utf8))
        #expect(body.contains("claude-sonnet-5-5") && body.contains("proposePlan"))
        #expect(!body.contains(d01.blocks[0].object?.uuidString ?? "none"))
        // Same pack: no second call.
        _ = await wording.word(d01, pack: pack)
        #expect(PlanStub.requests.count == 1 && ledger.calls().count == 1)
    }

    @Test func everyFailureShowsTheRulesPlan() async {
        PlanStub.queue = [(200, Self.reply(Self.ideal.replacingOccurrences(of: "Due 5 pm.", with: "Due 17:00.")))]
        #expect(await wording().word(d01, pack: pack) == .rules(line: nil))
        #expect(ledger.calls().last.flatMap { store.value("outcome", of: $0)?.stringValue }?
            .hasPrefix("rejected") == true)
        PlanStub.failure = .timedOut
        #expect(await wording().word(d01, pack: pack)
            == .rules(line: "Claude didn't answer in time. Here's your usual plan."))
        PlanStub.failure = nil
        PlanStub.queue = [(200, Self.reply(Self.ideal))]
        // A late reply (he touched the plan) is dropped, its cost still counted.
        #expect(await wording().word(d01, pack: pack, stale: { true }) == .rules(line: nil))
        #expect(ledger.calls().count == 3)
        #expect(ledger.calls().last.flatMap { store.value("outcome", of: $0)?.stringValue } == "late")
    }

    @Test func atTheCapNothingIsSent() async {
        ledger.record(
            use: .plan,
            model: ClaudePlanWording.model,
            input: 0,
            output: 0,
            costNano: TessUsageLedger.capNano,
            latency: 0,
            outcome: "works",
            requestID: nil,
            at: now
        )
        #expect(await wording().word(d01, pack: pack)
            == .rules(line: "Claude paused until Dec 1. Here's your usual plan."))
        #expect(PlanStub.requests.isEmpty)
    }
}
