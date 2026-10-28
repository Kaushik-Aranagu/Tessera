import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Tess coordinates (docs/ai/harness/agents.md, section 6): she asks a room agent, it answers as itself from its own
/// context and tools, its report is kept as its episode so the next run starts from it, and only she may ask.
@MainActor
@Suite(.oldWalls)
struct AgentDeskTests {
    let helper = TessRunTests()

    func systemText(_ request: BrainRequest) -> String {
        request.system.map(\.text).joined(separator: "\n")
    }

    @Test func tessAsksTheDeckAndAnswersInHerOwnVoice() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [
            [helper.use("t1", TessRun.askAgent, #"{"agents":["Deck"],"question":"How was bench this week?"}"#)],
            [.text("Up two and a half plates, three clean sets.")],
            [.text("The Deck says bench is up two and a half plates.")],
        ])
        let r = try helper.rig([.haiku: haiku])
        let events = await helper.collect(r.run.ask("how was bench this week"))
        #expect(events.last == .finished("The Deck says bench is up two and a half plates"))
        // The Deck ran as itself: its personality, its tools, and no way to ask another room.
        let seen = haiku.requestsSeen
        #expect(seen.count == 3)
        let deck = seen[1]
        #expect(systemText(deck).contains(Persona.deck) && !systemText(deck).contains(TessRun.voice))
        let deckTools = Set(deck.tools.map(\.name))
        #expect(!deckTools.contains(TessRun.askAgent) && deckTools.contains("recall") && deckTools.contains("logSet"))
        // Its words reached Tess, not him: only her reply streamed.
        #expect(!events.contains(.words("Up two and a half plates, three clean sets.")))
        // The report is the Deck's episode, and its next run starts from it.
        let kept = AgentEpisodes(engine: r.engine).recent(agent: "Training", policy: .lab)
        #expect(kept.last?.report == "Up two and a half plates, three clean sets.")
        let next = AgentContext.blocks(for: .training, engine: r.engine, policy: .lab)
        #expect(next[1].text.contains("Up two and a half plates, three clean sets."))
    }

    @Test func onlyTessAsksTheRooms() async throws {
        let r = try helper.rig([.haiku: ScriptedBrain(.haiku, rounds: [])])
        r.run.agent = .training
        let input = Data(#"{"agents":["Galley"],"question":"What's for dinner?"}"#.utf8)
        let refused = await r.run.askAgents(input, handles: [:], onDevice: false)
        #expect(refused.isError && refused.text == "Only Tess asks the rooms.")
    }

    @Test func anUnknownRoomListsTheRoomsThereAre() async throws {
        let r = try helper.rig([.haiku: ScriptedBrain(.haiku, rounds: [])], policy: .strict)
        let input = Data(#"{"agents":["Attic"],"question":"Anything?"}"#.utf8)
        let answer = await r.run.askAgents(input, handles: [:], onDevice: false)
        #expect(answer.isError && answer.text.contains("Deck") && answer.text.contains("Galley"))
        // Strict has no Purse or Body to ask.
        #expect(!answer.text.contains("Purse") && !answer.text.contains("Body"))
    }

    @Test func atMostThreeRoomsAtOnce() async throws {
        let haiku = ScriptedBrain(.haiku, rounds: [[.text("a")], [.text("b")], [.text("c")], [.text("d")]])
        let r = try helper.rig([.haiku: haiku])
        let input = Data(#"{"agents":["Deck","Galley","Log","Watch"],"question":"Anything new today?"}"#.utf8)
        let answer = await r.run.askAgents(input, handles: [:], onDevice: false)
        #expect(!answer.isError && answer.text.split(separator: "\n").count == AgentSpec.tess.maxChildren)
        #expect(answer.text.contains("Deck:") && !answer.text.contains("Watch:"))
    }
}
