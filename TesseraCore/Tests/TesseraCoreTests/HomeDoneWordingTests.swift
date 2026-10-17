import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

final class HomeStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var reply: (status: Int, body: String) = (200, "{}")
    nonisolated(unsafe) static var failure: URLError.Code?
    nonisolated(unsafe) static var redirect: String?
    nonisolated(unsafe) static var requests: [URLRequest] = []
    nonisolated(unsafe) static var bodies: [Data] = []

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HomeStub.self]
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
        var data = Data()
        if let stream = request.httpBodyStream {
            stream.open()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                data.append(buffer, count: count)
            }
            stream.close()
        }
        Self.bodies.append(data)
        if let failure = Self.failure {
            client?.urlProtocol(self, didFailWithError: URLError(failure))
            return
        }
        if let target = Self.redirect, let url = URL(string: target), request.url?.host() != url.host() {
            let hop = HTTPURLResponse(url: request.url!, statusCode: 301, httpVersion: nil,
                                      headerFields: ["Location": target])!
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: url), redirectResponse: hop)
            client?.urlProtocol(self, didReceive: hop, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.reply.status, httpVersion: nil,
                                       headerFields: ["request-id": "req_test"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.reply.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Home's done job (board 0al): asked once per finish, behind the switch and the 80% step-aside, every slot through
/// TessLineCheck, the rules words standing whenever anything fails.
@Suite(.serialized) @MainActor
struct HomeDoneWordingTests {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    static let ended = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 19, minute: 40))!
    static let key = "sk-" + "ant-" + "TEST-" + UUID().uuidString

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    var ledger: TessUsageLedger {
        TessUsageLedger(store: store, classes: classes)
    }

    init() throws {
        classes = try store.prepareCatalog()
        HomeStub.reply = (200, "{}")
        HomeStub.failure = nil
        HomeStub.redirect = nil
        HomeStub.requests = []
        HomeStub.bodies = []
    }

    static func reply(context: String?, detail: String?) -> String {
        func json(_ text: String?) -> String {
            text.map { "\"\($0)\"" } ?? "null"
        }
        return #"{"content":[{"type":"tool_use","id":"toolu_1","name":"proposeLines","input":{"lines":[{"item":"h1","#
            + #""context":\#(json(context)),"detail":\#(json(detail))}]}}],"stop_reason":"tool_use","#
            + #""usage":{"input_tokens":700,"output_tokens":30}}"#
    }

    func job(allowed: Bool = true, cache: URL? = nil) -> ClaudeHomeDone {
        let job = ClaudeHomeDone(keys: InMemoryKeychain(Self.key), ledger: ledger, session: HomeStub.session(),
                                 cacheURL: cache) { allowed }
        job.now = { Self.ended.addingTimeInterval(600) }
        job.calendar = Self.calendar
        // The deadline races the main actor, which the full suite keeps busy for long stretches; it isn't under test
        // here (the 6 s deadline is the app's).
        job.timeout = 600
        return job
    }

    static func line(_ title: String = "Push A", bests: [String] = ["Bench"], sinceLastDays: Int? = nil) -> HomeLine {
        let fact = HomeFact(id: UUID(), kind: .workout, title: title, state: .done, sets: 12, exercisesDone: 3,
                            exercisesPlanned: 3, records: bests, sinceLastDays: sinceLastDays,
                            startedAt: ended.addingTimeInterval(-3600), endedAt: ended)
        return HomeLines.line(for: fact, now: ended.addingTimeInterval(600), calendar: calendar)
    }

    @Test func aBestIsWordedOnceAndKept() async throws {
        HomeStub.reply = (200, Self.reply(context: "7:40 pm, a bench best", detail: nil))
        let job = job()
        let line = Self.line()
        let words = await job.words(for: line, dayLabel: "Thursday evening", store: store)
        #expect(words == HomeDoneWords(context: "7:40 pm, a bench best"),
                "\(ledger.calls().map { store.value("outcome", of: $0)?.stringValue ?? "" }) \(line.context ?? "-")")
        #expect(await job.words(for: line, dayLabel: "Thursday evening", store: store) == words)
        #expect(HomeStub.requests.count == 1 && ledger.calls().count == 1)
        let body = try #require(String(data: HomeStub.bodies[0], encoding: .utf8))
        #expect(body.contains(#""model":"claude-sonnet-5-5""#) && body.contains("<facts>"))
        #expect(!body.contains("weight") || body.contains("No weights")) // only the instructions name weights
    }

    @Test func sonnetIsNeverForcedToATool() async throws {
        // AI architecture on #658: Sonnet 5.5 refuses a forced tool, so the choice is auto.
        _ = await job().words(for: Self.line(), dayLabel: "Thursday evening", store: store)
        let body = try #require(HomeStub.bodies.first)
        let object = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect((object["tool_choice"] as? [String: Any])?["type"] as? String == "auto")
    }

    @Test func aDetailWithItsNewBestCountPasses() async {
        // HD1 through words(): "1 new best" is a count the pack licenses.
        let line = Self.line()
        let detail = "3 exercises, 12 sets, 1 new bench best."
        HomeStub.reply = (200, Self.reply(context: nil, detail: detail))
        #expect(await job().words(for: line, dayLabel: "Thursday evening", store: store)
            == HomeDoneWords(detail: detail), "\(line.detail ?? "-")")
    }

    @Test func aLineThatFailsLeavesTheRulesAndIsNeverAskedAgain() async {
        // C15: "after work" is banned outright; the rules words stand.
        HomeStub.reply = (200, Self.reply(context: "after work, a bench best", detail: nil))
        let job = job()
        let line = Self.line()
        #expect(await job.words(for: line, dayLabel: "Thursday evening", store: store) == nil)
        #expect(await job.words(for: line, dayLabel: "Thursday evening", store: store) == nil)
        #expect(HomeStub.requests.count == 1)
    }

    @Test func nothingIsSentWhenItShouldntBe() async {
        // Switch off; nothing to add (no best, a short gap); a walled title; at the 80% step-aside.
        #expect(await job(allowed: false).words(for: Self.line(), dayLabel: "Thursday evening", store: store) == nil)
        #expect(await job().words(for: Self.line(bests: [], sinceLastDays: 2), dayLabel: "Thursday evening",
                                  store: store) == nil)
        #expect(await job().words(for: Self.line("Gym pin 1234 day"), dayLabel: "Thursday evening",
                                  store: store) == nil)
        ledger.record(use: .lines, model: ClaudeHomeDone.model, input: 0, output: 0,
                      costNano: ClaudeHomeDone.stepAsideNano, latency: 0, outcome: "works", requestID: nil,
                      at: Self.ended)
        #expect(await job().words(for: Self.line(), dayLabel: "Thursday evening", store: store) == nil)
        #expect(HomeStub.requests.isEmpty)
    }

    @Test func homeLinesStopAtFortyCallsInAHouseDay() async throws {
        HomeStub.reply = (200, Self.reply(context: "7:40 pm, a bench best", detail: nil))
        func record(_ count: Int, at time: Date, use: TessUse = .lines) {
            for _ in 0 ..< count {
                ledger.record(use: use, model: ClaudeHomeDone.model, input: 0, output: 0, costNano: 1, latency: 0,
                              outcome: "works", requestID: nil, at: time)
            }
        }
        let now = Self.ended.addingTimeInterval(600) // 7:50 pm Thursday
        // Yesterday's calls (before 04:00 today), other jobs' and a fortieth of nothing do not count.
        record(40, at: Self.calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 3))!)
        record(40, at: now, use: .capture)
        record(39, at: now)
        #expect(job().callsToday() == 39)
        #expect(await job().words(for: Self.line(), dayLabel: "Thursday evening", store: store) != nil)
        #expect(HomeStub.requests.count == 1)
        // That call made forty. The next finish waits for tomorrow.
        #expect(job().callsToday() == ClaudeHomeDone.dailyCeiling)
        #expect(await job().words(for: Self.line("Pull B"), dayLabel: "Thursday evening", store: store) == nil)
        #expect(HomeStub.requests.count == 1)
        // The next house day opens again.
        let next = job()
        next.now = { Self.ended.addingTimeInterval(86400) }
        #expect(next.callsToday() == 0)
    }

    @Test func offlineTriesAgainButATimeoutNever() async throws {
        HomeStub.failure = .notConnectedToInternet
        let job = job()
        let line = Self.line()
        #expect(await job.words(for: line, dayLabel: "Thursday evening", store: store) == nil)
        #expect(try !job.wasAsked(#require(line.fact.id)))
        HomeStub.failure = .timedOut
        #expect(await job.words(for: line, dayLabel: "Thursday evening", store: store) == nil)
        #expect(try job.wasAsked(#require(line.fact.id)))
        #expect(await job.words(for: line, dayLabel: "Thursday evening", store: store) == nil)
        #expect(HomeStub.requests.count == 2)
    }

    @Test func aRedirectIsNeverFollowed() async {
        HomeStub.redirect = "https://" + "evil" + ".example/v1/messages"
        #expect(await job().words(for: Self.line(), dayLabel: "Thursday evening", store: store) == nil)
        #expect(!HomeStub.requests.contains { $0.url?.host()?.contains("evil") == true })
    }

    @Test func anUnreadableCacheIsNeverWrittenOver() async throws {
        // QA on #658: a file that can't be read (a locked device) keeps its history.
        let url = FileManager.default.temporaryDirectory
            .appending(path: "home-lines-\(UUID().uuidString)/home-lines-cache.json")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json yet".utf8).write(to: url)
        HomeStub.reply = (200, Self.reply(context: "7:40 pm, a bench best", detail: nil))
        _ = await job(cache: url).words(for: Self.line(), dayLabel: "Thursday evening", store: store)
        #expect(try String(contentsOf: url, encoding: .utf8) == "not json yet")
    }

    @Test func theCacheOutlivesTheAppAndStaysOutOfBackups() async throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "home-lines-\(UUID().uuidString)/home-lines-cache.json")
        HomeStub.reply = (200, Self.reply(context: "7:40 pm, a bench best", detail: nil))
        let line = Self.line()
        _ = await job(cache: url).words(for: line, dayLabel: "Thursday evening", store: store)
        let values = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
        let again = await job(cache: url).words(for: line, dayLabel: "Thursday evening", store: store)
        #expect(again == HomeDoneWords(context: "7:40 pm, a bench best") && HomeStub.requests.count == 1)
    }
}
