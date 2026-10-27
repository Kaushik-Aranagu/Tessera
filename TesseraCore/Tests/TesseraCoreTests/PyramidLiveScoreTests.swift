import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The live P1b score (docs/ai/harness/memory-pyramid.md). It does nothing unless `TESSERA_PYRAMID_SCORE=1`; run it
/// with `scripts/ai/pyramid-score.sh`, which sets the rest. With `TESSERA_PYRAMID_DRY=1` a scripted brain answers and
/// nothing leaves the Mac.
///
/// It writes the gists Haiku makes for the test world's last months, then asks every question three ways (flat, zoom,
/// zoom with gists) and writes `eval-runs/<date>-pyramid-<policy>.json`.
///
/// Walls, the same as the live runner's: a test store in memory, never his; the key is read from the Mac keychain by
/// the Claude brain and never printed or written; the month's allowance is the smaller of $50 and $100 minus what the
/// phone spent, minus what the runners spent this month in the one shared ledger file. The test store's ledger starts
/// with everything above the allowance already spent, so the Door refuses a call past it before it is sent.
@MainActor
struct PyramidLiveScoreTests {
    struct Answer: Codable {
        var arm: String
        var answer: String
        var passed: Bool
        var inTokens: Int
        var costNano: Int64
    }

    struct Question: Codable {
        var id: String
        var depth: String
        var path: String
        var ask: String
        var answers: [Answer]
    }

    struct ArmSummary: Codable {
        var arm: String
        var asked: Int
        var passed: Int
        var inTokens: Int
    }

    struct GistSummary: Codable {
        var nodes: Int
        var written: Int
        var sentences: Int
        var dropped: [String: Int]
        var wordsByLevel: [String: Int]
        var samples: [String]
    }

    struct Report: Codable {
        var date: String
        var policy: String
        var dry: Bool
        var months: Int
        var allowanceDollars: Double
        var spentNano: Int64
        var stoppedForCap: Bool
        var gists: GistSummary
        var arms: [ArmSummary]
        /// Zoom with gists at least as accurate as flat, with at most 70% of its input tokens.
        var passLine: Bool
        var walledHits: Int
        var keyShaped: Int
        var questions: [Question]
    }

    /// The runners' one ledger, shared with the live runner: not in the repo, not in the app's data.
    static var ledgerURL: URL {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/TessEval", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("ledger.json")
    }

    static func readLedger() -> [String: Int64] {
        (try? JSONDecoder().decode([String: Int64].self, from: Data(contentsOf: ledgerURL))) ?? [:]
    }

    /// Adds this run's new spend to the month as the file stands now, so another runner's rows are kept.
    static func addToLedger(_ nano: Int64, month: String) throws {
        guard nano > 0 else { return }
        var months = readLedger()
        months[month, default: 0] += nano
        try JSONEncoder().encode(months).write(to: ledgerURL, options: .atomic)
    }

    @Test func liveScore() async throws {
        let env = ProcessInfo.processInfo.environment
        guard env["TESSERA_PYRAMID_SCORE"] == "1" else { return }
        let dry = env["TESSERA_PYRAMID_DRY"] == "1"
        let policy: DoorPolicy = env["TESSERA_PYRAMID_POLICY"] == "lab" ? .lab : .strict
        let months = env["TESSERA_PYRAMID_MONTHS"].flatMap(Int.init) ?? 6
        let phone = env["TESSERA_PYRAMID_PHONE_SPENT"].flatMap(Double.init)
        let outDir = env["TESSERA_PYRAMID_OUT"].map { URL(fileURLWithPath: $0) }
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("eval-runs")
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let monthKey = TessSpendFile.monthKey(.now, calendar: .current)
        if !dry {
            try #require(phone != nil, "a live run needs --phone-spent (what the phone spent this month)")
        }
        let runnersSpent = dry ? 0 : Self.readLedger()[monthKey] ?? 0
        let ceiling = min(50.0, 100.0 - (phone ?? 0))
        let allowance = max(0, Int64(ceiling * 1_000_000_000) - runnersSpent)
        if !dry {
            try #require(allowance > 0, "the month's allowance for the runners is used up")
        }

        // A store in memory: never his, and gone when the run ends.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let ledger = TessUsageLedger(store: store, classes: classes)
        if !dry {
            ledger.record(use: .question, model: ClaudeBrain.Model.haiku.rawValue, input: 0, output: 0,
                          costNano: TessUsageLedger.capNano - allowance, latency: 0, outcome: "works", requestID: nil)
        }
        let runStart = Date.now
        let before = ledger.monthTotal(now: runStart)
        var recorded: Int64 = 0
        func settle() throws {
            guard !dry else { return }
            let spent = max(0, ledger.monthTotal(now: runStart) - before)
            try Self.addToLedger(spent - recorded, month: monthKey)
            recorded = spent
        }
        let router = BrainRouter { id in
            guard id == .haiku else { return nil }
            return dry ? ScriptedBrain(.haiku, rounds: []) : ClaudeBrain(model: .haiku)
        }
        let door = Door(ledger: ledger, sentLog: TessSentLog(store: store, classes: classes),
                        trace: RunTrace(url: nil), router: router, policy: { policy }, asksClaude: { true })
        door.now = { runStart }
        func capReached() -> Bool {
            !dry && ledger.monthTotal(now: runStart) >= TessUsageLedger.capNano - 1_000_000
        }

        let world = EvalWorld.make()
        let pyramid = MemoryPyramid(leaves: world.pyramidLeaves(), calendar: EvalWorld.calendar)
        let questions = PyramidScore.questions(world, months: months)

        // 1. Gists, bottom up, for the nodes the questions read and everything under them.
        let scope = Set(questions.map(\.path))
        let wanted = PyramidGists().stale(in: pyramid, policy: policy).filter { path in
            // What the questions read, everything under it, and the nodes above it short of the root.
            let under = scope.contains { path == $0 || path.hasPrefix($0 + "/") }
            let above = pyramid.nodes[path]?.level != .root && scope.contains { $0.hasPrefix(path + "/") }
            return under || above
        }
        let distiller = PyramidDistiller(door: door)
        var gists = PyramidGists()
        var stopped = false
        var summary = GistSummary(nodes: wanted.count, written: 0, sentences: 0, dropped: [:], wordsByLevel: [:],
                                  samples: [])
        for path in wanted {
            if capReached() {
                stopped = true
                break
            }
            if let gist = await distiller.distill(path, in: pyramid, gists: gists, policy: policy) {
                gists[path, gist.policy] = gist
                summary.written += 1
                summary.sentences += gist.sentences.count
                for drop in gist.dropped {
                    summary.dropped[drop.rawValue, default: 0] += 1
                }
                let level = pyramid.nodes[path]?.level.rawValue ?? "?"
                let words = gist.sentences.reduce(0) { $0 + $1.text.split(separator: " ").count }
                summary.wordsByLevel[level, default: 0] += words
                if summary.samples.count < 12, level != "day" || summary.samples.count < 4 {
                    summary.samples.append("\(path): " + gist.sentences.map(\.text).joined(separator: " "))
                }
            } else {
                summary.dropped["noGist", default: 0] += 1
            }
            try settle()
        }

        // 2. Every question, three ways.
        var results: [Question] = []
        for question in questions {
            var answers: [Answer] = []
            for arm in PyramidScore.Arm.allCases {
                if stopped || capReached() {
                    stopped = true
                    break
                }
                let job = DoorJob(name: "pyramid-score", ladder: [.haiku], request: PyramidScore.request(question),
                                  fragments: PyramidScore.context(question, arm: arm, pyramid: pyramid, gists: gists,
                                                                  policy: policy),
                                  validator: { PyramidScore.answer(from: $0) != nil })
                var answer = "", usage = BrainUsage()
                do {
                    for try await event in door.run(job) {
                        switch event {
                        case let .toolUse(_, name, input) where name == PyramidScore.toolName:
                            answer = PyramidScore.answer(from: input) ?? ""
                        case let .done(spent, _): usage = spent
                        default: break
                        }
                    }
                } catch {}
                answers.append(Answer(arm: arm.rawValue, answer: answer,
                                      passed: PyramidScore.score(question, answer: answer),
                                      inTokens: usage.inTokens + usage.cacheReadTokens + usage.cacheWriteTokens,
                                      costNano: usage.costNano))
                try settle()
            }
            results.append(Question(id: question.id, depth: question.depth.rawValue, path: question.path,
                                    ask: question.ask, answers: answers))
        }

        // 3. What was sent: under strict, no walled leaf's words and nothing key-shaped.
        let sentLog = TessSentLog(store: store, classes: classes)
        let walled = world.pyramidLeaves().filter { $0.taint == .deviceOnly }.map(\.text)
        var walledHits = 0, keyShaped = 0
        for entry in sentLog.entries() {
            let words = sentLog.words(of: entry)
            if policy == .strict, walled.contains(where: { words.contains($0) }) {
                walledHits += 1
            }
            if looksLikeClaudeKey(words) {
                keyShaped += 1
            }
        }

        try settle()
        let arms = PyramidScore.Arm.allCases.map { arm in
            let rows = results.flatMap(\.answers).filter { $0.arm == arm.rawValue }
            return ArmSummary(arm: arm.rawValue, asked: rows.count, passed: rows.count(where: \.passed),
                              inTokens: rows.reduce(0) { $0 + $1.inTokens })
        }
        let flat = arms.first { $0.arm == PyramidScore.Arm.flat.rawValue }
        let best = arms.first { $0.arm == PyramidScore.Arm.zoomWithGists.rawValue }
        let passLine = flat.flatMap { flat in
            best.map { $0.passed >= flat.passed && Double($0.inTokens) <= 0.7 * Double(flat.inTokens) }
        } ?? false
        let report = Report(
            date: String(ISO8601DateFormatter().string(from: .now).prefix(10)),
            policy: policy == .strict ? "strict" : "lab", dry: dry, months: months,
            allowanceDollars: Double(allowance) / 1_000_000_000, spentNano: recorded, stoppedForCap: stopped,
            gists: summary, arms: arms, passLine: passLine, walledHits: walledHits, keyShaped: keyShaped,
            questions: results
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let encoded = try encoder.encode(report)
        try #require(!looksLikeClaudeKey(String(decoding: encoded, as: UTF8.self)), "the report holds a key shape")
        let name = "\(report.date)-pyramid-\(report.policy)\(dry ? "-dry" : "").json"
        try encoded.write(to: outDir.appendingPathComponent(name), options: .atomic)
        let line = arms.map { "\($0.arm) \($0.passed)/\($0.asked) in \($0.inTokens) tokens" }.joined(separator: ", ")
        print("PYRAMID-SCORE \(name): \(line); gists \(summary.written)/\(summary.nodes); spent \(recorded) nano")
        #expect(walledHits == 0 && keyShaped == 0)
    }
}
