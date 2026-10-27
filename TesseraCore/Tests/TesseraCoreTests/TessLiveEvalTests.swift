import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The live runner (docs/ai/harness/test-world.md section 3). It runs the test world's questions through TessRun and
/// writes `eval-runs/<date>-<world>-<policy>.json`. It does nothing unless `TESSERA_LIVE_EVAL=1`; run it with
/// `scripts/tess-eval.sh`, which sets the rest. With `TESSERA_EVAL_DRY=1` a scripted brain answers and nothing leaves
/// the Mac.
///
/// Walls: a fresh test store in the temporary folder (a path inside the app's data folder is refused); the key is read
/// from the Mac keychain by the Claude brain and never printed or written; the month's cap is the smaller of $50 and
/// $100 minus what the phone spent, minus what earlier runs spent this month. The cap is enforced the way the phone
/// enforces its own: the test store's ledger starts with one row for everything above the allowance, so the Door's
/// reserve refuses a call before it is sent.
@MainActor
struct TessLiveEvalTests {
    struct Options {
        var world: EvalWorld.Size
        var policy: DoorPolicy
        var kinds: Set<String>
        /// Nil when not given: a live run refuses to start without it.
        var phoneSpentDollars: Double?
        var outDir: URL
        var dry: Bool
        /// A run stops asking after this many minutes (the rest are skipped, the report still written); 0 is no limit.
        var maxMinutes: Double
    }

    struct QuestionResult: Codable {
        var id: String
        var kind: String
        var turns: [String]
        var reply: String
        var toolsCalled: [String]
        var rung: String?
        var firstWordMs: Int?
        var totalMs: Int
        var costNano: Int64
        var score: WorldScore?
        /// The run's own answer-check span (shadow): "passed" or "failed", and how many numbers it called unsupported.
        /// Never the numbers or words themselves.
        var answerCheck: String?
        var answerCheckUnsupported: Int?
        /// The runner's own re-check of the reply's numbers against the world key (the question, the exact answer and
        /// the words it must say): how many it could not find there. Not what Tess was given: what the key knows.
        var keyUnsupported: Int?
        /// The check failed on a reply the key scores right: the number the 2% gate counts.
        var falseFail: Bool?
        var skipped: String?
        /// How each model call ended ("works", "badKey", "timeout"...): never a word of the call itself.
        var brainOutcomes: [String]?
    }

    /// The answer check's shadow results over the run (docs/ai/harness/checks.md): false fails are fails on replies the
    /// key scores right. The gate is under 2% of replies and none on money.
    struct CheckSummary: Codable {
        var checked: Int
        var failed: Int
        var falseFails: Int
        var falseFailRate: Double
        var moneyFalseFails: Int
    }

    struct SentScan: Codable {
        var rows: Int
        var walledWordHits: [String]
        var keyShaped: Int
    }

    struct Report: Codable {
        var date: String
        var world: String
        var policy: String
        var dry: Bool
        var allowanceDollars: Double
        var spentNano: Int64
        var asked: Int
        var passed: Int
        var stoppedForCap: Bool
        var sent: SentScan
        var answerCheck: CheckSummary
        var questions: [QuestionResult]
    }

    static func options() -> Options? {
        let env = ProcessInfo.processInfo.environment
        guard env["TESSERA_LIVE_EVAL"] == "1" else { return nil }
        let outDefault = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("eval-runs")
        return Options(
            world: EvalWorld.Size(rawValue: env["TESSERA_EVAL_WORLD"] ?? "small") ?? .small,
            policy: env["TESSERA_EVAL_POLICY"] == "strict" ? .strict : .lab,
            kinds: Set((env["TESSERA_EVAL_KINDS"] ?? "").split(separator: ",").map(String.init)),
            phoneSpentDollars: env["TESSERA_EVAL_PHONE_SPENT"].flatMap { Double($0) },
            outDir: env["TESSERA_EVAL_OUT"].map { URL(fileURLWithPath: $0) } ?? outDefault,
            dry: env["TESSERA_EVAL_DRY"] == "1",
            maxMinutes: env["TESSERA_EVAL_MINUTES"].flatMap { Double($0) } ?? 45
        )
    }

    /// Where the runner's month totals live, whatever the report folder is: not in the repo and not in the app's data.
    static var ledgerURL: URL {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/TessEval", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("ledger.json")
    }

    static func readLedger(_ url: URL) -> [String: Int64] {
        (try? JSONDecoder().decode([String: Int64].self, from: Data(contentsOf: url))) ?? [:]
    }

    /// Adds only the positive difference between what this run has spent and what it already recorded, to whatever the
    /// file holds right now, under a lock, so two runners (this one and the pyramid score) can never overwrite each
    /// other's rows on his money. Returns the new recorded figure.
    static func addToLedger(_ url: URL, month: String, spent: Int64, recorded: Int64) throws -> Int64 {
        let delta = max(0, spent - recorded)
        guard delta > 0 else { return recorded }
        let lockPath = url.appendingPathExtension("lock").path
        let descriptor = open(lockPath, O_CREAT | O_RDWR, 0o600)
        guard descriptor >= 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { flock(descriptor, LOCK_UN) }
        var months = readLedger(url)
        months[month, default: 0] += delta
        try JSONEncoder().encode(months).write(to: url, options: .atomic)
        return recorded + delta
    }

    /// What the simulator's own tests may spend this month, kept out of the runner's ceiling so the phone, the runners
    /// and the simulator together can never pass his $100.
    static let simulatorAllowanceDollars = 20.0

    /// $50, or $100 minus the phone's spend if that is smaller, minus what earlier runs spent this month.
    static func allowanceNano(phoneSpentDollars: Double, runnerSpentNano: Int64) -> Int64 {
        let ceiling = min(50.0, 100.0 - phoneSpentDollars - simulatorAllowanceDollars)
        return max(0, Int64(ceiling * 1_000_000_000) - runnerSpentNano)
    }

    @Test func liveRun() async throws {
        guard let options = Self.options() else { return }
        let manager = FileManager.default
        try manager.createDirectory(at: options.outDir, withIntermediateDirectories: true)
        let monthKey = TessSpendFile.monthKey(.now, calendar: .current)
        // One ledger in one fixed place whatever --out says, so no run can hide its spend by moving the report folder.
        let ledgerFile = Self.ledgerURL
        let months = Self.readLedger(ledgerFile)
        if !options.dry {
            // A live run must be told what the phone spent: defaulting it to 0 could take him past his $100 cap.
            try #require(
                options.phoneSpentDollars != nil,
                "a live run needs --phone-spent (what the phone spent this month)"
            )
        }
        let baseSpent = options.dry ? 0 : months[monthKey] ?? 0
        // What this run has already added to the shared ledger: only the difference is ever added again.
        var recorded: Int64 = 0
        let allowance = Self.allowanceNano(
            phoneSpentDollars: options.phoneSpentDollars ?? 0,
            runnerSpentNano: baseSpent
        )
        if !options.dry {
            try #require(allowance > 0, "the month's allowance for the runner is used up")
        }

        // A fresh test store in the temporary folder; never anywhere near the app's own.
        let folder = manager.temporaryDirectory.appendingPathComponent("tess-eval-\(UUID().uuidString)")
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: folder) }
        let appFolder = TesseraSchema.defaultURL.deletingLastPathComponent().resolvingSymlinksInPath().path
        try #require(!folder.resolvingSymlinksInPath().path.hasPrefix(appFolder))
        let storeURL = folder.appendingPathComponent("tessera.sqlite")
        let context = try TesseraContext(url: storeURL)
        let store = ObjectStore(context: context)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let world = EvalWorld.make(options.world)
        try EvalWorldSeeder.seed(world, into: engine)
        try #require(TestStore.allowsClaude(store))

        // The cap: everything above the allowance is already "spent" in this test store's ledger.
        let ledger = TessUsageLedger(store: store, classes: classes)
        if !options.dry {
            ledger.record(use: .question, model: "claude-haiku-5-5", input: 0, output: 0,
                          costNano: TessUsageLedger.capNano - allowance, latency: 0, outcome: "works",
                          requestID: nil)
        }
        // The Door's clock stays at the run's start, so a run that crosses midnight on the 1st can't start a fresh
        // month (and a fresh allowance) partway through.
        // The world's own moment (Friday Oct 23, 2026, 6:10 PM Pacific), not the wall clock: its dates are fixed, so a
        // run
        // on any other day would have Tess answer "October 2025" for a question about last month. The in-store ledger
        // and
        // the Door share it, so a run that crosses real midnight on the 1st can't start a fresh month either.
        let runStart = EvalWorld.now
        let before = ledger.monthTotal(now: runStart)

        let trace = RunTrace(url: TestStoreFiles.trace(of: storeURL))
        let keys = TessUsageLedgerKeys.make()
        let router = BrainRouter { id in
            if options.dry {
                return id == .haiku ? ScriptedBrain(.haiku, rounds: []) : nil
            }
            switch id {
            case .haiku: return ClaudeBrain(model: .haiku, keys: keys)
            case .sonnet: return ClaudeBrain(model: .sonnet, keys: keys)
            case .opus: return ClaudeBrain(model: .opus, keys: keys)
            default: return nil
            }
        }
        let door = Door(ledger: ledger, sentLog: TessSentLog(store: store, classes: classes), trace: trace,
                        router: router, policy: { options.policy }, asksClaude: { true })
        door.now = { runStart }
        engine.now = { runStart }
        engine.zone = { EvalWorld.calendar.timeZone }
        let conversation = TessConversation(store: store, classes: classes)
        let run = TessRun(door: door, engine: engine, conversation: conversation,
                          runs: TessRunStore(url: folder.appendingPathComponent("runs.json")))
        run.now = { runStart }

        let key = EvalWorldKey(world)
        let questions = key.questions().filter { options.kinds.isEmpty || options.kinds.contains($0.kind.rawValue) }
        var results: [QuestionResult] = []
        var stopped = false
        let clock = ContinuousClock()
        let runBegan = clock.now
        for question in questions {
            let timeUp = options.maxMinutes > 0
                && Self.milliseconds(clock.now - runBegan) > Int(options.maxMinutes * 60000)
            if stopped || timeUp {
                results.append(QuestionResult(id: question.id, kind: question.kind.rawValue, turns: question.turns,
                                              reply: "", toolsCalled: [], totalMs: 0, costNano: 0,
                                              skipped: stopped ? "the month's allowance was reached"
                                                  : "the run's time limit was reached"))
                continue
            }
            _ = conversation.clear()
            // Spans are stamped with the Door's pinned clock, so they are told apart by question, not by time: the
            // trace starts empty for each one.
            await trace.clear()
            var reply = ""
            var firstWord: Int?
            let started = ContinuousClock.now
            for turn in question.turns {
                var failedLine: String?
                var answered = false
                let before = await trace.all()
                let brainsBefore = before.filter { $0.kind == .brain }.count
                let checksBefore = before.filter { $0.kind == .check }.count
                for await event in run.ask(turn) {
                    switch event {
                    case .words:
                        if firstWord == nil {
                            firstWord = Self.milliseconds(clock.now - started)
                        }
                    case let .finished(text):
                        reply = text
                        answered = true
                    case let .failed(line): failedLine = line
                    default: break
                    }
                }
                // The turn's own check span lands a few milliseconds after its stream ends: wait (up to 3 s) until this
                // turn's span is there before the next turn starts, so a multi-turn question is scored on its last
                // reply.
                var waited = 0
                while answered, waited < 60 {
                    let now = await trace.all()
                    if now.filter({ $0.kind == .brain }).count == brainsBefore
                        || now.filter({ $0.kind == .check }).count > checksBefore
                    {
                        break
                    }
                    try? await Task.sleep(for: .milliseconds(50))
                    waited += 1
                }
                if let failedLine {
                    reply = failedLine
                    if failedLine == TessRun.cannotThink || failedLine == TessRun.noAnswer, !options.dry,
                       ledger.monthTotal() >= TessUsageLedger.capNano - 1_000_000
                    {
                        stopped = true
                    }
                }
            }
            let spans = await trace.all()
            let tools = spans.filter { $0.kind == .tool }.map(\.name)
            let rung = spans.last { $0.kind == .brain }?.brain
            let check = spans.last { $0.kind == .check && $0.name == TessRun.answerCheck }
            let scored = question.kind == .open ? nil : key.score(question, reply: reply, toolsCalled: tools)
            let cost = spans.reduce(Int64(0)) { $0 + $1.costNano }
            if !options.dry {
                // Written after every question, so a crash doesn't lose this run's spend.
                recorded = try Self.addToLedger(ledgerFile, month: monthKey,
                                                spent: max(0, ledger.monthTotal(now: runStart) - before),
                                                recorded: recorded)
            }
            results.append(QuestionResult(
                id: question.id, kind: question.kind.rawValue, turns: question.turns, reply: reply,
                toolsCalled: tools, rung: rung, firstWordMs: firstWord,
                totalMs: Self.milliseconds(clock.now - started), costNano: cost,
                score: scored, answerCheck: check?.outcome, answerCheckUnsupported: check?.unsupported,
                keyUnsupported: Self.keyUnsupported(question, reply: reply),
                falseFail: check.map { $0.outcome == "failed" && scored?.passed == true },
                brainOutcomes: spans.filter { $0.kind == .brain }.map(\.outcome)
            ))
        }

        // Under strict, the exact words sent are scanned for walled words and the key shape.
        let sentLog = TessSentLog(store: store, classes: classes)
        let walled = Set(questions.flatMap(\.mustNotSay).map { $0.lowercased() })
        var hits: [String] = []
        var keyShaped = 0
        for entry in sentLog.entries() {
            let words = sentLog.words(of: entry).lowercased()
            hits += walled.filter { words.contains($0) }
            if looksLikeClaudeKey(words) {
                keyShaped += 1
            }
        }
        let spent = max(0, ledger.monthTotal(now: runStart) - before)
        if !options.dry {
            recorded = try Self.addToLedger(ledgerFile, month: monthKey, spent: spent, recorded: recorded)
        }
        let scored = results.compactMap(\.score)
        let checked = results.filter { $0.answerCheck != nil }
        let falseFails = checked.filter { $0.falseFail == true }
        let summary = CheckSummary(
            checked: checked.count, failed: checked.filter { $0.answerCheck == "failed" }.count,
            falseFails: falseFails.count,
            falseFailRate: checked.isEmpty ? 0 : Double(falseFails.count) / Double(checked.count),
            moneyFalseFails: falseFails.filter { $0.kind == WorldKind.moneyAction.rawValue }.count
        )
        let day = ISO8601DateFormatter().string(from: .now).prefix(10)
        let report = Report(
            date: String(day), world: options.world.rawValue, policy: options.policy == .strict ? "strict" : "lab",
            dry: options.dry, allowanceDollars: Double(allowance) / 1_000_000_000, spentNano: spent,
            asked: results.filter { $0.skipped == nil }.count, passed: scored.filter(\.passed).count,
            stoppedForCap: stopped, sent: SentScan(rows: sentLog.count, walledWordHits: Array(Set(hits)).sorted(),
                                                   keyShaped: keyShaped),
            answerCheck: summary, questions: results
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // Nothing key-shaped is ever written: the whole encoded report is scanned under both policies.
        let encoded = try encoder.encode(report)
        try #require(
            !looksLikeClaudeKey(String(decoding: encoded, as: UTF8.self)),
            "the report holds a key-shaped string"
        )
        let name = "\(report.date)-\(report.world)-\(report.policy)\(options.dry ? "-dry" : "").json"
        try encoded.write(to: options.outDir.appendingPathComponent(name), options: .atomic)
        print("TESS-EVAL \(name): \(report.passed)/\(scored.count) passed, spent \(spent) nano")
        if options.policy == .strict {
            #expect(report.sent.walledWordHits.isEmpty && report.sent.keyShaped == 0)
        }
    }

    /// The reply's numbers that the key does not know: checked against the question, the exact answer and the words the
    /// reply must say, on the runner's side, with the same checker the phone runs.
    static func keyUnsupported(_ question: WorldQuestion, reply: String) -> Int {
        var known = question.turns + question.mustSay
        switch question.expected {
        case let .number(value, unit)?: known.append("\(value) \(unit ?? "")")
        case let .text(text)?: known.append(text)
        case let .day(date)?: known.append(date.formatted(.iso8601))
        default: break
        }
        return AnswerCheck().check(reply: reply, evidence: known).unsupported.count
    }

    static func milliseconds(_ duration: Duration) -> Int {
        Int(duration.components.seconds * 1000 + duration.components.attoseconds / 1_000_000_000_000_000)
    }

    @Test func theLedgerOnlyEverGainsTheDifferenceAndNeverOverwritesAnotherRunner() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("lock"))
        }
        var mine = try Self.addToLedger(url, month: "2026-10", spent: 100, recorded: 0)
        // Another runner adds its own row in between.
        _ = try Self.addToLedger(url, month: "2026-10", spent: 40, recorded: 0)
        mine = try Self.addToLedger(url, month: "2026-10", spent: 250, recorded: mine)
        // Nothing new: nothing added, and a lower figure never subtracts.
        mine = try Self.addToLedger(url, month: "2026-10", spent: 250, recorded: mine)
        _ = try Self.addToLedger(url, month: "2026-10", spent: 10, recorded: mine)
        #expect(Self.readLedger(url) == ["2026-10": 290])
    }

    @Test func theAllowanceIsTheSmallerOfFiftyAndWhatTheCapLeaves() {
        #expect(Self.allowanceNano(phoneSpentDollars: 0, runnerSpentNano: 0) == 50_000_000_000)
        #expect(Self.allowanceNano(phoneSpentDollars: 30, runnerSpentNano: 0) == 50_000_000_000)
        // The simulator's $20 is kept back: 100 - 50 - 20 leaves 30.
        #expect(Self.allowanceNano(phoneSpentDollars: 50, runnerSpentNano: 0) == 30_000_000_000)
        #expect(Self.allowanceNano(phoneSpentDollars: 70, runnerSpentNano: 0) == 10_000_000_000)
        #expect(Self.allowanceNano(phoneSpentDollars: 0, runnerSpentNano: 20_000_000_000) == 30_000_000_000)
        #expect(Self.allowanceNano(phoneSpentDollars: 79.5, runnerSpentNano: 1) == 499_999_999)
        #expect(Self.allowanceNano(phoneSpentDollars: 80, runnerSpentNano: 0) == 0)
        #expect(Self.allowanceNano(phoneSpentDollars: 100, runnerSpentNano: 0) == 0)
    }
}

/// The Mac keychain, read through the same item the app uses. Never printed.
enum TessUsageLedgerKeys {
    static func make() -> any TessKeychain {
        SystemKeychain()
    }
}
