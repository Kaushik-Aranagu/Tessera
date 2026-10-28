import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The Chart room's 20-sentence eval. Offline: every golden answer is valid and has the shape the sentence calls for,
/// so the corpus itself is sound. Live (`TESSERA_ROOM_EVAL=1`, paid): each sentence goes to Claude through the room job
/// and must pass the validator and match its shape.
@MainActor
struct RoomEvalTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]

    init() throws {
        classes = try store.prepareCatalog()
        try RoomSample.seedPlants(store: store, classes: classes)
    }

    @Test func twentySentencesWithGoldensThatPassTheValidatorAndHaveTheirShape() {
        #expect(RoomEvalCorpus.cases.count == 20)
        let validator = RoomPatchValidator(store: store, classes: classes)
        for item in RoomEvalCorpus.cases {
            let start = RoomEvalCorpus.start(item)
            let patch = RoomPatch(room: "Chart room", say: "ok", ops: item.golden)
            let result = validator.validate(patch, against: start)
            guard case .ok = result else {
                Issue.record("\(item.sentence): \(result)")
                continue
            }
            #expect(RoomEvalCorpus.matches(patch, item), "\(item.sentence) has its shape")
        }
    }

    @Test func theRoomJobRequestCarriesTheKitTheClassesAndThePickedPlaceFirst() throws {
        let engine = ActionEngine(store: store, classes: classes)
        let steps = RoomFixture.chart.parts.map {
            RoomPatch.Step(op: "add", id: $0.id, kind: $0.kind, place: $0.place, props: $0.props, bind: $0.bind)
        }
        try engine.perform(PatchRoom(patch: RoomPatch(room: "Chart room", say: "x", ops: steps)), by: .tess)
        let request = RoomJob.request(sentence: "Make this calmer", room: "Chart room", picked: "keystone",
                                      lastTouched: ["the orchid"], engine: engine)
        let text = request.messages.first.flatMap { message -> String? in
            if case let .text(text)? = message.content.first {
                text
            } else {
                nil
            }
        } ?? ""
        #expect(text.contains("Parts (kind: places; props; what it is):") && text.contains("lastWatered (date)"))
        #expect(text.contains("He has picked the keystone place") && text.contains("He last touched: the orchid"))
        #expect(text.contains("He said: Make this calmer"))
        let roomSection = text.components(separatedBy: "Room Chart room").last ?? ""
        let firstPart = roomSection.components(separatedBy: "\n").first { $0.hasPrefix("- ") }
        #expect(firstPart?.contains("in keystone") == true, "the picked place's parts come first")
        #expect(request.tools.map(\.name) == ["patchRoom"] && request.tools.first?.strict == true)
    }

    @Test func theJobAppliesTheModelsPatchAndSendsOnePlainRejectionBack() async {
        let engine = ActionEngine(store: store, classes: classes)
        let bad = #"{"room":"Chart room","say":"x","ops":[{"op":"add","id":"t","kind":"title","place":"widget","#
            + #""props":"","bind":"","trait":"","value":"","reach":"","index":-1}]}"#
        let good = #"{"room":"Chart room","say":"Title, set","ops":[{"op":"add","id":"t","kind":"title","#
            + #""place":"title","props":"{\"text\":\"Plants\"}","bind":"","trait":"","value":"","reach":"","index":-1}]}"#
        let brain = ScriptedBrain(.haiku, rounds: [
            [.toolUse(id: "1", name: "patchRoom", input: Data(bad.utf8)), .done(BrainUsage(), stop: "tool_use")],
            [.toolUse(id: "2", name: "patchRoom", input: Data(good.utf8)), .done(BrainUsage(), stop: "tool_use")],
        ])
        let result = await RoomJob.run(sentence: "Make this my plant room", room: "Chart room", brain: brain,
                                       engine: engine)
        guard case let .applied(record, output) = result else {
            Issue.record("the second try applies: \(result)")
            return
        }
        #expect(record.state == .pending && output.say == "Title, set")
    }
}
