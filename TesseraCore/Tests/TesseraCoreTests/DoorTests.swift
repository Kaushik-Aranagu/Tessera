import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Harness H1b: the Door's order of steps, the router, the hedge, the cap, the key scan and the two policies.
@MainActor
struct DoorTests {
    static let ask = BrainRequest(system: [TextBlock("Be brief.")], messages: [BrainMessage(.user, text: "Hi")])

    func job(_ ladder: [BrainID], fragments: [PackFragment] = [], hedge: Bool = false, estimate: Int64 = 100_000,
             validator: @escaping @Sendable (Data) -> Bool = { _ in true }) -> DoorJob
    {
        DoorJob(name: "test", ladder: ladder, request: Self.ask, fragments: fragments, estimateNano: estimate,
                hedge: hedge, validator: validator)
    }

    @Test func theRouterSkipsADownedRung() async throws {
        let down = FakeBrain(.sonnet), up = FakeBrain(.haiku)
        down.available = false
        let rig = try DoorRig(brains: [.sonnet: down, .haiku: up])
        let events = await rig.events(job([.sonnet, .haiku]))
        #expect(events.text == "ok" && events.finished)
        #expect(down.streamCount == 0 && up.streamCount == 1)
    }

    @Test func aFailureBeforeAnyWordFallsToTheNextRung() async throws {
        let bad = FakeBrain(.sonnet), good = FakeBrain(.haiku)
        bad.outcome = .busy
        let rig = try DoorRig(brains: [.sonnet: bad, .haiku: good])
        let events = await rig.events(job([.sonnet, .haiku]))
        #expect(events.text == "ok" && events.failure == nil)
        #expect(bad.streamCount == 1 && good.streamCount == 1)
    }

    @Test func theHedgeReturnsTheFirstStreamerAndSettlesBoth() async throws {
        let slow = FakeBrain(.sonnet), quick = FakeBrain(.haiku)
        // Never answers on its own (until cancelled): no clock decides which one streams first.
        slow.firstDelay = .seconds(3600)
        slow.reply = "slow"
        quick.reply = "quick"
        let rig = try DoorRig(brains: [.sonnet: slow, .haiku: quick], hedgeWait: .zero)
        let events = await rig.events(job([.sonnet, .haiku], hedge: true))
        #expect(events.text == "quick")
        #expect(slow.streamCount == 1 && quick.streamCount == 1)
        // Both holds are released, and both calls left a row.
        #expect(rig.ledger.pendingNano == 0)
        // The cancelled rung is recorded at what was held for it.
        let rows = rig.ledger.calls()
        #expect(rows.count == 2)
        #expect(rows.contains { rig.store.value("outcome", of: $0)?.stringValue == "cancelled"
                && rig.store.number("costNano", of: $0) == 100_000
        })
    }

    @Test func noHedgeWhenSonnetAnswersInTime() async throws {
        let sonnet = FakeBrain(.sonnet), haiku = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.sonnet: sonnet, .haiku: haiku], hedgeWait: nil)
        let events = await rig.events(job([.sonnet, .haiku], hedge: true))
        #expect(events.text == "ok" && haiku.streamCount == 0)
        #expect(rig.ledger.pendingNano == 0)
    }

    @Test func theReserveHappensBeforeTheSendAndTheSettleAfter() async throws {
        let brain = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.haiku: brain])
        let ledger = rig.ledger
        let held = HeldDuringSend()
        brain.onStream = { _ in
            Task { @MainActor in held.value = ledger.pendingNano }
        }
        _ = await rig.events(job([.haiku], estimate: 123_000))
        try await Task.sleep(for: .milliseconds(50))
        #expect(held.value == 123_000)
        #expect(ledger.pendingNano == 0 && ledger.calls().count == 1)
    }

    @Test func theCapRefusesBeforeAnyNetwork() async throws {
        let brain = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.haiku: brain])
        let events = await rig.events(job([.haiku], estimate: TessUsageLedger.capNano + 1))
        #expect(events.failure == .capReached)
        #expect(brain.streamCount == 0 && brain.warmCount == 0)
        // The cap also counts what was already spent this month.
        let spent = rig.ledger.record(use: .door, model: "claude-haiku-5-5", input: 1, output: 1,
                                      costNano: TessUsageLedger.capNano - 50, latency: 0.1, outcome: "works",
                                      requestID: nil, at: .now)
        #expect(spent != nil)
        let again = await rig.events(job([.haiku], estimate: 100_000))
        #expect(again.failure == .capReached && brain.streamCount == 0)
    }

    @Test func aCapRefusalFallsToTheDeviceRungWhenThereIsOne() async throws {
        let haiku = FakeBrain(.haiku), apple = FakeBrain(.appleOnDevice)
        apple.reply = "on the phone"
        let rig = try DoorRig(brains: [.haiku: haiku, .appleOnDevice: apple])
        let events = await rig.events(job([.haiku, .appleOnDevice], estimate: TessUsageLedger.capNano + 1))
        #expect(events.text == "on the phone" && haiku.streamCount == 0)
    }

    @Test func aKeyShapedStringInAnyFragmentIsRefusedUnderBothPolicies() async throws {
        let key = "sk-" + "ant-" + "api03-" + String(repeating: "Ab3x", count: 8)
        for policy in [DoorPolicy.lab, .strict] {
            let brain = FakeBrain(.haiku), apple = FakeBrain(.appleOnDevice)
            let rig = try DoorRig(brains: [.haiku: brain, .appleOnDevice: apple], policy: policy)
            let events = await rig.events(job([.haiku, .appleOnDevice],
                                              fragments: [PackFragment("fine"), PackFragment("my key is \(key)",
                                                                                             taint: .deviceOnly)]))
            #expect(events.failure == .refused, "\(policy)")
            #expect(brain.streamCount == 0 && apple.streamCount == 0 && rig.sent.entries().isEmpty)
            #expect(await !"\(rig.trace.all())".contains(key))
        }
    }

    @Test func strictKeepsDeviceOnlyOffClaudeAndLabKeepsItAndLogsTheExactWords() async throws {
        let fragments = [
            PackFragment("Steps: 8000 today"),
            PackFragment("Weight 82.4 kg, rent 1450", taint: .deviceOnly),
        ]
        let strictBrain = FakeBrain(.haiku)
        let strict = try DoorRig(brains: [.haiku: strictBrain], policy: .strict)
        _ = await strict.events(job([.haiku], fragments: fragments))
        let strictText = try Door.words(#require(strictBrain.lastRequest))
        #expect(strictText.contains("Steps: 8000") && !strictText.contains("82.4") && !strictText.contains("1450"))

        let labBrain = FakeBrain(.haiku)
        let lab = try DoorRig(brains: [.haiku: labBrain], policy: .lab)
        _ = await lab.events(job([.haiku], fragments: fragments))
        let labText = try Door.words(#require(labBrain.lastRequest))
        #expect(labText.contains("82.4") && labText.contains("1450"))
        // The sent log holds exactly those words, unmasked, once.
        let entries = lab.sent.entries()
        #expect(entries.count == 1)
        let words = lab.store.value("words", of: entries[0])?.stringValue ?? ""
        #expect(words.contains("Weight 82.4 kg, rent 1450"))
    }

    @Test func aDeviceRungAlwaysGetsEveryFragmentAndWritesNoSentRow() async throws {
        let apple = FakeBrain(.appleOnDevice)
        let rig = try DoorRig(brains: [.appleOnDevice: apple], policy: .strict)
        _ = await rig.events(job([.appleOnDevice], fragments: [PackFragment("Weight 82.4 kg", taint: .deviceOnly)]))
        #expect(try Door.words(#require(apple.lastRequest)).contains("82.4"))
        #expect(rig.sent.entries().isEmpty && rig.ledger.calls().isEmpty)
    }

    @Test func claudeIsNeverCalledWithTessAsksClaudeOff() async throws {
        let brain = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.haiku: brain], asks: false)
        let events = await rig.events(job([.haiku]))
        #expect(events.failure == .notAllowed && brain.streamCount == 0)
    }

    @Test func aToolCallTheValidatorRefusesIsAFailureOfThatRung() async throws {
        let bad = FakeBrain(.haiku), good = FakeBrain(.appleOnDevice)
        bad.toolInput = Data(#"{"count":99}"#.utf8)
        good.reply = "fallback"
        let rig = try DoorRig(brains: [.haiku: bad, .appleOnDevice: good])
        let events = await rig.events(job([.haiku, .appleOnDevice], validator: { _ in false }))
        #expect(events.text == "fallback")
        #expect(!events.contains {
            if case .toolUse = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func warmGoesThroughTheLedgerTheCapAndTheSwitch() async throws {
        let brain = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.haiku: brain])
        let result = await rig.door.warm(.haiku, Self.ask)
        #expect(result?.status == 200 && brain.warmCount == 1)
        #expect(rig.ledger.calls().count == 1 && rig.ledger.pendingNano == 0)
        // Over the cap, or with Tess asks Claude off, nothing is sent.
        rig.door.asksClaude = { false }
        #expect(await rig.door.warm(.haiku, Self.ask) == nil && brain.warmCount == 1)
    }

    @Test func noTraceSpanHoldsTextFromTheRequest() async throws {
        let brain = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.haiku: brain])
        _ = await rig.events(job([.haiku], fragments: [PackFragment("Weight 82.4 kg lantern", taint: .deviceOnly)]))
        let json = try await String(decoding: JSONEncoder().encode(rig.trace.all()), as: UTF8.self)
        #expect(!json.contains("82.4") && !json.contains("lantern") && !json.contains("Be brief"))
        #expect(await rig.trace.all().count == 1)
    }

    @Test func strictAlsoScansTheRequestsOwnWordsAndLogsInexactRows() async throws {
        let claude = FakeBrain(.haiku), apple = FakeBrain(.appleOnDevice)
        apple.reply = "kept home"
        let rig = try DoorRig(brains: [.haiku: claude, .appleOnDevice: apple], policy: .strict)
        let own = BrainRequest(system: [TextBlock("Be brief.")],
                               messages: [BrainMessage(.user, text: "I weighed in at 82.4 kg and ate 650 kcal")])
        let hit = await rig.events(DoorJob(name: "t", ladder: [.haiku, .appleOnDevice], request: own,
                                           estimateNano: 100_000))
        #expect(hit.text == "kept home" && claude.streamCount == 0 && rig.sent.entries().isEmpty)
        // A clean strict call is logged, as an inexact row (the normal masking applies to it).
        let clean = await rig.events(job([.haiku]))
        #expect(clean.text == "ok")
        let rows = rig.sent.entries()
        #expect(rows.count == 1 && rows[0].classDef?.systemKey == SystemCatalog.Key.tessSent.systemKey)
    }

    @Test func labRowsAreMirrorsInNoBackupAndNormalRowsAreNot() async throws {
        let rig = try DoorRig(brains: [.haiku: FakeBrain(.haiku)], policy: .lab)
        _ = await rig.events(job([.haiku], fragments: [PackFragment("Weight 82.4 kg", taint: .deviceOnly)]))
        let exact = try #require(rig.sent.entries().first)
        #expect(PrivateWords.isMirror(exact) && PrivateWords.isLocalOnly(exact))
        #expect(PrivateWords.mirrorIDs(in: rig.store.context).contains(exact.id))
        let plain = try #require(rig.sent.record(words: "hello", use: .door, requestID: nil, at: .now))
        #expect(!PrivateWords.isMirror(plain))
        // It still shows, exactly, in the sent list.
        #expect(rig.sent.shownWords(of: exact).contains("82.4 kg"))
    }

    @Test func moneyActionsAreNeverOfferedToAModel() async throws {
        for policy in [DoorPolicy.lab, .strict] {
            let brain = FakeBrain(.haiku)
            let rig = try DoorRig(brains: [.haiku: brain], policy: policy)
            var request = Self.ask
            request.tools = [ToolSpec(
                name: "logSpend",
                description: "Logs a spend",
                schema: Data(#"{"type":"object"}"#.utf8)
            )]
            let events = await rig.events(DoorJob(name: "t", ladder: [.haiku], request: request, estimateNano: 1000))
            #expect(events.failure == .refused && brain.streamCount == 0, "\(policy)")
        }
        for name in Door.moneyActions {
            #expect(ActionRegistry.descriptors.contains { $0.name == name }, "\(name)")
        }
    }

    @Test func theKeyScanAlsoCoversToolInputsAndToolDescriptions() async throws {
        let key = "sk-" + "ant-" + "api03-" + String(repeating: "Ab3x", count: 8)
        let brain = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.haiku: brain])
        var described = Self.ask
        described.tools = [ToolSpec(name: "x", description: "use \(key)", schema: Data("{}".utf8))]
        let first = await rig.events(DoorJob(name: "t", ladder: [.haiku], request: described, estimateNano: 1000))
        var replay = Self.ask
        replay.messages.append(BrainMessage(
            .assistant,
            [.toolUse(id: "1", name: "x", input: Data("{\"k\":\"\(key)\"}".utf8))]
        ))
        let second = await rig.events(DoorJob(name: "t", ladder: [.haiku], request: replay, estimateNano: 1000))
        #expect(first.failure == .refused && second.failure == .refused && brain.streamCount == 0)
    }
}

@MainActor
final class HeldDuringSend {
    var value: Int64 = -1
}
