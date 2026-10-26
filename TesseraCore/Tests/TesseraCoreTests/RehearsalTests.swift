import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Tess tries it first (docs/ai/harness/rehearsal.md): the copy, the diff, the checks and the wall.
@MainActor
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

    func task(_ json: String) -> Rehearsal.Call {
        Rehearsal.Call(name: "createTask", json: json)
    }

    @Test func theRealStoreIsByteForByteUnchangedAndNoObserverFires() throws {
        try engine.perform(CreateTask(title: "Existing"), by: .user)
        try store.context.save()
        var heard = 0
        engine.observe { _ in heard += 1 }
        let before = fingerprint()
        let rehearsal = Rehearsal(engine: engine)
        let result = rehearsal.try([task(#"{"title":"Call the bank","due":null}"#),
                                    Rehearsal.Call(name: "createList", json: #"{"name":"Packing"}"#)])
        #expect(result.passed && result.diff.count == 2)
        #expect(fingerprint() == before)
        #expect(heard == 0)
        #expect(!store.context.hasChanges)
    }

    @Test func theDiffNamesWhatWouldChangeAndTheRealRunMatchesIt() throws {
        let result = Rehearsal(engine: engine).try([task(#"{"title":"Call the bank","due":null}"#)], expecting: 1)
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
        let refused = Rehearsal(engine: engine).try([Rehearsal.Call(name: "noSuchTool", json: "{}")])
        #expect(!refused.passed && refused.receipts.first?.refused == true)
        let wrongCount = Rehearsal(engine: engine).try([task(#"{"title":"One","due":null}"#)], expecting: 5)
        #expect(wrongCount.failed.contains(.count(expected: 5, got: 1)))
    }

    @Test func aPrivateThingIsItsLabelAndMoneyAndBodyAreDeviceOnly() throws {
        let note = Rehearsal(engine: engine).try([Rehearsal.Call(name: "createNote",
                                                                 json: #"{"body":"Lexapro refill at 5"}"#)])
        let made = try #require(note.diff.first)
        #expect(made.name == ObjectPrivacy.noteLabel && made.details.isEmpty && made.taint == .deviceOnly)
        #expect(!note.text.contains("Lexapro"))
        let spend = Rehearsal(engine: engine).try([Rehearsal.Call(
            name: "logSpend", json: #"{"amount":12,"note":"lunch"}"#
        )])
        #expect(spend.diff.allSatisfy { $0.taint == .deviceOnly })
        #expect(spend.fragments.filter { $0.taint == .deviceOnly }.count == spend.diff.count)
    }

    @Test func aMoneyToolOffThePhoneIsAFailedCheck() {
        let result = Rehearsal(engine: engine).try(
            [Rehearsal.Call(name: "logSpend", json: #"{"amount":12,"note":"x"}"#)],
            onDevice: false
        )
        #expect(result.failed.contains(.moneyOffPhone("logSpend")) && result.diff.isEmpty)
    }

    @Test func aSliceKeepsAnAgentOutOfAnotherRoomsThings() {
        let galley = MemoryScope(AgentSpec.kitchen, policy: .lab)
        let result = Rehearsal(engine: engine).try([task(#"{"title":"Call the bank","due":null}"#)], scope: galley)
        #expect(result.failed.contains(.outOfScope("Call the bank")))
    }

    @Test func threeTriesAnAskAndNoRehearsingARehearsal() {
        let rehearsal = Rehearsal(engine: engine)
        for index in 1 ... 3 {
            #expect(rehearsal.try([task(#"{"title":"Try \#(index)","due":null}"#)]).passed)
        }
        #expect(!rehearsal.try([task(#"{"title":"Fourth","due":null}"#)]).passed)
        let nested = Rehearsal(engine: engine).try([Rehearsal.Call(name: "rehearse", json: "{}")])
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
