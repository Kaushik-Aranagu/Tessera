import Foundation
@testable import TesseraCore
@testable import TesseraTess
import Testing

/// M2 and memory scopes (docs/ai/harness/memory-scopes.md): each agent reads the shared memory through its own slice,
/// its notebook is its own, recall pages in what scores above the floor by path, a private thing reads by its label
/// only, and remember keeps a maybe only with evidence.
@MainActor
@Suite(.oldWalls)
struct RecallToolsTests {
    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine
    let now = Date(timeIntervalSince1970: 1_793_000_000)

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
    }

    func index(_ spec: AgentSpec = .tess, policy: DoorPolicy = .lab) -> MemoryIndex {
        MemoryIndex(engine: engine, scope: MemoryScope(spec, policy: policy))
    }

    func call(_ name: String, _ json: String, _ index: MemoryIndex, seeds: [UUID] = [])
        -> TessRecallTools.Result
    {
        TessRecallTools.run(name, arguments: Data(json.utf8), index: index, engine: engine, seeds: seeds, now: now)
    }

    // MARK: Scopes

    @Test func aRoomAgentReadsItsRoomAndTessReadsEveryRoom() throws {
        let task = try engine.perform(CreateTask(title: "Call the bank"), by: .user).output
        let note = try engine.perform(CreateNote(body: "Pack the charger", title: "Trip packing"), by: .user).output
        let notes = index(.notes)
        #expect(notes.path(of: note.id) != nil && notes.path(of: task.id) == nil)
        let tess = index()
        #expect(tess.path(of: note.id) != nil && tess.path(of: task.id) != nil)
        // A path outside the slice is nothing there, whatever the model asks for.
        let path = try #require(tess.path(of: task.id))
        #expect(call(TessRecallTools.links, "{\"path\":\"\(path)\"}", notes).isError)
    }

    @Test func strictKeepsMoneyBodyAndCalendarOutOfEverySlice() throws {
        for key in [SystemCatalog.Key.spend, .pool, .sleepNight, .stepsDay, .occasion] {
            let classDef = try #require(classes[key])
            #expect(!MemoryScope(.tess, policy: .strict).reads(classDef, classes: classes), "\(key)")
            #expect(MemoryScope(.tess, policy: .lab).reads(classDef, classes: classes), "\(key)")
        }
        // Her own bookkeeping is in no slice, under either policy.
        let turn = try #require(classes[.tessTurn])
        #expect(!MemoryScope(.tess, policy: .lab).reads(turn, classes: classes))
    }

    @Test func strictRecallsNoCalendarOrHealthThing() throws {
        // A calendar event's title is free text the Door's scan can't read: under strict it is in no slice at all.
        let eventClass = try #require(classes[.event])
        let event = try store.create(eventClass, title: "Dentist with Dr Rao")
        let sleepClass = try #require(classes[.sleepNight])
        let night = try store.create(sleepClass, title: "Short night")
        let strict = index(policy: .strict)
        #expect(strict.path(of: event.id) == nil && strict.path(of: night.id) == nil)
        let asked = call(TessRecallTools.recall, #"{"query":"dentist","kinds":"all","limit":5}"#, strict)
        #expect(asked.text == ContextPacker.nothingKeptLine)
        #expect(!strict.entries.values.contains { $0.digest.contains("Dentist") || $0.digest.contains("Short night") })
        // Lab carries them, as it does for the pack.
        #expect(index(policy: .lab).path(of: event.id) != nil)
    }

    @Test func aMixedCaseNotebookStillOwnsItsPages() {
        let scope = MemoryScope(agent: "Garden", classes: [], notebook: "/memories/Garden", policy: .lab)
        #expect(scope.owns("/memories/garden/beds.md") && scope.owns("/memories/Garden/beds.md"))
    }

    @Test func aNotebookBelongsToItsAgentOnly() {
        let deck = MemoryScope(.training, policy: .lab)
        #expect(deck.owns("/memories/training/lifts.md"))
        #expect(!deck.owns("/memories/kitchen/dishes.md"))
        #expect(!deck.owns("/memories/training/../kitchen/dishes.md"))
        #expect(!deck.owns("/memories/training"))
        #expect(MemoryScope.isNotebook("/memories/kitchen/dishes.md"))
    }

    // MARK: Recall

    @Test func recallFindsAThingByItsWordsAndWhatLinksToIt() throws {
        let trip = try engine.perform(CreateNote(body: "Towels, snacks", title: "Beach trip"), by: .user).output
        let task = try engine.perform(CreateTask(title: "Buy sunscreen", about: [trip.id]), by: .user).output
        _ = try engine.perform(CreateTask(title: "Call the bank"), by: .user)
        let tess = index()
        let result = call(TessRecallTools.recall, #"{"query":"beach trip","kinds":"all","limit":5}"#, tess)
        #expect(!result.isError)
        let tripPath = try #require(tess.path(of: trip.id)), taskPath = try #require(tess.path(of: task.id))
        #expect(result.text.contains(tripPath) && result.text.contains(taskPath))
        #expect(!result.text.contains("bank"))
        // Best first: the thing his words name, then what links to it.
        let first = try #require(result.text.split(separator: "\n").first)
        #expect(first.hasPrefix(tripPath))
    }

    @Test func nothingAboveTheFloorSaysSo() throws {
        _ = try engine.perform(CreateTask(title: "Call the bank"), by: .user)
        let result = call(TessRecallTools.recall, #"{"query":"quantum physics","kinds":"all","limit":5}"#, index())
        #expect(result.text == ContextPacker.nothingKeptLine)
    }

    @Test func aPrivateThingReadsByItsLabelOnly() throws {
        let note = try engine.perform(CreateNote(body: "Lexapro 10 mg", title: "Lexapro", isPrivate: true),
                                      by: .user).output
        let tess = index()
        let path = try #require(tess.path(of: note.id))
        #expect(!path.lowercased().contains("lexapro") && path.contains("private"))
        let all = tess.entries.values.map { $0.path + $0.digest }.joined()
        #expect(!all.lowercased().contains("lexapro"))
        // His walled word finds nothing: the slice only holds what can be shown.
        let result = call(TessRecallTools.recall, #"{"query":"lexapro","kinds":"all","limit":5}"#, tess)
        #expect(!result.text.lowercased().contains("lexapro"))
    }

    @Test func openReadsARecallPath() throws {
        let task = try engine.perform(CreateTask(title: "Water the plants"), by: .user).output
        let tess = index()
        let path = try #require(tess.path(of: task.id))
        let read = TessOpenTool.run(arguments: Data("{\"handle\":\"\(path)\",\"depth\":1}".utf8), handles: [:],
                                    engine: engine, policy: .lab, index: tess)
        #expect(!read.isError && read.text.contains("Water the plants"))
        // Outside the agent's slice, the same path reads as nothing.
        let outside = TessOpenTool.run(arguments: Data("{\"handle\":\"\(path)\",\"depth\":1}".utf8), handles: [:],
                                       engine: engine, policy: .lab, index: index(.notes))
        #expect(outside.isError)
    }

    // MARK: History and remember

    @Test func historyNamesTheActionsNeverTheTitles() throws {
        let task = try engine.perform(CreateTask(title: "Call the bank"), by: .user).output
        let tess = index()
        let path = try #require(tess.path(of: task.id))
        let result = call(TessRecallTools.history, "{\"path\":\"\(path)\"}", tess)
        #expect(!result.isError && result.text.contains("he: createTask"))
        #expect(!result.text.contains("Call the bank"))
    }

    @Test func rememberKeepsAMaybeOnlyWithEvidence() throws {
        let task = try engine.perform(CreateTask(title: "Water the plants"), by: .user).output
        let tess = index()
        let path = try #require(tess.path(of: task.id))
        let kept = call(TessRecallTools.remember,
                        "{\"words\":\"You water the plants on Sundays\",\"key\":\"pattern\",\"about\":null,"
                            + "\"evidence\":[\"\(path)\"]}", tess)
        #expect(!kept.isError && kept.ghosts.count == 1)
        #expect(engine.history(limit: 1).first?.state == .pending)
        let none = call(TessRecallTools.remember,
                        #"{"words":"You like rain","key":"prefers","about":null,"evidence":["/nowhere"]}"#, tess)
        #expect(none.isError && none.ghosts.isEmpty)
        let long = String(repeating: "word ", count: 20)
        let tooLong = "{\"words\":\"\(long)\",\"key\":\"fact\",\"about\":null,\"evidence\":[\"\(path)\"]}"
        #expect(call(TessRecallTools.remember, tooLong, tess).isError)
    }

    @Test func everyRecallToolHasAStrictSchemaAndASafeName() throws {
        let banned = ["delete", "remove", "send", "email", "share", "export", "forget", "erase"]
        for spec in TessRecallTools.specs {
            #expect(!banned.contains { spec.name.lowercased().contains($0) }, "\(spec.name)")
            let schema = try #require(JSONSerialization.jsonObject(with: spec.schema) as? [String: Any])
            #expect(schema["additionalProperties"] as? Bool == false, "\(spec.name)")
        }
        #expect(Set(TessRun.toolSpecs().map(\.name)).isSuperset(of: TessRecallTools.names))
    }
}
