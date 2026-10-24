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
        slow.firstDelay = .seconds(5)
        slow.reply = "slow"
        quick.reply = "quick"
        let rig = try DoorRig(brains: [.sonnet: slow, .haiku: quick], hedgeAfter: .milliseconds(40))
        let events = await rig.events(job([.sonnet, .haiku], hedge: true))
        #expect(events.text == "quick")
        #expect(slow.streamCount == 1 && quick.streamCount == 1)
        // Both holds are released, and both calls left a row.
        #expect(rig.ledger.pendingNano == 0)
        #expect(rig.ledger.calls().count == 2)
    }

    @Test func noHedgeWhenSonnetAnswersInTime() async throws {
        let sonnet = FakeBrain(.sonnet), haiku = FakeBrain(.haiku)
        let rig = try DoorRig(brains: [.sonnet: sonnet, .haiku: haiku], hedgeAfter: .seconds(5))
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
}

@MainActor
final class HeldDuringSend {
    var value: Int64 = -1
}
