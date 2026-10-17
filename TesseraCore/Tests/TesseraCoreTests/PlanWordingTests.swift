import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The canned Claude for PlanWordingTests.
final class PlanStub: URLProtocol, @unchecked Sendable {
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
        PlanStub.redirect = nil
        PlanStub.bodies = []
    }

    /// d01: three tasks in one run, three meetings, Push A at 6 pm.
    var d01: DayPlan {
        DayPlanner.plan(d01Input)
    }

    var d01Input: PlanInput {
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
        return day
    }

    var pack: PlanPack? {
        PlanPack(plan: d01, now: now, calendar: DayPlanTests.calendar, calendarKnown: true, restDay: false,
                 otherNames: ["Sort the garage", "Mum's birthday", "Push A", "Lunch", "Reply to landlord today"],
                 lastWeightKg: nil)
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
        // fixtures/plan-my-day-claude.md d01, byte for byte: handles, no ids, no notes or health. "Book physio" goes as
        // "task" since the Home wall (QA audit of d6fd9ca).
        let expected = #"{"allDay":[],"blocks":[{"end":"08:15","id":"t1","kind":"task","min":15,"run":1,"#
            + #""start":"08:00","title":"Reply to landlord"},{"due":"17:00","end":"09:00","id":"t2","kind":"task","#
            + #""min":45,"run":1,"start":"08:15","title":"Expense report"},{"end":"09:20","id":"t3","kind":"task","#
            + #""min":20,"run":1,"start":"09:00","title":"task"},{"end":"09:45","fixed":true,"id":"e1","#
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
                         restDay: false, lastWeightKg: nil) == nil)
        let unknown = PlanPack(plan: d01, now: now, calendar: DayPlanTests.calendar, calendarKnown: false,
                               restDay: true, lastWeightKg: nil)
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
        // QA T1: an added, dropped or renamed block.
        ("V2", #""id":"e3","start":"15:00""#, #""id":"e9","start":"15:00""#),
        ("V2", #"{"id":"e3","start":"15:00","end":"15:30","lineText":""},"#, ""),
        // V13 (Product 10:24 PM PT, fixture N5): something he has that isn't in this plan.
        ("V13", "while the morning is quiet.", "before Sort the garage."),
        ("V13", "a quick one to open with.", "before Mum's birthday."),
    ])
    func eachBadReplyIsCaught(_ code: String, _ from: String, _ to: String) throws {
        let bad = Self.ideal.replacingOccurrences(of: from, with: to)
        #expect(bad != Self.ideal)
        #expect(try PlanProposalValidator.violations(proposal(bad), against: #require(pack)).contains(code))
    }

    func wording() -> ClaudePlanWording {
        let wording = ClaudePlanWording(keys: InMemoryKeychain("sk-ant-TEST-plan"), ledger: ledger,
                                        session: PlanStub.session(), allowed: { true })
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

    @Test func aRedirectIsNeverFollowedForThePlan() async {
        // Product 9:53 PM PT: the plan call refuses a 301 and keeps his usual plan.
        PlanStub.redirect = "https://" + "evil" + ".example/v1/messages"
        let result = await wording().word(d01, pack: pack)
        if case .worded = result {
            Issue.record("a redirected reply was used")
        }
        #expect(!PlanStub.requests.contains { $0.url?.host()?.contains("evil") == true })
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

    @Test(arguments: [(2026, 11, 1), (2027, 3, 14)])
    func aDSTDayPacksWallClockTimes(_ date: (Int, Int, Int)) throws {
        // QA P1: the pack and the applied plan read 07:00 on the clock, not an hour off.
        let calendar = DayPlanTests.calendar
        let open = try #require(calendar.date(from: DateComponents(year: date.0, month: date.1, day: date.2, hour: 6)))
        var input = PlanInput(now: open, calendar: calendar)
        input.later = [PlanInput.Task(title: "Fix bike light", minutes: 20, updatedAt: open)]
        let plan = DayPlanner.plan(input)
        let pack = try #require(PlanPack(plan: plan, now: open, calendar: calendar, calendarKnown: true,
                                         restDay: false, lastWeightKg: nil))
        #expect(pack.json.contains(#""window":["07:00","21:00"]"#) && pack.json.contains(#""start":"07:00""#))
        let reply = try JSONDecoder().decode(ProposePlan.self, from: Data(#"""
        {"blocks":[{"id":"t1","start":"07:00","end":"07:20","lineText":""}],"startWith":{"id":"t1",
        "line":"Bike light first, 7 am."},"ghostLines":[{"id":"t1","line":"20 min on the bike light."}],"note":null}
        """#.utf8))
        #expect(PlanProposalValidator.violations(reply, against: pack).isEmpty)
        let applied = plan.applying(reply, pack: pack, calendar: calendar, now: open)
        #expect(try calendar.component(.hour, from: #require(applied.plan.ghosts.first).start) == 7)
    }

    @Test func aRestDaySaysOnlyRestDay() throws {
        // V13: no workout block, so no training words; on a rest day the note "Rest day." alone is fine.
        var input = PlanInput(now: now, calendar: DayPlanTests.calendar)
        input.later = [PlanInput.Task(title: "Fix bike light", minutes: 20, updatedAt: now)]
        let plan = DayPlanner.plan(input)
        let rest = try #require(PlanPack(plan: plan, now: now, calendar: DayPlanTests.calendar, calendarKnown: true,
                                         restDay: true, lastWeightKg: nil))
        func reply(_ note: String) throws -> ProposePlan {
            let json = #"{"blocks":[{"id":"t1","start":"08:00","end":"08:20","lineText":""}],"#
                + #""startWith":{"id":"t1","line":"Bike light first."},"#
                + #""ghostLines":[{"id":"t1","line":"20 min on the bike light."}],"note":""# + note + #""}"#
            return try JSONDecoder().decode(ProposePlan.self, from: Data(json.utf8))
        }
        #expect(try PlanProposalValidator.violations(reply("Rest day."), against: rest).isEmpty)
        #expect(try PlanProposalValidator.violations(reply("No gym today."), against: rest).contains("V13"))
    }

    @Test func eachFailureHasProductsLine() async throws {
        // Product 10:24 PM PT, and effort low on the wire (QA P5).
        PlanStub.reply = (401, "{}")
        #expect(await wording().word(d01, pack: pack)
            == .rules(line: "That key didn't work. Paste it again? Here's your usual plan."))
        PlanStub.reply = (529, "{}")
        #expect(await wording().word(d01, pack: pack) == .rules(line: "Here's your usual plan."))
        PlanStub.failure = .notConnectedToInternet
        #expect(await wording().word(d01, pack: pack) == .rules(line: "Here's your usual plan."))
        let body = try #require(String(data: PlanStub.bodies[0], encoding: .utf8))
        #expect(body.contains(#""effort":"low""#))
    }

    @Test func eventTitlesCanStayOnThePhone() throws {
        let pack = try #require(PlanPack(plan: d01, now: now, calendar: DayPlanTests.calendar, calendarKnown: true,
                                         restDay: false, includesEventTitles: false, lastWeightKg: nil))
        #expect(!pack.json.contains("Standup") && !pack.json.contains("Priya"))
        #expect(pack.json.contains(#""kind":"event","min":15,"start":"09:30","title":"busy""#))
        #expect(pack.json.contains("Reply to landlord") && pack.json.contains("Push A"))
    }

    @Test func privateTitlesGoAsTaskOrBusy() {
        /// QA A4, Research 138 MB24 to MB27 and 139: secret, money and body titles never ride in the pack.
        func block(_ kind: DayPlan.Kind, _ title: String) -> DayPlan.Block {
            DayPlan.Block(kind: kind, title: title, start: now, end: now.addingTimeInterval(900), object: nil,
                          ghost: kind == .task, due: nil, movedFrom: nil, running: false)
        }
        for title in ["Coffee 6.25", "Pay Sam back $40", "Refill lexapro 10mg", "Reset my PIN",
                      "Password reset email"]
        {
            #expect(
                PlanPack.packTitle(block(.task, title), includesEventTitles: true, lastWeightKg: nil) == "task",
                "\(title)"
            )
        }
        #expect(PlanPack
            .packTitle(block(.event, "Dentist, copay $35"), includesEventTitles: true, lastWeightKg: nil) == "busy")
        #expect(PlanPack
            .packTitle(block(.task, "Reply to landlord"), includesEventTitles: true, lastWeightKg: nil) ==
            "Reply to landlord")
        #expect(PlanPack.packTitle(block(.event, "Standup"), includesEventTitles: true, lastWeightKg: nil) == "Standup")
    }

    @Test func everyClaudeModelHasAPriceAndAnUnknownOneNeverSpends() {
        // QA A6: a model with no price row would cost 0 against the cap; it is refused instead.
        for model in [ClaudePlanWording.model, ClaudeRecipeReader.model, ClaudeTessModel.model] {
            #expect(TessUsageLedger.prices[model] != nil, "\(model)")
        }
        #expect(TessUsageLedger.estimate(text: "hi", maxTokens: 10, model: "claude-unknown") == 0)
        #expect(ledger.reserve(0, now: now, calendar: DayPlanTests.calendar) == nil)
    }

    @Test func aRejectedPackIsRememberedAndTheSwitchIsOne() async {
        // Merge check on #298: reopening after a rejection makes no second paid call.
        PlanStub.queue = [(200, Self.reply(Self.ideal.replacingOccurrences(of: "Due 5 pm.", with: "Due 17:00.")))]
        let wording = wording()
        _ = await wording.word(d01, pack: pack)
        _ = await wording.word(d01, pack: pack)
        #expect(PlanStub.requests.count == 1)
        // "Tess asks Claude" off: nothing is sent.
        let off = self.wording()
        off.allowed = { false }
        #expect(await off.word(d01, pack: pack) == .rules(line: nil) && PlanStub.requests.count == 1)
    }

    @Test func aCutOffReplyShowsTheRulesPlan() async {
        PlanStub.queue = [(200, Self.reply(Self.ideal).replacingOccurrences(of: #""stop_reason":"tool_use""#,
                                                                            with: #""stop_reason":"max_tokens""#))]
        #expect(await wording().word(d01, pack: pack) == .rules(line: nil))
        #expect(ledger.calls().last.flatMap { store.value("outcome", of: $0)?.stringValue } == "max_tokens")
    }

    @Test(arguments: [
        "the rest of the afternoon is yours.", "before lunch.", "a quick session before Standup.",
        "the landlord reply, before Standup.",
    ])
    func ordinaryWordsPassV13(_ line: String) throws {
        // QA S1 on #303: "rest", a one-word Later task, "session", and a name overlapping a plan title.
        let bad = Self.ideal.replacingOccurrences(of: "while the morning is quiet.", with: line)
        #expect(try !PlanProposalValidator.violations(proposal(bad), against: #require(pack)).contains("V13"))
    }

    @Test func aMinuteLaterTheWordingIsReusedAndAFailureIsRememberedToday() async {
        // QA S2: 08:00 then 08:07, one request; the times repack from the new start.
        PlanStub.queue = [(200, Self.reply(Self.ideal))]
        let wording = wording()
        _ = await wording.word(d01, pack: pack)
        var later = PlanInput(now: DayPlanTests.at(2, "08:07"), calendar: DayPlanTests.calendar)
        later.events = d01Input.events
        later.workout = d01Input.workout
        later.today = d01Input.today
        let plan = DayPlanner.plan(later)
        let next = PlanPack(plan: plan, now: DayPlanTests.at(2, "08:07"), calendar: DayPlanTests.calendar,
                            calendarKnown: true, restDay: false, lastWeightKg: nil)
        wording.now = { DayPlanTests.at(2, "08:07") }
        guard case let .worded(again) = await wording.word(plan, pack: next) else {
            Issue.record("not reused")
            return
        }
        #expect(PlanStub.requests.count == 1)
        #expect(again.plan.ghosts.first?.start == DayPlanTests.at(2, "08:10"))
        // A rejection (or a late reply) is remembered for the day; a bad key is not.
        let failing = self.wording()
        PlanStub.queue = [(200, Self.reply(Self.ideal.replacingOccurrences(of: "Due 5 pm.", with: "Due 17:00.")))]
        _ = await failing.word(d01, pack: pack, stale: { true })
        _ = await failing.word(d01, pack: pack)
        #expect(PlanStub.requests.count == 2)
        let keyed = self.wording()
        PlanStub.reply = (401, "{}")
        _ = await keyed.word(d01, pack: pack)
        _ = await keyed.word(d01, pack: pack)
        #expect(PlanStub.requests.count == 4)
    }

    @Test func anAllDayTitleInThePlanIsNotSomethingElse() throws {
        var day = d01Input
        day.events.append(PlanInput.Event(title: "Bank holiday", start: DayPlanTests.at(2, "00:00"),
                                          end: DayPlanTests.at(3, "00:00"), allDay: true))
        let plan = DayPlanner.plan(day)
        let pack = try #require(PlanPack(plan: plan, now: now, calendar: DayPlanTests.calendar, calendarKnown: true,
                                         restDay: false, otherNames: ["Bank holiday"], lastWeightKg: nil))
        let line = Self.ideal.replacingOccurrences(of: "while the morning is quiet.", with: "a Bank holiday morning.")
        #expect(try !PlanProposalValidator.violations(proposal(line), against: pack).contains("V13"))
    }

    @Test(arguments: ["Physio at 5", "Call mom about the lawyer", "Pay Dr Lee"])
    func careMoneyAndPeopleTitlesGoAsTask(_ title: String) throws {
        // QA's walls audit of d6fd9ca: the plan pack uses the Home pack's wall.
        #expect(PlanPack.isPrivate(title, lastWeightKg: nil), "\(title)")
        var input = PlanInput(now: now, calendar: DayPlanTests.calendar)
        input.later = [PlanInput.Task(title: title, minutes: 20, updatedAt: now)]
        let pack = try #require(PlanPack(plan: DayPlanner.plan(input), now: now, calendar: DayPlanTests.calendar,
                                         calendarKnown: true, restDay: false, lastWeightKg: nil))
        #expect(!pack.json.contains(title), "\(pack.json)")
        #expect(!PlanPack.isPrivate("Fix bike light", lastWeightKg: nil))
    }
}
