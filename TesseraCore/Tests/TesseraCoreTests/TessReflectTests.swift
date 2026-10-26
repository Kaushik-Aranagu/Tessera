import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// The 4 am reflection: a room agent looks back at its closing day as itself (its personality, open ladder, high
/// effort), keeps at most its cap of maybes through remember with evidence, and what it said becomes its episode. No
/// items, no call; strict never shows it money or body things.
@MainActor
struct TessReflectTests {
    let helper = TessRunTests()
    let now = Date(timeIntervalSince1970: 1_793_000_000)

    /// The path a task with this title has in Bridge's slice (class paths are the same in every store).
    func taskPath(_ title: String) throws -> String {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        let engine = ActionEngine(store: store, classes: classes)
        let task = try engine.perform(CreateTask(title: title), by: .user).output
        let index = MemoryIndex(engine: engine, scope: MemoryScope(.today, policy: .lab))
        return try #require(index.path(of: task.id))
    }

    func remember(_ id: String, _ words: String, _ path: String) -> BrainEvent {
        helper.use(id, TessRecallTools.remember,
                   "{\"words\":\"\(words)\",\"key\":\"pattern\",\"about\":null,\"evidence\":[\"\(path)\"]}")
    }

    @Test func aReflectionKeepsAtMostItsCapAndBecomesAnEpisode() async throws {
        let path = try taskPath("Water the plants")
        let sonnet = ScriptedBrain(.sonnet, rounds: [
            [remember("r1", "You water the plants on Sundays", path), remember("r2", "You like mornings", path)],
            [.text("Kept one: plants on Sundays.")],
        ])
        let r = try helper.rig([.sonnet: sonnet])
        _ = try r.engine.perform(CreateTask(title: "Water the plants"), by: .user)
        let items = [NightPass.DayItem(kind: "task done", name: "Water the plants", at: now, room: "today")]
        let result = await r.run.reflect(.today, items: items, cap: 1)
        #expect(!result.failed && result.kept.count == 1 && result.report == "Kept one: plants on Sundays.")
        let seen = try #require(sonnet.requestsSeen.first)
        #expect(seen.system.map(\.text).joined().contains(Persona.bridge) && seen.effort == .high)
        let asked = seen.messages.flatMap(\.content).compactMap { piece -> String? in
            if case let .text(text) = piece { text } else { nil }
        }.joined()
        #expect(asked.contains("Water the plants") && asked.contains("at most 1"))
        let episode = AgentEpisodes(engine: r.engine).recent(agent: "Today", policy: .lab).last
        #expect(episode?.report == "Kept one: plants on Sundays." && episode?.ask.hasPrefix("Night") == true)
    }

    @Test func nothingToLookAtMeansNoCall() async throws {
        let sonnet = ScriptedBrain(.sonnet, rounds: [])
        let r = try helper.rig([.sonnet: sonnet], policy: .strict)
        let empty = await r.run.reflect(.today, items: [])
        #expect(empty.report.isEmpty && sonnet.requestsSeen.isEmpty)
        // Under strict a day of only spends and sleep has nothing to reflect on.
        let walled = [NightPass.DayItem(kind: "spend", name: "Lunch", at: now, room: "today"),
                      NightPass.DayItem(kind: "sleep", name: "", at: now, room: "today")]
        _ = await r.run.reflect(.today, items: walled)
        #expect(sonnet.requestsSeen.isEmpty)
    }
}
