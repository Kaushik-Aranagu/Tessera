import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// P2 of the memory pyramid (docs/ai/harness/memory-pyramid.md): `zoom` reads his past one node at a time, the picker
/// offers it on an ask about his past, the pack says how paths look, and her rung reads a node in the run.
@MainActor
struct TessZoomToolTests {
    let world = EvalWorld.make()

    var pyramid: MemoryPyramid {
        MemoryPyramid(leaves: world.pyramidLeaves(), calendar: EvalWorld.calendar)
    }

    func read(_ path: String, in pyramid: MemoryPyramid, policy: DoorPolicy = .lab) -> (text: String, isError: Bool) {
        let json = try? JSONSerialization.data(withJSONObject: ["path": path])
        return TessZoomTool.run(arguments: json ?? Data(), pyramid: pyramid, policy: policy)
    }

    // MARK: Reading

    @Test func aPathReadsItsNode() {
        let pyramid = pyramid
        let october = read("/time/2026/10", in: pyramid)
        #expect(!october.isError && october.text.hasPrefix("October 2026 (/time/2026/10)"), "\(october.text)")
        #expect(october.text == pyramid.zoom("/time/2026/10", policy: .lab).text)
        #expect(read("/time/2026/10/", in: pyramid).text == october.text)
        // The Door's policy decides what a node shows.
        #expect(read("/time/2026/10", in: pyramid, policy: .strict).text
            == pyramid.zoom("/time/2026/10", policy: .strict).text)
    }

    @Test func aMissingPathStepsUpToTheNearestNode() {
        let pyramid = pyramid
        let missing = read("/time/2026/13", in: pyramid)
        #expect(missing.isError && missing.text == "Nothing there. Try /time/2026", "\(missing.text)")
        #expect(read("/time/2026/10/40/leaf-x", in: pyramid).text == "Nothing there. Try /time/2026/10")
        #expect(read("October", in: pyramid).isError && read("", in: pyramid).text.hasPrefix("Say a path"))
        let empty = MemoryPyramid(leaves: [], calendar: EvalWorld.calendar)
        #expect(read("/time/2026", in: empty).text == "Nothing in his past yet")
    }

    @Test func theSpecTakesOnePath() throws {
        let schema = try #require(JSONSerialization.jsonObject(with: TessZoomTool.spec.schema) as? [String: Any])
        #expect(TessZoomTool.spec.name == "zoom" && schema["required"] as? [String] == ["path"])
        #expect(ToolInputCheck.problem(Data(#"{"path":"/time/2026"}"#.utf8), schema: TessZoomTool.spec.schema) == nil)
        #expect(ToolInputCheck.problem(Data(#"{"day":"/time/2026"}"#.utf8), schema: TessZoomTool.spec.schema) != nil)
        // The guide has its page, and the run digest knows it.
        #expect(TessGuide.book["/tools/zoom"] != nil && RunDigest.knownTools.contains(TessZoomTool.name))
    }

    // MARK: Offered and packed

    @Test func anAskAboutHisPastGetsZoom() {
        for ask in ["how many sets did I do last week", "when did I last cook chili", "what did I lift in October",
                    "how often have I run since june", "what did I eat yesterday"]
        {
            #expect(TessZoomTool.isAbout(ask), "\(ask)")
        }
        for ask in ["move it to friday", "add milk and eggs", "start", "open the last task", "plan my week please"] {
            #expect(!TessZoomTool.isAbout(ask), "\(ask)")
        }
        let frame = ElementLooksTests().deckFrame()
        let past = ToolPicker.pick("how many sets did I do in october", frame: frame)
        #expect(past.tools.contains(TessZoomTool.name) && past.tools.count <= ToolPicker.maxTools, "\(past.tools)")
        #expect(!ToolPicker.pick("plan my week please", frame: frame).tools.contains(TessZoomTool.name))
    }

    @Test func thePackSaysHowPathsLookOnlyWithZoom() throws {
        let helper = TessRunTests()
        let r = try helper.rig([:])
        let pyramid = pyramid
        r.run.pyramidSource = { pyramid }
        let frame = ElementLooksTests().deckFrame()
        let ask = "how many sets did I do in october"
        let past = ToolPicker.pick(ask, frame: frame)
        let pack = r.run.pack(about: [], screen: nil, withTools: true, frame: frame, pick: past, ask: ask)
        #expect(pack.tools.contains { $0.name == TessZoomTool.name })
        #expect(pack.fragments.contains { $0.text.hasPrefix(TessZoomTool.contentsLine) })
        let plain = ToolPicker.pick("plan my week please", frame: frame)
        let other = r.run.pack(about: [], screen: nil, withTools: true, frame: frame, pick: plain, ask: "plan my week")
        #expect(!other.fragments.contains { $0.text.hasPrefix(TessZoomTool.contentsLine) })
    }

    @Test func aSureRouterNamesWhereToStart() {
        let pyramid = pyramid
        let ask = "how many sets did I do in october"
        let terms = PyramidAsk.terms(ask, now: world.now, calendar: EvalWorld.calendar)
        let router = PyramidRouter(sure: 0)
        let steps = router.guess(terms, to: .day, in: pyramid, policy: .lab)
        let line = TessZoomTool.line(for: ask, pyramid: pyramid, router: router, policy: .lab, now: world.now,
                                     calendar: EvalWorld.calendar)
        #expect(line == TessZoomTool.contentsLine + ". Start at \(steps.last?.path ?? "")", "\(line)")
        // Never sure: the line only says how paths look.
        let unsure = TessZoomTool.line(for: ask, pyramid: pyramid, router: PyramidRouter(sure: 2), policy: .lab,
                                       now: world.now, calendar: EvalWorld.calendar)
        #expect(unsure == TessZoomTool.contentsLine)
    }

    @Test func herRungZoomsInTheRun() async throws {
        let helper = TessRunTests()
        let frame = ElementLooksTests().deckFrame()
        let ask = "how many sets did I do in october"
        let pick = ToolPicker.pick(ask, frame: frame)
        let use = helper.use("t1", TessZoomTool.name, #"{"path":"/time/2026/10"}"#)
        var brains: [BrainID: any Brain] = [:]
        var scripted: [ScriptedBrain] = []
        for id in pick.plan.ladder {
            let brain = ScriptedBrain(id, rounds: [[use], [.text("Plenty")]])
            brains[id] = brain
            scripted.append(brain)
        }
        let r = try helper.rig(brains, policy: .strict)
        let pyramid = pyramid
        r.run.pyramidSource = { pyramid }
        _ = await helper.collect(r.run.ask(ask, frame: frame))
        let results = scripted.flatMap(\.requestsSeen).flatMap { $0.messages.last?.content ?? [] }
            .compactMap { piece -> String? in
                if case let .toolResult(_, content, false) = piece { content } else { nil }
            }
        // Under strict, the node as strict reads it.
        #expect(results.contains(pyramid.zoom("/time/2026/10", policy: .strict).text), "\(results)")
    }
}
