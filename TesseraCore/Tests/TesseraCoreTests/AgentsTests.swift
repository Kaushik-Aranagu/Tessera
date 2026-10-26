import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// Persistent agents (docs/ai/harness/agents.md): the shipped agents become objects once, a new room spawns exactly
/// one agent, each agent's notebook is its own, its episodes carry it from run to run, and every run starts from its
/// personality and its memory through its walls.
@MainActor
struct AgentsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let now = Date(timeIntervalSince1970: 1_793_000_000)
    /// Key-shaped on purpose; no real key.
    let keyShaped = "sk-ant-" + "made-up-for-a-test"

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    func notebook(_ spec: AgentSpec, _ policy: DoorPolicy = .lab) -> AgentNotebook {
        AgentNotebook(engine: engine, scope: MemoryScope(spec, policy: policy), now: now)
    }

    // MARK: Registry

    @Test func theShippedAgentsBecomeObjectsOnce() throws {
        let registry = AgentRegistry(engine: engine)
        #expect(registry.sync(now: now) == AgentSpec.shipped.count)
        #expect(registry.sync(now: now) == 0)
        #expect(Set(registry.rows().map(\.title)) == Set(AgentSpec.shipped.map(\.title)))
        #expect(registry.agent("deck", under: .lab) == AgentSpec.training)
    }

    @Test func aNewRoomSpawnsOneAgentAndOnlyOne() throws {
        let registry = AgentRegistry(engine: engine)
        let book = try #require(classes[.book])
        let garden = try registry.spawn(room: "garden", title: "Garden", classIDs: [book.id], now: now)
        let again = try registry.spawn(room: "garden", title: "Garden", now: now)
        #expect(garden == again && garden.title == "Garden" && garden.notebook == "/memories/garden")
        #expect(garden.problems().isEmpty, "\(garden.problems())")
        #expect(registry.agents(under: .strict).count == AgentSpec.available(under: .strict).count + 1)
        // A shipped room already has its agent; a spawned name never takes a shipped one.
        #expect(throws: AgentRegistry.Refusal.self) { try registry.spawn(room: "training", title: "Gym", now: now) }
        let deck = try registry.spawn(room: "climbing", title: "Deck", now: now)
        #expect(deck.name == "Deck 2" && deck.notebook == "/memories/deck-2")
        // It reads its own kind and nothing of the other rooms.
        let scope = MemoryScope(garden, policy: .lab)
        #expect(scope.reads(book, classes: classes) && !scope.reads(classes[.task], classes: classes))
    }

    @Test func aPrivateRoomsAgentNeverCarriesItsName() throws {
        let registry = AgentRegistry(engine: engine)
        let therapy = try registry.spawn(room: "therapy", title: "Therapy", now: now)
        #expect(therapy.title == "Private room" && therapy.name == "Private room")
        #expect(!therapy.persona.lowercased().contains("therapy") && !therapy.room.contains("therapy"))
        #expect(!therapy.notebook.contains("therapy"))
        // The same room comes back as the same agent, by its room or its shown name.
        #expect(try registry.spawn(room: "therapy", title: "Therapy", now: now) == therapy)
        #expect(registry.agent("therapy", under: .lab) == therapy)
        // A second private room gets its own agent, numbered like any clash.
        let clinic = try registry.spawn(room: "clinic", title: "Clinic", now: now)
        #expect(clinic.name == "Private room 2" && clinic != therapy)
        // The room key is salted per install: a backup can't confirm a guessed name.
        let plain = Data(repeating: 0, count: 32)
        #expect(registry.key(for: "therapy") != AgentRegistry(engine: engine, roomSalt: plain).key(for: "therapy"))
        #expect(registry.key(for: "therapy") == therapy.room)
        // Nothing stored on the Agent objects names either room.
        for row in registry.rows() {
            let fields = ["agentName", "room", "persona", "notebook"]
            let stored = fields.compactMap { store.value($0, of: row)?.stringValue } + [row.title]
            #expect(!stored.contains { $0.lowercased().contains("therapy") || $0.lowercased().contains("clinic") })
        }
    }

    // MARK: Notebook

    @Test func aNotebookIsItsAgentsOwn() throws {
        let deck = notebook(.training)
        try deck.create("/memories/training/warmups.md", text: "He likes two ramp sets before bench.")
        #expect(deck.view(nil).contains("/memories/training/warmups.md: He likes two ramp sets"))
        #expect(notebook(.kitchen).view(nil) == "Your notebook is empty.")
        #expect(throws: AgentNotebook.Refusal.notYours) {
            try deck.create("/memories/kitchen/dishes.md", text: "x")
        }
        #expect(throws: AgentNotebook.Refusal.notYours) {
            try deck.create("/memories/training/../kitchen/dishes.md", text: "x")
        }
        try deck.replace("/memories/training/warmups.md", old: "two", new: "three")
        #expect(deck.view("/memories/training/warmups.md").contains("three ramp sets"))
        try deck.rename("/memories/training/warmups.md", to: "/memories/training/bench.md")
        try deck.remove("/memories/training/bench.md")
        #expect(deck.view(nil) == "Your notebook is empty.")
    }

    @Test func aNotebookKeepsNoKeyAndNoOversizePage() throws {
        let deck = notebook(.training)
        #expect(throws: AgentNotebook.Refusal.walled) {
            try deck.create("/memories/training/x.md", text: "remember \(keyShaped)")
        }
        #expect(throws: AgentNotebook.Refusal.tooLong) {
            try deck.create("/memories/training/x.md", text: String(repeating: "a", count: 4001))
        }
        for page in 1 ... AgentNotebook.maxPages {
            try deck.create("/memories/training/p\(page).md", text: "page \(page)")
        }
        #expect(throws: AgentNotebook.Refusal.full) { try deck.create("/memories/training/more.md", text: "x") }
    }

    @Test func aLabPageIsNeverReadUnderStrict() throws {
        try notebook(.training, .lab).create("/memories/training/sleep.md", text: "Short nights before heavy days.")
        #expect(notebook(.training, .strict).view(nil) == "Your notebook is empty.")
        // And strict never writes a twin of it.
        #expect(throws: AgentNotebook.Refusal.exists) {
            try notebook(.training, .strict).create("/memories/training/sleep.md", text: "x")
        }
    }

    @Test func theNotebookToolRunsCommands() throws {
        let deck = notebook(.training)
        let rest = #""old":null,"line":null,"newPath":null}"#
        let make = #"{"command":"create","path":"/memories/training/a.md","text":"Bench on Mondays","# + rest
        let made = deck.run(arguments: Data(make.utf8))
        #expect(made.text == "Saved." && !made.isError)
        let look = #"{"command":"view","path":"/memories/training","text":null,"# + rest
        #expect(deck.run(arguments: Data(look.utf8)).text.contains("Bench on Mondays"))
    }

    // MARK: Episodes and context

    @Test func episodesCarryAnAgentFromRunToRun() throws {
        let episodes = AgentEpisodes(engine: engine)
        episodes.append(agent: "Training", ask: "How was bench this week?", report: "Up 2.5 kg, three clean sets.",
                        lab: false, at: now.addingTimeInterval(-3600))
        episodes.append(agent: "Training", ask: "Store this: \(keyShaped)", report: "No.", lab: false,
                        at: now.addingTimeInterval(-1800))
        episodes.append(agent: "Training", ask: "Did sleep slow me down?", report: "Short nights, slower bar.",
                        lab: true, at: now.addingTimeInterval(-600))
        episodes.append(agent: "Kitchen", ask: "Dinner?", report: "Rice bowls.", lab: false, at: now)
        let lab = episodes.recent(agent: "Training", policy: .lab, now: now)
        #expect(lab.map(\.ask) == ["How was bench this week?", "Did sleep slow me down?"])
        let strict = episodes.recent(agent: "Training", policy: .strict, now: now)
        #expect(strict.map(\.report) == ["Up 2.5 kg, three clean sets."])
        // Ninety days on, they are gone for good.
        #expect(episodes.expire(now: now.addingTimeInterval(91 * 86400)) == 4)
    }

    @Test func everyRunStartsFromItsPersonalityAndItsMemory() throws {
        try notebook(.training).create("/memories/training/warmups.md", text: "Two ramp sets before bench.")
        AgentEpisodes(engine: engine).append(agent: "Training", ask: "How was bench?", report: "Up 2.5 kg.",
                                             lab: false, at: now.addingTimeInterval(-3600))
        let blocks = AgentContext.blocks(for: .training, engine: engine, policy: .lab, now: now)
        #expect(blocks.count == 2)
        #expect(blocks[0].text.hasPrefix(Persona.deck) && blocks[0].text.contains("You work for Tess"))
        #expect(blocks[1].text.contains("Two ramp sets") && blocks[1].text.contains("Up 2.5 kg."))
        // The Galley starts from its own memory, not the Deck's.
        let galley = AgentContext.blocks(for: .kitchen, engine: engine, policy: .lab, now: now)
        #expect(!galley[1].text.contains("ramp sets") && !galley[1].text.contains("2.5 kg"))
        let tess = AgentContext.blocks(for: .tess, engine: engine, policy: .lab, now: now)
        #expect(tess[0].text.contains("He talks to you"))
    }
}
