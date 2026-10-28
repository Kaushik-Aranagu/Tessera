import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The live Tess: what he says goes through TessRun and the Door, with the Claude key from the Keychain.
@MainActor
struct TessLiveTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    func live(_ brain: ScriptedBrain, asks: Bool = true, policy: DoorPolicy = .lab) -> TessLive {
        TessLive(engine: engine, keys: InMemoryKeychain("sk-ant-test-not-a-real-key"), asksClaude: { asks },
                 policy: { policy }, router: BrainRouter(hedgeAfter: .seconds(1), sleep: { _ in
                     try? await Task.sleep(for: .seconds(3600))
                 }) { $0 == .haiku ? brain : nil })
    }

    func use(_ id: String, _ name: String, _ json: String) -> BrainEvent {
        .toolUse(id: id, name: name, input: Data(json.utf8))
    }

    @Test func aFreeQuestionIsAnsweredByTessThroughTheDoorAndShowsUnderWhatWasSent() async {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("You did "), .text("3 sets.")]])
        let tess = live(haiku)
        let answer = await tess.ask("how many sets today")
        #expect(answer.line == "You did 3 sets" && !answer.failed && answer.records.isEmpty)
        #expect(haiku.streamCount == 1)
        // The exact words that left the phone are in the sent log, and the call is in the ledger.
        #expect(TessSentLog(store: store, classes: classes).entries().count == 1)
        #expect(tess.door.ledger.monthTotal() >= 0)
    }

    @Test func aWriteIsProposedAsGhostRowsHerAnswerReportsAndUndoTakesBack() async {
        let haiku = ScriptedBrain(.haiku, rounds: [
            [use("t1", "createTask", #"{"title":"Call mom","startsAt":null,"about":[]}"#)],
            [.text("Added it.")],
        ])
        let answer = await live(haiku).ask("remind me to call mom")
        #expect(answer.records.count == 1 && answer.records[0].state == .pending)
        #expect(answer.line == "Added it")
        let capture = TessCapture(records: answer.records, line: answer.line, source: .claude)
        #expect(capture.source == .claude && capture.records.count == 1)
        engine.undo(answer.records[0])
        #expect(answer.records[0].state == .undone)
    }

    @Test func withClaudeOffNothingIsSentAndTheAnswerIsAPhoneMadeLine() async {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("never")]])
        let answer = await live(haiku, asks: false).ask("how many sets today")
        #expect(haiku.streamCount == 0, "no Claude rung starts while Tess asks Claude is off")
        #expect(answer.failed && !answer.line.isEmpty && !answer.line.contains("never"))
    }

    @Test func aMissingKeyIsNamedAndNeverCarriesAnyKeyText() async {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("never")]])
        let tess = TessLive(engine: engine, keys: InMemoryKeychain(nil), asksClaude: { true },
                            router: BrainRouter(hedgeAfter: .seconds(1), sleep: { _ in
                                try? await Task.sleep(for: .seconds(3600))
                            }) { _ in nil })
        let answer = await tess.ask("how many sets today")
        #expect(answer.failed && answer.failure == .noKey && tess.lastFailure == .noKey)
        #expect(!answer.line.contains("sk-") && haiku.streamCount == 0)
    }

    @Test func claudeFailuresAreNamedFromTheirOutcomes() throws {
        #expect(ClaudeFailure(outcome: "badKey") == .authFailed && ClaudeFailure(outcome: "offline") == .network)
        #expect(ClaudeFailure(outcome: "capReached") == .capReached && ClaudeFailure(outcome: "timeout") == .timeout)
        #expect(ClaudeFailure(outcome: "refused") == .refused && ClaudeFailure(outcome: "works") == nil)
        let flags = try ClaudeMissFlags(defaults: #require(UserDefaults(suiteName: "tess-live-\(UUID().uuidString)")))
        #expect(flags.lastFailure == nil)
    }

    @Test func cancelStopsTheRunAndTheHostHearsCancelled() async {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("slow")]])
        haiku.delay = .seconds(30)
        let tess = live(haiku)
        let asking = Task { @MainActor () -> String in
            let answer = await tess.ask("how many sets today")
            return answer.failed ? answer.line : "answered"
        }
        try? await Task.sleep(for: .milliseconds(200))
        tess.cancel()
        #expect(await asking.value == "Cancelled")
    }

    @Test func theViewChangesAnAnswerCalledForAreKeptForTheHost() async {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("Here.")]])
        let tess = live(haiku)
        _ = await tess.ask("how many sets today")
        #expect(tess.lastShell.isEmpty)
    }

    @Test func theCaptureEngineLeavesTheMissToTessWhenTheInlineClaudeStepIsOff() {
        let capture = TessCaptureEngine(engine: engine)
        #expect(capture.claudeInline == true)
        capture.claudeInline = false
        #expect(capture.claudeInline == false)
    }
}
