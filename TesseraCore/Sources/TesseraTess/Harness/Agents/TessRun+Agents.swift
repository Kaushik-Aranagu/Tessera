import Foundation
import TesseraCore

/// Tess coordinates (docs/ai/harness/agents.md, section 6): `ask_agent` lets her put one question to up to three room
/// agents at once. Each runs in parallel as itself: its own `AgentContext` (personality, notebook, beliefs, last
/// episodes), its own memory scope and its own tools, and none of them may ask another (agents reach each other only
/// through her). Each report is kept as that agent's episode, and she answers him in one voice. Their writes land as
/// ghost rows like hers.
extension TessRun {
    public static let askAgent = "ask_agent"
    /// The most a report keeps; she gets the gist, not an essay.
    public static let maxReport = 600

    static var askAgentSpec: ToolSpec {
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false, "required": ["agents", "question"],
            "properties": [
                "agents": [
                    "type": "array", "items": ["type": "string"],
                    "description": "Rooms to ask, 1 to 3: Bridge, Log, Deck, Galley, Watch, Lookout; Purse and Body "
                        + "under lab; or a room he made.",
                ],
                "question": [
                    "type": "string",
                    "description": "One self-contained question; the agents don't see his words or the screen.",
                ],
            ],
        ]
        return ToolSpec(name: askAgent, description: "Ask your room agents. Each answers from its own memory and "
            + "may make small changes; you answer him.",
            schema: (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])) ?? Data("{}".utf8))
    }

    struct AgentAnswer {
        var text: String
        var isError: Bool
        var ghosts: [UUID]
    }

    /// Runs `ask_agent`. Only an agent at the top of the tree (Tess) may ask, and at most its `maxChildren` rooms.
    func askAgents(_ input: Data, handles: [String: UUID], onDevice: Bool) async -> AgentAnswer {
        guard agent.depth == 0, agent.maxChildren > 0 else {
            return AgentAnswer(text: "Only Tess asks the rooms.", isError: true, ghosts: [])
        }
        guard let args = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any],
              let names = args["agents"] as? [String], let question = args["question"] as? String,
              !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return AgentAnswer(text: "Name the rooms and the question.", isError: true, ghosts: [])
        }
        let policy = door.policy()
        let registry = AgentRegistry(engine: engine)
        var picked: [AgentSpec] = []
        for name in names {
            guard let spec = registry.agent(name, under: policy), spec.name != agent.name,
                  !picked.contains(spec) else { continue }
            picked.append(spec)
        }
        guard !picked.isEmpty else {
            let rooms = registry.agents(under: policy).filter { $0.name != agent.name }.map(\.title)
            return AgentAnswer(text: "No such room here. Rooms: \(rooms.joined(separator: ", ")).", isError: true,
                               ghosts: [])
        }
        let rooms = Array(picked.prefix(agent.maxChildren))

        // In parallel: every room thinks at once, and the slowest one sets the wait. Main-actor tasks started
        // together and awaited in order (a task group's sendability check refuses this shape).
        let tasks = rooms.indices.map { position in
            Task { @MainActor in
                await self.runAgent(rooms[position], question: question, handles: handles, onDevice: onDevice)
            }
        }
        // Unstructured tasks don't inherit cancellation: a cancelled ask stops every room, so none keeps spending.
        let results = await withTaskCancellationHandler {
            var out: [(report: String, ghosts: [UUID], failed: Bool)] = []
            for task in tasks {
                out.append(await task.value)
            }
            return out
        } onCancel: {
            tasks.forEach { $0.cancel() }
        }

        let about = handles.values.compactMap { engine.store.object(id: $0) }
        let episodes = AgentEpisodes(engine: engine)
        var lines: [String] = []
        var ghosts: [UUID] = []
        for (spec, result) in zip(rooms, results) {
            lines.append("\(spec.title): \(result.report)")
            ghosts += result.ghosts
            if !result.failed {
                episodes.append(agent: spec.name, ask: question, report: result.report, about: about,
                                lab: policy == .lab, at: now())
            }
        }
        return AgentAnswer(text: lines.joined(separator: "\n"), isError: results.allSatisfy { $0.failed },
                           ghosts: ghosts)
    }

    /// One room agent's run: a child loop with the agent's own context, scope and tools, and no history but its own
    /// episodes (they are in its context). Its words never reach him; its report goes back to Tess.
    func runAgent(_ spec: AgentSpec, question: String, handles: [String: UUID],
                  onDevice: Bool) async -> (report: String, ghosts: [UUID], failed: Bool)
    {
        let child = TessRun(door: door, engine: engine, conversation: conversation, trace: trace,
                            runs: TessRunStore(url: nil))
        child.agent = spec
        child.now = now
        child.calendar = calendar
        child.flagOn = flagOn
        let system = AgentContext.blocks(for: spec, engine: engine, policy: door.policy(), now: now(),
                                         calendar: calendar)
        // The child's own tools only: never ask_agent, never a money write (AgentSpec.problems keeps both out).
        let tools = Self.toolSpecs(only: spec.tools.filter { $0 != Self.askAgent })
        let pack = Pack(system: system, cacheAfter: [CacheMark(0, .oneHour), CacheMark(1, .fiveMinutes)],
                        tools: tools, fragments: [], handles: handles)
        let plan: RungPlan = onDevice ? .deviceOnly : (RungPlan.pick(question) == .open ? spec.open : spec.plain)
        var state = TessRunState(startedAt: now(), askText: question, aboutIDs: Array(handles.values),
                                 messages: [BrainMessage(.user, text: question)])
        var ghosts: [UUID] = []
        let outcome = await child.rounds(&state, plan: plan, pack: pack, runID: state.id) { event in
            if case let .ghost(id) = event {
                ghosts.append(id)
            }
        }
        switch outcome {
        case let .reply(text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let report = trimmed.count > Self.maxReport ? String(trimmed.prefix(Self.maxReport - 1)) + "…" : trimmed
            return (report, ghosts, false)
        case let .phone(line):
            return ("No answer (\(line.isEmpty ? "stopped" : line))", ghosts, true)
        }
    }
}
