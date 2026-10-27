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
        var phoneSpentDollars: Double
        var outDir: URL
        var dry: Bool
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
        var skipped: String?
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
            phoneSpentDollars: Double(env["TESSERA_EVAL_PHONE_SPENT"] ?? "") ?? 0,
            outDir: env["TESSERA_EVAL_OUT"].map { URL(fileURLWithPath: $0) } ?? outDefault,
            dry: env["TESSERA_EVAL_DRY"] == "1"
        )
    }

    /// $50, or $100 minus the phone's spend if that is smaller, minus what earlier runs spent this month.
    static func allowanceNano(phoneSpentDollars: Double, runnerSpentNano: Int64) -> Int64 {
        let ceiling = min(50.0, 100.0 - phoneSpentDollars)
        return max(0, Int64(ceiling * 1_000_000_000) - runnerSpentNano)
    }

    @Test func liveRun() async throws {
        guard let options = Self.options() else { return }
        let manager = FileManager.default
        try manager.createDirectory(at: options.outDir, withIntermediateDirectories: true)
        let monthKey = TessSpendFile.monthKey(.now, calendar: .current)
        let ledgerFile = options.outDir.appendingPathComponent("ledger.json")
        var months = (try? JSONDecoder().decode([String: Int64].self, from: Data(contentsOf: ledgerFile))) ?? [:]
        let allowance = Self.allowanceNano(phoneSpentDollars: options.phoneSpentDollars,
                                           runnerSpentNano: options.dry ? 0 : months[monthKey] ?? 0)
        if !options.dry {
            #expect(allowance > 0, "the month's allowance for the runner is used up")
            guard allowance > 0 else { return }
        }

        // A fresh test store in the temporary folder; never anywhere near the app's own.
        let folder = manager.temporaryDirectory.appendingPathComponent("tess-eval-\(UUID().uuidString)")
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: folder) }
        let appFolder = TesseraSchema.defaultURL.deletingLastPathComponent().resolvingSymlinksInPath().path
        #expect(!folder.resolvingSymlinksInPath().path.hasPrefix(appFolder))
        let storeURL = folder.appendingPathComponent("tessera.sqlite")
        let context = try TesseraContext(url: storeURL)
        let store = ObjectStore(context: context)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let world = EvalWorld.make(options.world)
        try EvalWorldSeeder.seed(world, into: engine)
        #expect(TestStore.allowsClaude(store))

        // The cap: everything above the allowance is already "spent" in this test store's ledger.
        let ledger = TessUsageLedger(store: store, classes: classes)
        if !options.dry {
            ledger.record(use: .question, model: "claude-haiku-5-5", input: 0, output: 0,
                          costNano: TessUsageLedger.capNano - allowance, latency: 0, outcome: "works",
                          requestID: nil)
        }
        let before = ledger.monthTotal()

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
        let conversation = TessConversation(store: store, classes: classes)
        let run = TessRun(door: door, engine: engine, conversation: conversation,
                          runs: TessRunStore(url: folder.appendingPathComponent("runs.json")))

        let key = EvalWorldKey(world)
        let questions = key.questions().filter { options.kinds.isEmpty || options.kinds.contains($0.kind.rawValue) }
        var results: [QuestionResult] = []
        var stopped = false
        let clock = ContinuousClock()
        for question in questions {
            if stopped {
                results.append(QuestionResult(id: question.id, kind: question.kind.rawValue, turns: question.turns,
                                              reply: "", toolsCalled: [], totalMs: 0, costNano: 0,
                                              skipped: "the month's allowance was reached"))
                continue
            }
            _ = conversation.clear()
            var reply = ""
            var firstWord: Int?
            let started = ContinuousClock.now
            let startedAt = Date.now
            for turn in question.turns {
                var failedLine: String?
                for await event in run.ask(turn) {
                    switch event {
                    case .words:
                        if firstWord == nil {
                            firstWord = Self.milliseconds(clock.now - started)
                        }
                    case let .finished(text): reply = text
                    case let .failed(line): failedLine = line
                    default: break
                    }
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
            let spans = await trace.all().filter { $0.at >= startedAt.addingTimeInterval(-1) }
            let tools = spans.filter { $0.kind == .tool }.map(\.name)
            let rung = spans.last { $0.kind == .brain }?.brain
            let cost = spans.reduce(Int64(0)) { $0 + $1.costNano }
            results.append(QuestionResult(
                id: question.id, kind: question.kind.rawValue, turns: question.turns, reply: reply,
                toolsCalled: tools, rung: rung, firstWordMs: firstWord,
                totalMs: Self.milliseconds(clock.now - started), costNano: cost,
                score: question.kind == .open ? nil : key.score(question, reply: reply, toolsCalled: tools)
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
        let spent = max(0, ledger.monthTotal() - before)
        if !options.dry {
            months[monthKey, default: 0] += spent
            try JSONEncoder().encode(months).write(to: ledgerFile, options: .atomic)
        }
        let scored = results.compactMap(\.score)
        let day = ISO8601DateFormatter().string(from: .now).prefix(10)
        let report = Report(
            date: String(day), world: options.world.rawValue, policy: options.policy == .strict ? "strict" : "lab",
            dry: options.dry, allowanceDollars: Double(allowance) / 1_000_000_000, spentNano: spent,
            asked: results.filter { $0.skipped == nil }.count, passed: scored.filter(\.passed).count,
            stoppedForCap: stopped, sent: SentScan(rows: sentLog.count, walledWordHits: Array(Set(hits)).sorted(),
                                                   keyShaped: keyShaped),
            questions: results
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let name = "\(report.date)-\(report.world)-\(report.policy)\(options.dry ? "-dry" : "").json"
        try encoder.encode(report).write(to: options.outDir.appendingPathComponent(name), options: .atomic)
        print("TESS-EVAL \(name): \(report.passed)/\(scored.count) passed, spent \(spent) nano")
        if options.policy == .strict {
            #expect(report.sent.walledWordHits.isEmpty && report.sent.keyShaped == 0)
        }
    }

    static func milliseconds(_ duration: Duration) -> Int {
        Int(duration.components.seconds * 1000 + duration.components.attoseconds / 1_000_000_000_000_000)
    }

    @Test func theAllowanceIsTheSmallerOfFiftyAndWhatTheCapLeaves() {
        #expect(Self.allowanceNano(phoneSpentDollars: 0, runnerSpentNano: 0) == 50_000_000_000)
        #expect(Self.allowanceNano(phoneSpentDollars: 70, runnerSpentNano: 0) == 30_000_000_000)
        #expect(Self.allowanceNano(phoneSpentDollars: 0, runnerSpentNano: 20_000_000_000) == 30_000_000_000)
        #expect(Self.allowanceNano(phoneSpentDollars: 99.5, runnerSpentNano: 1) == 499_999_999)
        #expect(Self.allowanceNano(phoneSpentDollars: 100, runnerSpentNano: 0) == 0)
    }
}

/// The Mac keychain, read through the same item the app uses. Never printed.
enum TessUsageLedgerKeys {
    static func make() -> any TessKeychain {
        SystemKeychain()
    }
}
