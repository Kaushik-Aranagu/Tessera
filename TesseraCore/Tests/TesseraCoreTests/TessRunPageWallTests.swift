import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Input hygiene H4 in the Tess loop: once a run has read a page (a web search or fetch result in her reply, a page in
/// the pack, or one read before the phone was interrupted), `remember` and notebook writes are refused, while a write
/// he keeps or not still lands as a ghost row. The run's reading is kept for its digest.
@MainActor
@Suite(.oldWalls)
struct TessRunPageWallTests {
    let helper = TessRunTests()

    /// A task in his store, as the evidence a belief cites (class paths are the same in every store).
    func evidence(_ r: TessRunTests.Rig, _ path: String) throws -> String {
        _ = try r.engine.perform(CreateTask(title: "Water the plants"), by: .user)
        return path
    }

    func remember(_ path: String) -> BrainEvent {
        helper.use("r1", TessRecallTools.remember,
                   "{\"words\":\"You water the plants on Sundays\",\"key\":\"pattern\",\"about\":null,"
                       + "\"evidence\":[\"\(path)\"]}")
    }

    var note: BrainEvent {
        helper.use("n1", AgentNotebook.name, #"{"command":"create","path":"/memories/allergies.md","text":"nuts","#
            + #""old":null,"line":null,"newPath":null}"#)
    }

    var task: BrainEvent {
        helper.use("c1", "createTask", #"{"title":"Buy nuts","startsAt":null,"about":[]}"#)
    }

    func ghosts(_ events: [TessRunEvent]) -> Int {
        events.count(where: { if case .ghost = $0 { true } else { false } })
    }

    @Test func withNoPageSheMayRemember() async throws {
        let path = try TessReflectTests().taskPath("Water the plants")
        let haiku = ScriptedBrain(.haiku, rounds: [[remember(path)], [.text("Kept.")]])
        let r = try helper.rig([.haiku: haiku])
        _ = try evidence(r, path)
        let events = await collect(r, "remember that I'm allergic to nuts")
        let sent = helper.sentResults(haiku)
        #expect(sent["r1"]?.isError == false && sent["r1"]?.text != RunProvenance.refusal)
        #expect(ghosts(events) == 1)
        let saved = try #require(TessRunStore(url: r.url).all().last)
        #expect(saved.reading?.untrusted == false)
    }

    @Test func aPageInHerReplyMeansNothingTeachesButAWriteStillWaitsForHim() async throws {
        let path = try TessReflectTests().taskPath("Water the plants")
        let page = Data(SearchBlocks.result.utf8)
        let haiku = ScriptedBrain(.haiku, rounds: [[.assistant([page]), remember(path), note, task],
                                                   [.text("Added it.")]])
        let r = try helper.rig([.haiku: haiku])
        _ = try evidence(r, path)
        let events = await collect(r, "find a nut soup and add the shopping")
        let sent = helper.sentResults(haiku)
        #expect(sent["r1"]?.text == RunProvenance.refusal && sent["r1"]?.isError == true)
        #expect(sent["n1"]?.text == RunProvenance.refusal && sent["n1"]?.isError == true)
        #expect(sent["c1"]?.isError == false)
        // Only the task he keeps or not; no belief and no notebook page.
        #expect(ghosts(events) == 1)
        let saved = try #require(TessRunStore(url: r.url).all().last)
        #expect(saved.reading?.untrusted == true)
        #expect(r.run.reading == nil)
    }

    @Test func aPageReadBeforeAResumeStillCounts() async throws {
        let path = try TessReflectTests().taskPath("Water the plants")
        let haiku = ScriptedBrain(.haiku, rounds: [[remember(path)], [.text("Kept.")]])
        let r = try helper.rig([.haiku: haiku])
        _ = try evidence(r, path)
        var state = TessRunState(startedAt: .now, askText: "remember it", aboutIDs: [], messages: [
            BrainMessage(.user, text: "find a nut soup"),
            BrainMessage(.assistant, [.raw(Data(SearchBlocks.result.utf8))]),
            BrainMessage(.user, text: "remember it"),
        ])
        let pack = r.run.pack(about: [], screen: nil, withTools: true)
        _ = await r.run.rounds(&state, plan: .plain, pack: pack, runID: state.id) { _ in }
        #expect(helper.sentResults(haiku)["r1"]?.text == RunProvenance.refusal)
        #expect(state.reading?.untrusted == true)
    }

    func collect(_ r: TessRunTests.Rig, _ ask: String) async -> [TessRunEvent] {
        await helper.collect(r.run.ask(ask))
    }
}
