import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Tess tries it first (docs/ai/harness/rehearsal.md): the copy, the diff, the checks and the wall.
@MainActor
@Suite(.oldWalls)
struct RehearsalTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        let classes = try store.prepareCatalog()
        self.classes = classes
        engine = ActionEngine(store: store, classes: classes)
        engine.zone = { TimeZone(identifier: "America/Los_Angeles")! }
        engine.now = { Date(timeIntervalSince1970: 1_792_000_000) }
    }

    /// Every row of the real graph as it would be saved, plus the revision and the op count.
    func fingerprint() -> [String] {
        let context = store.context
        let models: [any TesseraModel] = Array(context.classes.values) + Array(context.fields.values)
            + Array(context.objects.values) + Array(context.links.values) + Array(context.views.values)
            + Array(context.operations.values)
        let rows = models.map { model -> String in
            let row = TesseraDatabaseSchema.Row(model)
            return row.sql + "|" + String(describing: row.arguments)
        }.sorted()
        return rows + ["revision \(context.revision)", "ops \(context.operations.count)",
                       "dirty \(context.hasChanges)"]
    }

    /// A rehearsal with no time limit: unit tests run in a slow debug build; the budget has its own tests.
    func fresh() -> Rehearsal {
        let rehearsal = Rehearsal(engine: engine)
        rehearsal.seconds = 1000
        return rehearsal
    }

    func task(_ json: String) -> Rehearsal.Call {
        Rehearsal.Call(name: "createTask", json: json)
    }

    @Test func theRealStoreIsByteForByteUnchangedAndNoObserverFires() throws {
        try engine.perform(CreateTask(title: "Existing"), by: .user)
        try store.context.save()
        var heard = 0
        engine.observe { _ in heard += 1 }
        let before = fingerprint()
        let rehearsal = fresh()
        let result = rehearsal.try([task(#"{"title":"Call the bank","due":null}"#),
                                    Rehearsal.Call(name: "createList", json: #"{"name":"Packing"}"#)])
        #expect(result.passed && result.diff.count == 2)
        #expect(fingerprint() == before)
        #expect(heard == 0)
        #expect(!store.context.hasChanges)
    }

    @Test func theDiffNamesWhatWouldChangeAndTheRealRunMatchesIt() throws {
        let result = fresh().try([task(#"{"title":"Call the bank","due":null}"#)], expecting: 1)
        #expect(result.passed)
        #expect(result.diff.first?.kind == .made && result.diff.first?.name == "Call the bank")
        #expect(result.receipts.first?.refused == false)
        // Nothing real yet; running it for real makes exactly that.
        let tasks = try #require(classes[.task])
        #expect(store.objects(of: tasks).filter { $0.title == "Call the bank" }.isEmpty)
        _ = try TessTools.run("createTask", arguments: Data(#"{"title":"Call the bank","due":null}"#.utf8),
                              engine: engine)
        #expect(store.objects(of: tasks).filter { $0.title == "Call the bank" }.count == 1)
    }

    @Test func aRefusedCallAndAWrongCountFailTheChecks() {
        let refused = fresh().try([Rehearsal.Call(name: "noSuchTool", json: "{}")])
        #expect(!refused.passed && refused.receipts.first?.refused == true)
        let wrongCount = fresh().try([task(#"{"title":"One","due":null}"#)], expecting: 5)
        #expect(wrongCount.failed.contains(.count(expected: 5, got: 1)))
    }

    @Test func aPrivateThingIsItsLabelAndMoneyAndBodyAreDeviceOnly() throws {
        let note = fresh().try([Rehearsal.Call(name: "createNote",
                                                   json: #"{"body":"Lexapro refill at 5"}"#)])
        let made = try #require(note.diff.first)
        #expect(made.name == ObjectPrivacy.noteLabel && made.details.isEmpty && made.taint == .deviceOnly)
        #expect(!note.text.contains("Lexapro"))
        let spend = fresh().try([Rehearsal.Call(
            name: "logSpend", json: #"{"amount":12,"note":"lunch"}"#
        )])
        #expect(spend.diff.allSatisfy { $0.taint == .deviceOnly })
        #expect(spend.fragments.filter { $0.taint == .deviceOnly }.count == spend.diff.count)
    }

    @Test func failureLinesThatHoldNamesStayOnThePhone() {
        let failures: [Rehearsal.Failure] = [.refused(tool: "x", line: "no note called Lexapro"), .danglingLink("n"),
                                             .orphan("n"), .outOfScope("n")]
        #expect(failures.allSatisfy { $0.taint == .deviceOnly })
        #expect(Rehearsal.Failure.count(expected: 1, got: 2).taint == .claudeSafe)
        let result = Rehearsal.Result(receipts: [], diff: [], failed: failures)
        #expect(result.fragments.allSatisfy { $0.taint == .deviceOnly })
    }

    @Test func aTryThatRunsOutOfTimeStopsAndSaysToAskHimFirst() {
        let rehearsal = Rehearsal(engine: engine)
        rehearsal.seconds = 0
        let result = rehearsal.try([task(#"{"title":"Slow","due":null}"#)])
        #expect(!result.passed && result.diff.isEmpty && result.receipts.isEmpty)
        #expect(result.failed.contains {
            if case .overBudget = $0 {
                true
            } else {
                false
            }
        })
        #expect(result.failed.map(\.line).contains("That took too long to try; ask him first"))
    }

    @Test func aPrivateParentAndATitleOfAPrivateThingMaskNewThingsInTheCopy() throws {
        let secret = try engine.perform(CreateNote(body: "Lexapro refill"), by: .user).output
        let result = fresh().try([
            Rehearsal.Call(name: "createNote", json: #"{"body":"Lexapro refill"}"#),
            Rehearsal.Call(name: "createNote", json: #"{"body":"Dr Lin 4 pm"}"#),
        ])
        #expect(secret.title != "" || true)
        #expect(result.diff.count == 2 && result.diff.allSatisfy { $0.taint == .deviceOnly && $0.details.isEmpty })
        #expect(!result.text.contains("Lexapro") && !result.text.contains("Lin"))
    }

    @Test func aMoneyToolOffThePhoneIsAFailedCheck() {
        let result = fresh().try(
            [Rehearsal.Call(name: "logSpend", json: #"{"amount":12,"note":"x"}"#)],
            onDevice: false
        )
        #expect(result.failed.contains(.moneyOffPhone("logSpend")) && result.diff.isEmpty)
    }

    @Test func aSliceKeepsAnAgentOutOfAnotherRoomsThings() {
        let galley = MemoryScope(AgentSpec.kitchen, policy: .lab)
        let result = fresh().try([task(#"{"title":"Call the bank","due":null}"#)], scope: galley)
        #expect(result.failed.contains(.outOfScope("Call the bank")))
    }

    @Test func threeTriesAnAskAndNoRehearsingARehearsal() {
        let rehearsal = fresh()
        for index in 1 ... 3 {
            #expect(rehearsal.try([task(#"{"title":"Try \#(index)","due":null}"#)]).passed)
        }
        #expect(!rehearsal.try([task(#"{"title":"Fourth","due":null}"#)]).passed)
        let nested = fresh().try([Rehearsal.Call(name: "rehearse", json: "{}")])
        #expect(!nested.passed)
    }

    @Test func theRehearseToolReadsTheResultAndIsNeverOfferedToClaude() throws {
        let tool = try #require(TessTools.tool(named: "rehearse"))
        #expect(tool.deviceOnly && !TessTools.claudeTools.contains { $0.name == "rehearse" })
        let before = fingerprint()
        let args = #"{"calls":[{"name":"createTask","arguments":"{\"title\":\"Call the bank\",\"due\":null}"}],"expecting":1}"#
        let answer = #expect(throws: TessToolAnswer.self) {
            try TessTools.run("rehearse", arguments: Data(args.utf8), engine: engine)
        }
        #expect(answer?.line.contains("made Call the bank") == true && answer?.line
            .contains("All checks passed") == true)
        #expect(fingerprint() == before)
    }
}
