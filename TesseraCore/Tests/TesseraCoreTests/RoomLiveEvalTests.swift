import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The live run of the Chart room's 20-sentence eval (`RoomEvalCorpus`). It does nothing unless `TESSERA_ROOM_EVAL=1`;
/// run it with `scripts/ai/room-eval.sh`, which sets the rest. With `TESSERA_ROOM_DRY=1` a scripted brain answers each
/// sentence with its golden patch and nothing leaves the Mac.
///
/// Every call goes through the Door (`DoorBrain`), never to a model directly: the policy (lab, his Oct 27 rule), the
/// key-shape scan, the $100 reserve before any network, the sent log and the ledger. Each sentence runs the real room
/// job (`RoomJob.run`, one retry on a plain rejection) on a test store in memory, never his, that starts from the
/// sentence's own room. It writes `eval-runs/<date>-room-<model>.json`.
///
/// The allowance is the pyramid score's: the smaller of $50 and $100 minus what the phone spent and the simulator's
/// reserved $20, minus what the runners spent this month in `TessEvalLedger`. The Door's ledger starts with everything
/// above it already spent, so the Door refuses a call past it before it is sent.
@MainActor
struct RoomLiveEvalTests {
    struct Row: Codable {
        var sentence: String
        /// applied, refused or noAnswer.
        var outcome: String
        /// The applied patch has every shape the sentence calls for.
        var shapeMatched: Bool
        /// A refusal's offer has the shape (Tess's nearest thing).
        var offerMatched: Bool
        var tries: Int
        var say: String
        var refusal: String?
        var queued: String?
        var ops: [String]
        var costNano: Int64
    }

    struct Report: Codable {
        var date: String
        var model: String
        var dry: Bool
        var allowanceDollars: Double
        var spentNano: Int64
        var stoppedForCap: Bool
        var asked: Int
        var applied: Int
        var shapeMatched: Int
        var keyShaped: Int
        var rows: [Row]
    }

    /// Passes events through and keeps every `patchRoom` input, so the run can read the patch the model sent.
    @MainActor
    final class Calls {
        var inputs: [Data] = []
    }

    struct Recording: Brain {
        let inner: any Brain
        let calls: Calls

        var id: BrainID {
            inner.id
        }

        var isAvailable: Bool {
            get async { await inner.isAvailable }
        }

        func stream(_ request: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error> {
            AsyncThrowingStream { continuation in
                let work = Task { @MainActor in
                    do {
                        for try await event in inner.stream(request) {
                            if case let .toolUse(_, name, input) = event, name == "patchRoom" {
                                calls.inputs.append(input)
                            }
                            continuation.yield(event)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { _ in work.cancel() }
            }
        }

        func warm(_: BrainRequest) async -> BrainWarm? {
            nil
        }
    }

    /// The tool input a golden patch is, as the strict `patchRoom` schema has it (every field, empty when unset).
    static func toolInput(_ steps: [RoomPatch.Step]) -> Data {
        let ops: [[String: Any]] = steps.map { step in
            ["op": step.op, "id": step.id ?? "", "kind": step.kind ?? "", "place": step.place ?? "",
             "props": step.props.map(RoomDocument.text) ?? "", "bind": step.bind ?? "", "trait": step.trait ?? "",
             "value": step.value ?? "", "reach": step.reach ?? "", "index": step.index ?? -1]
        }
        let object: [String: Any] = ["room": "Chart room", "say": "Done", "ops": ops]
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
    }

    /// A fresh store with the plants and the sentence's starting room, installed as one patch.
    static func startEngine(for item: RoomEvalCorpus.Case) throws -> ActionEngine {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        try RoomSample.seedPlants(store: store, classes: classes)
        let engine = ActionEngine(store: store, classes: classes)
        let start = RoomEvalCorpus.start(item)
        let steps = start.parts.map {
            RoomPatch.Step(op: "add", id: $0.id, kind: $0.kind, place: $0.place, props: $0.props, bind: $0.bind)
        } + start.look.sorted { $0.key < $1.key }.map { RoomPatch.Step(op: "look", trait: $0.key, value: $0.value) }
        if !steps.isEmpty {
            try engine.perform(PatchRoom(patch: RoomPatch(room: start.name, say: "Start", ops: steps)), by: .tess)
        }
        return engine
    }

    static func summary(_ step: RoomPatch.Step) -> String {
        [step.op, step.id, step.kind, step.place, step.trait, step.value].compactMap(\.self).joined(separator: " ")
    }

    @Test func theDryRunPassesEveryGoldenThroughTheDoorAndTheRoomJob() async throws {
        // The runner's own plumbing, free: the golden answers, scripted, must all apply and match through the Door.
        let rows = try await Self.run(model: .haiku, door: { brain in
            try DoorRig(brains: [.haiku: brain]).door
        }, capReached: { false })
        #expect(rows.count == RoomEvalCorpus.cases.count)
        for row in rows {
            #expect(row.outcome == "applied" && row.shapeMatched && row.tries == 1, "\(row.sentence): \(row)")
        }
    }

    @Test func liveEval() async throws {
        let env = ProcessInfo.processInfo.environment
        guard env["TESSERA_ROOM_EVAL"] == "1" else { return }
        let dry = env["TESSERA_ROOM_DRY"] == "1"
        let model: BrainID = env["TESSERA_ROOM_MODEL"] == "sonnet" ? .sonnet : .haiku
        let phone = env["TESSERA_ROOM_PHONE_SPENT"].flatMap(Double.init)
        let outDir = env["TESSERA_ROOM_OUT"].map { URL(fileURLWithPath: $0) }
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("eval-runs")
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let monthKey = TessSpendFile.monthKey(.now, calendar: .current)
        if !dry {
            try #require(phone != nil, "a live run needs --phone-spent (what the phone spent this month)")
        }
        let runnersSpent = dry ? 0 : TessEvalLedger.read()[monthKey] ?? 0
        let ceiling = min(50.0, 100.0 - (phone ?? 0) - PyramidLiveScoreTests.simulatorReserveDollars)
        let allowance = max(0, Int64(ceiling * 1_000_000_000) - runnersSpent)
        if !dry {
            try #require(allowance > 0, "the month's allowance for the runners is used up")
        }

        // The Door's own store: its ledger and sent log, in memory and gone when the run ends.
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let ledger = TessUsageLedger(store: store, classes: classes)
        if !dry {
            ledger.record(use: .question, model: ClaudeBrain.Model.haiku.rawValue, input: 0, output: 0,
                          costNano: TessUsageLedger.capNano - allowance, latency: 0, outcome: "works", requestID: nil)
        }
        let runStart = Date.now
        let before = ledger.monthTotal(now: runStart)
        let sentLog = TessSentLog(store: store, classes: classes)
        func throughDoor(_ scripted: any Brain) -> Door {
            let router = BrainRouter { id in
                guard id == model else { return nil }
                return dry ? scripted : ClaudeBrain(model: model == .sonnet ? .sonnet : .haiku)
            }
            let made = Door(ledger: ledger, sentLog: sentLog, trace: RunTrace(url: nil), router: router,
                            policy: { .lab }, asksClaude: { true })
            made.now = { runStart }
            return made
        }
        var recorded: Int64 = 0
        var stopped = false
        let rows = try await Self.run(model: model, door: throughDoor, spent: {
            ledger.monthTotal(now: runStart) - before
        }, capReached: {
            let reached = !dry && ledger.monthTotal(now: runStart) >= TessUsageLedger.capNano - 1_000_000
            stopped = stopped || reached
            return reached
        }, settle: { spent in
            guard !dry else { return }
            recorded = try TessEvalLedger.add(month: monthKey, spent: spent, recorded: recorded)
        })

        // Nothing key-shaped was sent.
        let keyShaped = sentLog.entries().count(where: { looksLikeClaudeKey(sentLog.words(of: $0)) })
        let report = Report(
            date: String(ISO8601DateFormatter().string(from: .now).prefix(10)), model: model.rawValue, dry: dry,
            allowanceDollars: Double(allowance) / 1_000_000_000, spentNano: recorded, stoppedForCap: stopped,
            asked: rows.count, applied: rows.count(where: { $0.outcome == "applied" }),
            shapeMatched: rows.count(where: \.shapeMatched), keyShaped: keyShaped, rows: rows
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let encoded = try encoder.encode(report)
        try #require(!looksLikeClaudeKey(String(decoding: encoded, as: UTF8.self)), "the report holds a key shape")
        let name = "\(report.date)-room-\(report.model)\(dry ? "-dry" : "").json"
        try encoded.write(to: outDir.appendingPathComponent(name), options: .atomic)
        print("ROOM-EVAL \(name): applied \(report.applied)/\(report.asked), shape \(report.shapeMatched)/"
            + "\(report.asked); spent \(recorded) nano")
        #expect(keyShaped == 0)
    }

    /// Every sentence through the room job on its own store, the model reached only through `door`.
    static func run(model: BrainID, door: (any Brain) throws -> Door, spent: () -> Int64 = { 0 },
                    capReached: () -> Bool, settle: (Int64) throws -> Void = { _ in }) async throws -> [Row]
    {
        var rows: [Row] = []
        for item in RoomEvalCorpus.cases {
            if capReached() {
                break
            }
            let engine = try startEngine(for: item)
            let scripted = ScriptedBrain(model, rounds: [[
                .toolUse(id: "golden", name: "patchRoom", input: toolInput(item.golden)),
                .done(BrainUsage(), stop: "tool_use"),
            ]])
            let calls = Calls()
            let inner = try DoorBrain(door: door(scripted), name: "room-eval", ladder: [model])
            let brain = Recording(inner: inner, calls: calls)
            let costBefore = spent()
            let result = await RoomJob.run(sentence: item.sentence, room: "Chart room", brain: brain, engine: engine)
            let sent = calls.inputs.last.flatMap(RoomJob.patch(from:))
            var row = Row(sentence: item.sentence, outcome: "noAnswer", shapeMatched: false, offerMatched: false,
                          tries: calls.inputs.count, say: sent?.say ?? "", refusal: nil, queued: nil,
                          ops: sent?.ops.map(summary) ?? [], costNano: spent() - costBefore)
            switch result {
            case let .applied(_, output):
                row.outcome = "applied"
                row.say = output.say
                row.shapeMatched = sent.map { RoomEvalCorpus.matches($0, item) } ?? false
            case let .refused(refusal, _):
                row.outcome = "refused"
                row.refusal = refusal.line
                row.queued = refusal.queue
                row.offerMatched = refusal.offer.map { RoomEvalCorpus.matches($0, item) } ?? false
            case .noAnswer:
                break
            }
            rows.append(row)
            try settle(spent())
        }
        return rows
    }
}

/// `DoorBrain` adds nothing and skips nothing: each request is a Door job, so it is logged, held against the cap and
/// refused when it holds a key, exactly as any other call.
@MainActor
struct DoorBrainTests {
    func collect(_ brain: any Brain, _ request: BrainRequest) async -> [BrainEvent] {
        var events: [BrainEvent] = []
        do {
            for try await event in brain.stream(request) {
                events.append(event)
            }
        } catch {}
        return events
    }

    func request(_ text: String) -> BrainRequest {
        BrainRequest(system: [TextBlock("Answer")], messages: [BrainMessage(.user, text: text)], maxTokens: 256)
    }

    @Test func aCallGoesThroughTheDoorsLedgerAndSentLog() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Hi"), .done(BrainUsage(costNano: 5000), stop: "end_turn")]])
        let rig = try DoorRig(brains: [.haiku: haiku])
        let events = await collect(DoorBrain(door: rig.door, name: "room-eval"), request("Say hi"))
        #expect(events.contains { if case .text("Hi") = $0 { true } else { false } }, "\(events)")
        #expect(haiku.requestsSeen.count == 1)
        #expect(rig.ledger.monthTotal(now: rig.door.now()) >= 5000 && rig.sent.entries().count == 1)
    }

    @Test func theCapAndTheKeyScanRefuseBeforeAnythingIsSent() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Hi"), .done(BrainUsage(), stop: "end_turn")]])
        let rig = try DoorRig(brains: [.haiku: haiku])
        let brain = DoorBrain(door: rig.door, name: "room-eval")
        let keyed = await collect(brain, request("my key " + "sk-" + "ant-" + "made-up-for-a-test-0123456789"))
        #expect(keyed.contains { if case .failed(.refused) = $0 { true } else { false } }, "\(keyed)")
        rig.ledger.record(use: .question, model: ClaudeBrain.Model.haiku.rawValue, input: 0, output: 0,
                          costNano: TessUsageLedger.capNano, latency: 0, outcome: "works", requestID: nil,
                          at: rig.door.now())
        let capped = await collect(brain, request("Say hi"))
        #expect(capped.contains { if case .failed(.capReached) = $0 { true } else { false } }, "\(capped)")
        #expect(haiku.requestsSeen.isEmpty && rig.sent.entries().isEmpty)
    }

    @Test func theHoldIsTheDearestRungsPriceForTheWholeMaxTokens() {
        let ask = request("Make this calmer")
        let haiku = DoorBrain.estimate(ask, on: [.haiku])
        #expect(haiku > 0 && DoorBrain.estimate(ask, on: [.haiku, .sonnet]) > haiku)
        #expect(DoorBrain.estimate(ask, on: [.appleOnDevice]) == 0)
    }
}
