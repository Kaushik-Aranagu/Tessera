import Foundation
import TesseraCore

/// H3: the Tess streaming loop. One `TessRun` object serves the layer; each ask is a run. The phone's capture grammar
/// gets the text first, and a phrase it can do never reaches here. Then `pickRung` chooses the smallest rung that fits,
/// the pack is built so the prefix caches, and up to three rounds of the Door run, with each tool started the moment
/// its
/// block closes. Every settled step is checkpointed so a kill never repeats a write.
@MainActor
public final class TessRun {
    /// Ten rounds (accuracy first); a paused turn does not use one.
    public static let maxRounds = 10
    public static let sameAskWindow: TimeInterval = 10
    public static let warmSpacing: TimeInterval = 240
    public static let warmWindow: TimeInterval = 2 * 3600
    /// Most times in one run a paused turn is sent back before she gives up.
    static let maxPauses = 5
    /// A run still marked running after this long is dropped on launch, not resumed.
    static let resumeWindow: TimeInterval = 600

    public static let tooManySteps = "That needed more steps than I take, try it in two"
    public static let cannotThink = "I can't think that through right now, the rest still works"
    public static let keyLine = "That looks like a key, so I won't send it"
    public static let noAnswer = "I couldn't get an answer just now, try again in a moment"

    /// Her voice and rules: fixed text, so the prefix caches (cache breakpoint after it).
    public static let voice = """
    You are Tess, the assistant inside Tessera, a personal app on one person's phone. Voice: brief, warm, a little dry. \
    Answer in a sentence or two unless asked for more, with no full stop at the end of a line. Use the tools to look \
    things up and to make small changes; a change you make, a money change too, is only proposed until the person \
    approves it. You never invent facts about the person's data: say you don't know. Objects in the pack have short \
    handles like o1; read one with open. Do not repeat the pack back.
    """

    public let door: Door
    public let engine: ActionEngine
    public let conversation: TessConversation
    public let trace: RunTrace
    public let runs: TessRunStore
    /// The memory profile block (shape A), changes about once a day. Empty means none.
    public var profile: @MainActor () -> String = { "" }
    /// Today's digest (Home's day facts), a plain line or two.
    public var dayDigest: @MainActor () -> String? = { nil }
    /// The flag `tessAsks`.
    public var flagOn: @MainActor () -> Bool = { true }
    public var now: () -> Date = { .now }
    public var calendar: Calendar = .current
    /// The shell's quiet stage (sheet 287, section 5): a look Tess picks is drawn off screen first and applied only
    /// if it passes. Nil until the host has one; then the shell's own check is the only gate.
    public var stage: LookStage?
    /// The most looks Tess tries off screen for one ask (rehearsal.md section 2): past that she asks him.
    nonisolated static let maxTries = 3

    /// The looks tried in the run in flight: how many tries are left, and the ones that passed, which `setLook`
    /// needn't stage again.
    struct LookTries {
        var runID: UUID
        var left = TessRun.maxTries
        var passed: Set<String> = []
    }

    private final class Active: @unchecked Sendable {
        let id = UUID()
        let text: String
        let startedAt: Date
        var task: Task<Void, Never>?
        var buffer: [TessRunEvent] = []
        var subscribers: [UUID: AsyncStream<TessRunEvent>.Continuation] = [:]
        var done = false
        /// A full stop held back from the live words: shown only if more words follow it (ShownLine).
        var heldStop = false

        init(text: String, startedAt: Date) {
            self.text = text
            self.startedAt = startedAt
        }
    }

    /// The agent this run speaks for (M4). Its memory scope decides what recall and open can reach (M2).
    public var agent: AgentSpec = .tess
    /// How many more beliefs `remember` may keep in this run; nil is no limit beyond the phrase's ghost budget. The
    /// 4 am reflection sets it (at most five a night).
    public var remembersLeft: Int?
    private var current: Active?
    /// The memory slice for the run in flight, built on its first recall or path read.
    private var memory: (runID: UUID, index: MemoryIndex)?
    /// His past as a pyramid (`zoom`); nil builds it from his store. A test or the eval world sets its own.
    public var pyramidSource: (@MainActor () -> MemoryPyramid)?
    /// The router that names where a zoom starts; the host sets the one it keeps (`PyramidRouter.load()`).
    public var pyramidRouter: @MainActor () -> PyramidRouter = { PyramidRouter() }
    /// The gists written at night for the pyramid's nodes; none until the host keeps them.
    public var pyramidGists: @MainActor () -> PyramidGists = { PyramidGists() }
    /// The pyramid built from his store, kept until the store changes or the day turns.
    private var pyramidCache: (revision: Int, day: Date, pyramid: MemoryPyramid)?
    private var tries: LookTries?
    /// The rehearsal for the run in flight: one per ask, so its three tries are the ask's. Dropped when the run ends,
    /// with its copy of his store.
    private(set) var rehearsal: (runID: UUID, rehearsal: Rehearsal, slow: Bool)?
    /// The time one rehearsal try may take (`Rehearsal.seconds`); a test sets it lower.
    var rehearsalSeconds = Rehearsal.seconds
    /// What she hears when a rehearsal ran out of time, and on every write after it in the same ask.
    static let slowRehearsal = "That took too long to try. Change nothing and ask him first"
    /// What a call that waited for its reply hears when the reply broke off or ran out of room: it never ran.
    static let notRun = "Nothing ran: the reply broke off before it ended. Ask again, in fewer steps if it was long"
    private var lastRung: BrainID?
    private var lastAskAt: Date?
    private var lastWarm: [BrainID: Date] = [:]

    public init(door: Door, engine: ActionEngine, conversation: TessConversation, trace: RunTrace? = nil,
                runs: TessRunStore = TessRunStore())
    {
        self.door = door
        self.engine = engine
        self.conversation = conversation
        self.trace = trace ?? door.trace
        self.runs = runs
    }

    // MARK: Ask

    /// Where an ask comes from: a plain screen line (the old way), or the frame of where he is with the tool pick made
    /// from it (docs/ai/harness/elements.md).
    struct Context {
        var screen: String?
        var frame: TessFrame?
        var pick: ToolPicker.Pick?
    }

    /// Starts a run from the frame (where he is). The picker chooses the calls and the rung; a short command about the
    /// thing in focus ("done", "open this") is bound from the frame and runs with no model at all. The frame's
    /// fragments replace the old "On screen" line, and its object ids become the run's handles.
    public func ask(_ text: String, frame: TessFrame) -> AsyncStream<TessRunEvent> {
        let pick = ToolPicker.pick(text, frame: frame, agent: agent, looks: SettingsStore(engine: engine).read().looks)
        let about = frame.aboutIDs.compactMap { engine.store.object(id: $0) }.filter { !$0.isDeleted }
        return start(text, about: about, context: Context(screen: nil, frame: frame, pick: pick))
    }

    /// Starts a run. The same text again within 10 s joins the running stream; any other ask cancels the one in flight.
    public func ask(_ text: String, about: [ObjectRecord] = [], screen: String? = nil) -> AsyncStream<TessRunEvent> {
        start(text, about: about, context: Context(screen: screen))
    }

    private func start(_ text: String, about: [ObjectRecord], context: Context) -> AsyncStream<TessRunEvent> {
        if let active = current, !active.done, active.text == text,
           now().timeIntervalSince(active.startedAt) < Self.sameAskWindow
        {
            return subscribe(active)
        }
        if let old = current, !old.done {
            old.task?.cancel()
            old.done = true
            for continuation in old.subscribers.values {
                continuation.finish()
            }
            old.subscribers = [:]
        }
        let active = Active(text: text, startedAt: now())
        current = active
        let stream = subscribe(active)
        active.task = Task { [weak self] in
            await self?.execute(active, about: about, context: context)
        }
        return stream
    }

    private func subscribe(_ active: Active) -> AsyncStream<TessRunEvent> {
        AsyncStream { continuation in
            for event in active.buffer {
                continuation.yield(event)
            }
            if active.done {
                continuation.finish()
                return
            }
            let id = UUID()
            active.subscribers[id] = continuation
            continuation.onTermination = { [weak active] _ in
                Task { @MainActor in active?.subscribers[id] = nil }
            }
        }
    }

    private func emit(_ event: TessRunEvent, _ active: Active) {
        guard !active.done else { return }
        // No full stop on a line he sees (ShownLine): her whole reply, her phone lines, and the live words, whose
        // closing stop is held until more words follow so nothing flickers when the reply lands.
        let shown: TessRunEvent
        switch event {
        case let .finished(line): shown = .finished(ShownLine.unstopped(line))
        case let .failed(line): shown = .failed(ShownLine.unstopped(line))
        case let .words(delta):
            var live = (active.heldStop ? "." : "") + delta
            active.heldStop = live.hasSuffix(".") && !live.hasSuffix("..")
            if active.heldStop {
                live.removeLast()
            }
            guard !live.isEmpty else { return }
            shown = .words(live)
        default: shown = event
        }
        active.buffer.append(shown)
        for continuation in active.subscribers.values {
            continuation.yield(shown)
        }
        if shown.isTerminal {
            active.done = true
            for continuation in active.subscribers.values {
                continuation.finish()
            }
            active.subscribers = [:]
        }
    }

    // MARK: Pack

    struct Pack {
        var system: [TextBlock]
        var cacheAfter: [CacheMark]
        var tools: [ToolSpec]
        var fragments: [PackFragment]
        var handles: [String: UUID]
    }

    /// The shell calls as tools: they change what is shown and write nothing.
    static func shellSpecs() -> [ToolSpec] {
        func spec(_ name: String, _ description: String, _ schema: TessSchema) -> ToolSpec {
            let data = (try? JSONSerialization.data(withJSONObject: schema.json, options: [.sortedKeys])) ?? Data()
            return ToolSpec(name: name, description: description, schema: data)
        }
        return [
            spec(
                "openItem",
                "Open a thing on the screen",
                .object([("item", .string("The thing, by its handle or name"))])
            ),
            spec("openDoor", "Open a door of this room", .object([("door", .string("The door's name"))])),
            spec(
                "showWindow",
                "Change the screen's window (the switcher's word)",
                .object([("window", .string("The word"))])
            ),
            spec("goBack", "Go back one page", .object([])),
            spec("setLook", "Change how a place on screen looks (a setting; his things don't change): one form, or "
                + "one trait to one value, only from that place's look line. It is tried off screen first", .object([
                    ("place", .string("The place: dial, widget, page, needs, doorSummary, glyph, keystone...")),
                    ("form", .nullable(.string("A form from the look line, or designed for the studio's look"))),
                    ("trait", .nullable(.string("A trait from the look line, with value"))),
                    ("value", .nullable(.string("The trait's new value"))),
                    ("scope", .nullable(.string("room for this room, everywhere for every room; null is this room"))),
                ])),
            spec("showLooks", "Open shape mode on a place so he can swipe through its forms",
                 .object([("place", .string("The place"))])),
        ]
    }

    /// Tries a look off screen (the quiet stage): never a shell call, since nothing is shown.
    static var tryLookSpec: ToolSpec {
        let schema = TessSchema.object([
            ("place", .string("The place: dial, widget, page, needs, doorSummary, glyph, keystone...")),
            ("form", .nullable(.string("A form from the look line, or designed for the studio's look"))),
            ("trait", .nullable(.string("A trait from the look line, with value"))),
            ("value", .nullable(.string("The trait's new value"))),
        ])
        let data = (try? JSONSerialization.data(withJSONObject: schema.json, options: [.sortedKeys])) ?? Data()
        return ToolSpec(name: "tryLook", description: "Try a look off screen before you show it: draws this screen "
            + "with one form, or one trait at one value, and says which checks it fails (fits, floor, contrast, "
            + "rules, touch, calm). Shows and changes nothing. On an open ask try up to three, then setLook one that "
            + "passes, or tell him why none fit", schema: data)
    }

    /// The rehearsal as Claude reads it: the device-only tool's own input, run here, so what comes back is
    /// what the Door lets through (`rehearsed`).
    static var rehearseSpec: ToolSpec? {
        guard let tool = TessTools.tool(named: RehearseFlags.tool),
              let data = try? JSONSerialization.data(withJSONObject: tool.input.json, options: [.sortedKeys])
        else { return nil }
        return ToolSpec(name: tool.name, description: RehearseFlags.description, schema: data)
    }

    /// Only the tools a pick named, in its order (shell calls included); `open` rides along as a read.
    static func toolSpecs(only names: [String]) -> [ToolSpec] {
        let all = toolSpecs() + shellSpecs() + [tryLookSpec] + (rehearseSpec.map { [$0] } ?? [])
        return names.compactMap { name in all.first { $0.name == name } }
    }

    /// The tool definitions in a fixed order: the Tess tools, then `open`.
    static func toolSpecs() -> [ToolSpec] {
        var specs: [ToolSpec] = []
        if let data = try? TessTools.definitionsJSON(),
           let list = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        {
            for item in list {
                guard let name = item["name"] as? String, let schema = item["input_schema"],
                      let json = try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])
                else { continue }
                specs.append(ToolSpec(name: name, description: item["description"] as? String ?? "", schema: json))
            }
        }
        return specs + [TessOpenTool.spec] + TessRecallTools.specs
            + [AgentNotebook.spec, askAgentSpec, TessGuide.spec, TessZoomTool.spec]
    }

    /// His past as a pyramid: the source's, or built from his store once per store change and day.
    func pyramid() -> MemoryPyramid {
        if let pyramidSource {
            return pyramidSource()
        }
        let store = engine.store, day = calendar.startOfDay(for: now())
        if let pyramidCache, pyramidCache.revision == store.revision, pyramidCache.day == day {
            return pyramidCache.pyramid
        }
        let leaves = MemoryPyramid.leaves(store: store, classes: engine.classes, now: now())
        let built = MemoryPyramid(leaves: leaves, calendar: calendar)
        pyramidCache = (store.revision, day, built)
        return built
    }

    /// The agent's memory slice for this run (M2), built once per run so recall's paths stay the same across rounds.
    func memoryIndex(for runID: UUID) -> MemoryIndex {
        if let memory, memory.runID == runID {
            return memory.index
        }
        let index = MemoryIndex(engine: engine, scope: MemoryScope(agent, policy: door.policy()), calendar: calendar)
        memory = (runID, index)
        return index
    }

    /// system[0] voice (cache), tools, system[1] profile (cache); fragments ride on the ask.
    func pack(about: [ObjectRecord], screen: String?, withTools: Bool, frame: TessFrame? = nil,
              pick: ToolPicker.Pick? = nil, ask: String? = nil) -> Pack
    {
        var system = [TextBlock(Self.voice)]
        var cache: [CacheMark] = [CacheMark(0, .oneHour)]
        let profile = profile()
        if !profile.isEmpty {
            system.append(TextBlock(profile))
            cache.append(CacheMark(1, .oneHour))
        }
        var fragments: [PackFragment] = []
        var handles: [String: UUID] = [:]
        let store = engine.store, classes = engine.classes
        if let frame {
            // Where he is, by shown names; each fragment keeps its own taint for the Door.
            fragments.append(contentsOf: frame.fragments())
            if pick?.looks == true {
                // His looks come from settings, never from the frame: the frame is the same in every look.
                fragments.append(contentsOf: frame.lookLines(SettingsStore(engine: engine).read().looks))
            }
        } else if let screen, !screen.isEmpty {
            fragments.append(PackFragment("On screen: \(screen)"))
        }
        if let digest = dayDigest(), !digest.isEmpty {
            // Today's digest can name events and sleep, which the strict scan cannot tell from other words: deviceOnly,
            // so
            // it goes to Claude under lab only.
            fragments.append(PackFragment("Today: \(digest)", taint: .deviceOnly))
        }
        for (index, object) in about.enumerated() where !object.isDeleted {
            let handle = "o\(index + 1)"
            handles[handle] = object.id
            // Under lab (his Oct 27 call: Claude sees everything) a private thing goes by its own words, not its label,
            // tainted so strict would drop it.
            let label = ObjectPrivacy.shownLabel(of: object, in: store, classes: classes)
            let lab = door.policy() == .lab && ClaudeSees.everything
            let shown = (lab ? nil : label)
                ?? TessAskRouter.shownSentence(object, in: store, classes: classes, calendar: calendar)
                ?? (object.title.isEmpty ? "an object" : object.title)
            // Money, health, body, calorie and calendar things go to Claude only under lab mode.
            let hidden = TessAskRouter.isUnnameable(object, classes: classes) || (lab && label != nil)
            let taint: Taint = hidden ? .deviceOnly : .claudeSafe
            fragments.append(PackFragment("[\(handle)] \(shown)", taint: taint))
        }
        let specs = pick.map { Self.toolSpecs(only: $0.tools) }
            ?? Self.toolSpecs()
        if withTools, pick?.tools.contains(TessGuide.name) == true {
            // Tier 1 of the guide: what it holds, so she pages in only what the ask needs.
            fragments.append(PackFragment(TessGuide.contentsLine))
        }
        if withTools, let ask, pick?.tools.contains(TessZoomTool.name) == true {
            // Tier 1 of the pyramid: how paths look, and where to start when the router is sure. Only paths: what
            // a node holds comes back through zoom, under the Door's policy.
            fragments.append(PackFragment(TessZoomTool.line(for: ask, pyramid: pyramid(), router: pyramidRouter(),
                                                            policy: door.policy(), now: now(), calendar: calendar)))
        }
        if let reason = pick?.rehearse, specs.contains(where: { $0.name == RehearseFlags.tool }) {
            // Only when the phone has the rehearsal: a line about a tool she wasn't given would mislead her.
            fragments.append(PackFragment(RehearseFlags.line(reason, count: pick?.count)))
        }
        return Pack(system: system, cacheAfter: cache, tools: withTools ? specs : [],
                    fragments: fragments, handles: handles)
    }

    private func history() -> [BrainMessage] {
        conversation.forClaude(asksClaude: door.asksClaude()).map {
            BrainMessage($0.role == .user ? .user : .assistant, text: $0.text)
        }
    }

    // MARK: Execute

    private func execute(_ active: Active, about: [ObjectRecord], context: Context) async {
        emit(.waiting, active)
        let text = active.text
        // A key-shaped ask goes nowhere: no Door call, no stored turn.
        if looksLikeClaudeKey(text) {
            return emit(.failed(Self.keyLine), active)
        }
        // A bound call runs with no model at all: the frame filled every input.
        if let bound = context.pick?.bound {
            _ = conversation.append(role: .user, text: text, about: about, at: now())
            let line = await runBound(bound, frame: context.frame, active: active)
            _ = conversation.append(role: .tess, text: line.reply, about: about, at: now())
            return emit(line.failed ? .failed(line.reply) : .finished(line.reply), active)
        }
        let claudeOn = flagOn() && door.asksClaude()
        let plan = claudeOn ? (context.pick?.plan ?? pickRung(text)) : RungPlan.deviceOnly
        lastRung = plan.ladder.first
        lastAskAt = now()
        let pack = pack(about: about, screen: context.screen, withTools: claudeOn, frame: context.frame,
                        pick: context.pick, ask: text)
        let messages = history() + [BrainMessage(.user, text: text)]
        _ = conversation.append(role: .user, text: text, about: about, at: now())
        var state = TessRunState(startedAt: now(), askText: text, aboutIDs: about.map(\.id), messages: messages)
        runs.save(state, now: now())
        let outcome = await rounds(&state, plan: plan, pack: pack, runID: state.id) { [weak self] event in
            guard let self else { return }
            emit(event, active)
        }
        finish(&state, outcome: outcome, about: about)
        if Task.isCancelled {
            state.status = .dropped
        }
        runs.save(state, now: now())
        if case let .reply(reply) = outcome, !Task.isCancelled {
            emit(.finished(reply), active)
            // C6 in shadow, after the reply is out, so nothing on the phone waits on the check or the trace's write.
            await recordAnswerCheck(reply: reply, ask: text, pack: pack, messages: state.messages, runID: state.id)
        } else if case let .phone(line) = outcome, !Task.isCancelled {
            emit(.failed(line), active)
        }
    }

    enum Outcome {
        case reply(String)
        case phone(String)
    }

    private func finish(_ state: inout TessRunState, outcome: Outcome, about: [ObjectRecord]) {
        switch outcome {
        case let .reply(reply):
            state.status = .finished
            // Her reply is a stored turn, naming what the ask was about; a failed run stores nothing.
            _ = conversation.append(role: .tess, text: reply, about: about, at: now())
        case .phone:
            state.status = .failed
        }
    }

    /// Up to three rounds. Each round is one `door.run`; each tool starts when its block closes.
    func rounds(_ state: inout TessRunState, plan: RungPlan, pack: Pack, runID: UUID,
                sink: (TessRunEvent) -> Void) async -> Outcome
    {
        var budget = TessTools.maxRecordsPerPhrase
        var pauses = 0
        defer {
            // The copy of his store and the tries live only as long as the ask.
            rehearsal = nil
            tries = nil
        }
        while state.round <= Self.maxRounds {
            let request = BrainRequest(system: pack.system, messages: state.messages, tools: pack.tools,
                                       toolChoice: pack.tools.isEmpty ? .auto : plan.toolChoice,
                                       maxTokens: plan.maxTokens, effort: plan.effort, cacheAfter: pack.cacheAfter,
                                       deadline: .seconds(30))
            // The hold covers the dearest Claude rung on the ladder (Opus, when it is the second try).
            let text = Door.words(request) + pack.fragments.map(\.text).joined()
                + pack.tools.map(\.description).joined()
            let estimate = plan.ladder.compactMap { Self.claudeModel(for: $0) }.map {
                TessUsageLedger.estimate(text: text, maxTokens: plan.maxTokens, model: $0.rawValue)
            }.max() ?? 0
            let job = DoorJob(name: "tess-turn", ladder: plan.ladder, request: request, fragments: pack.fragments,
                              estimateNano: estimate, hedge: plan.hedge, runID: runID)
            var roundText = ""
            var roundBlocks: [Data] = []
            var stop = "end_turn"
            var uses: [(id: String, name: String, input: Data)] = []
            var results: [String: (text: String, isError: Bool)] = [:]
            var failure: ClaudeOutcome?
            // H5: a read starts the moment its block closes; anything that writes or shows waits until the reply has
            // ended whole, so a call from a reply cut off at the token limit, refused, or broken off never runs.
            var waiting: [(id: String, name: String, input: Data)] = []
            let offered = Set(pack.tools.map(\.name))
            let schemas = Dictionary(pack.tools.map { ($0.name, $0.schema) }, uniquingKeysWith: { first, _ in first })
            do {
                for try await event in door.run(job) {
                    switch event {
                    case let .text(piece):
                        roundText += piece
                        state.words += piece
                        sink(.words(piece))
                    case let .toolUse(id, name, input):
                        uses.append((id, name, input))
                        guard ToolPicker.runAtOnce.contains(name) else {
                            waiting.append((id, name, input))
                            break
                        }
                        // A read starts at once: the tool runs now, not when the stream ends.
                        let result = await runTool(id: id, name: name, input: input, handles: pack.handles,
                                                   offered: offered, schemas: schemas,
                                                   onDevice: plan.ladder == [.appleOnDevice], budget: &budget,
                                                   runID: runID, sink: sink)
                        results[id] = result
                        state.doneToolIDs.append(id)
                        state.toolResults[id] = result.text
                        runs.save(state, now: now())
                    case let .failed(outcome):
                        failure = outcome
                    case let .assistant(blocks):
                        roundBlocks = blocks
                    case let .done(_, stop: reason):
                        stop = reason
                    case .status:
                        break
                    }
                }
            } catch {
                failure = .other
            }
            if Task.isCancelled {
                return .phone("")
            }
            let whole = failure == nil && stop != "max_tokens" && stop != "refusal"
            for use in waiting {
                var result: (text: String, isError: Bool) = (Self.notRun, true)
                if whole {
                    result = await runTool(id: use.id, name: use.name, input: use.input, handles: pack.handles,
                                           offered: offered, schemas: schemas,
                                           onDevice: plan.ladder == [.appleOnDevice], budget: &budget, runID: runID,
                                           sink: sink)
                }
                results[use.id] = result
                state.doneToolIDs.append(use.id)
                state.toolResults[use.id] = result.text
                runs.save(state, now: now())
            }
            if let failure, uses.isEmpty {
                return .phone(Self.line(for: failure, onlyDevice: plan.ladder == [.appleOnDevice]))
            }
            // The assistant message is replayed exactly as the API sent it, never rebuilt from text deltas.
            let assistantContent: [BrainContent] = roundBlocks.isEmpty
                ? (roundText.isEmpty ? [] : [.text(roundText)]) + uses.map { .toolUse(
                    id: $0.id,
                    name: $0.name,
                    input: $0.input
                ) }
                : roundBlocks.map(BrainContent.raw)
            if stop == "pause_turn", uses.isEmpty, pauses < Self.maxPauses {
                // The server paused a long turn: send it back unchanged. It does not use one of the three rounds.
                pauses += 1
                state.messages.append(BrainMessage(.assistant, assistantContent))
                runs.save(state, now: now())
                continue
            }
            if uses.isEmpty {
                return state.words.isEmpty ? .phone(Self.noAnswer) : .reply(state.words)
            }
            if state.round == Self.maxRounds {
                return .phone(Self.tooManySteps)
            }
            // All tool results go back together in one user message.
            state.messages.append(BrainMessage(.assistant, assistantContent))
            state.messages.append(BrainMessage(.user, uses.map { use in
                let result = results[use.id] ?? ("Nothing ran", true)
                return .toolResult(id: use.id, content: result.text, isError: result.isError)
            }))
            state.round += 1
            runs.save(state, now: now())
        }
        return .phone(Self.tooManySteps)
    }

    static func claudeModel(for id: BrainID) -> ClaudeBrain.Model? {
        switch id {
        case .haiku: .haiku
        case .sonnet: .sonnet
        case .opus: .opus
        default: nil
        }
    }

    static func line(for outcome: ClaudeOutcome, onlyDevice: Bool) -> String {
        if onlyDevice {
            return cannotThink
        }
        switch outcome {
        case .refused: return "I can't help with that one"
        case .notAllowed: return cannotThink
        default: return noAnswer
        }
    }

    // MARK: Tools

    /// Runs one tool. Reads (open, query) are read only; every other tool is a write that lands as a pending
    /// ghost,
    /// within the per-phrase budget. Never throws: a failure is the result the model reads.
    /// `schemas`: each offered tool's input schema; a call that doesn't fit its own runs nothing (H5).
    func runTool(id _: String, name: String, input: Data, handles: [String: UUID], offered: Set<String>,
                 schemas: [String: Data] = [:], onDevice: Bool, budget: inout Int, runID: UUID,
                 sink: (TessRunEvent) -> Void) async -> (text: String, isError: Bool)
    {
        let started = ContinuousClock.now
        var result: (text: String, isError: Bool)
        // Only a call this turn was offered can run, whatever name the model returns; and while money stays off
        // Claude (`ClaudeSees.moneyWrites` off), a money tool never runs for a Claude rung, even if it were offered.
        // The rehearsal is device-only as a tool, but it writes nothing: it runs here, and a Claude rung reads
        // only what the Door lets through. A money call inside it fails off the phone while money stays off Claude.
        let deviceOnly = name != RehearseFlags.tool
            && ClaudeSees.keepsOnPhone(TessTools.tool(named: name)?.deviceOnly == true)
        let misfit = schemas[name].flatMap { ToolInputCheck.problem(input, schema: $0) }
        switch name {
        case _ where !offered.contains(name) || (deviceOnly && !onDevice):
            result = ("That isn't a call I can make here", true)
        case _ where misfit != nil:
            result = (misfit ?? "", true)
        case TessOpenTool.name:
            // A path (from recall) resolves through the agent's slice; a pack handle needs no index.
            let isPath = ((try? JSONSerialization.jsonObject(with: input)) as? [String: Any])?["handle"]
                .flatMap { $0 as? String }?.hasPrefix("/") == true
            result = TessOpenTool.run(arguments: input, handles: handles, engine: engine, policy: door.policy(),
                                      calendar: calendar, index: isPath ? memoryIndex(for: runID) : nil)
        case TessGuide.name:
            // What the app is, never his data: the same page on every rung and policy.
            result = TessGuide.run(arguments: input)
        case TessZoomTool.name:
            // His past, read only: the node shows what the Door's policy lets it.
            result = TessZoomTool.run(arguments: input, pyramid: pyramid(), policy: door.policy(),
                                      gists: pyramidGists())
        case Self.askAgent:
            // Tess asks her rooms; each runs as itself, in parallel, and its writes land as ghost rows.
            let answer = await askAgents(input, handles: handles, onDevice: onDevice)
            for ghost in answer.ghosts {
                sink(.ghost(ghost))
            }
            result = (answer.text, answer.isError)
        case AgentNotebook.name:
            // Its own notebook only: the scope's folder, the policy's pages.
            result = AgentNotebook(engine: engine, scope: MemoryScope(agent, policy: door.policy()), now: now())
                .run(arguments: input)
        case _ where TessRecallTools.names.contains(name):
            if name == TessRecallTools.remember, budget <= 0 || (remembersLeft.map { $0 <= 0 } ?? false) {
                result = (budget <= 0 ? TessTools.capLine : "That's enough for tonight", true)
                break
            }
            let answer = TessRecallTools.run(name, arguments: input, index: memoryIndex(for: runID), engine: engine,
                                             seeds: Array(handles.values), now: now(), calendar: calendar)
            budget -= answer.ghosts.count
            if let left = remembersLeft, name == TessRecallTools.remember {
                remembersLeft = left - answer.ghosts.count
            }
            for ghost in answer.ghosts {
                sink(.ghost(ghost))
            }
            result = (answer.text, answer.isError)
        case RehearseFlags.tool:
            result = rehearsed(input, runID: runID, onDevice: onDevice, offered: offered)
        case "tryLook":
            let args = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any] ?? [:]
            result = await tryLook(args.compactMapValues { $0 as? String }, runID: runID)
        case _ where ElementCatalog.shellCalls.contains(name):
            // A shell call writes nothing: the host plays it.
            let args = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any] ?? [:]
            var strings: [String: String] = [:]
            var object: UUID?
            for (key, value) in args {
                guard let text = value as? String else { continue }
                strings[key] = text
                // Only a handle from this pack points at a thing; an id the model made up points at nothing.
                if let id = handles[text] {
                    object = id
                }
            }
            if name == "setLook", let refusal = await staged(strings, runID: runID) {
                result = refusal
                break
            }
            sink(.shell(ShellIntent(call: name, object: object, arguments: strings)))
            result = ("Shown.", false)
        case _ where rehearsal?.runID == runID && rehearsal?.slow == true && !ToolPicker.runAtOnce.contains(name):
            // A rehearsal that ran out of time proved nothing: she asks him instead of writing unrehearsed.
            result = (Self.slowRehearsal, true)
        default:
            do {
                let records = try TessTools.run(name, arguments: input, engine: engine, pending: true, now: now(),
                                                calendar: calendar, budget: budget)
                budget -= records.count
                for record in records {
                    sink(.ghost(record.id))
                }
                result = ("Done: \(records.count) waiting for approval", false)
            } catch let answer as TessToolAnswer {
                result = (answer.line, false)
            } catch let error as TessToolError {
                result = (error.description, true)
            } catch {
                result = ("That didn't work", true)
            }
        }
        await trace.record(TraceSpan(kind: .tool, name: name, at: now(), totalMs: LatencyBench.ms(.now - started),
                                     outcome: result.isError ? "error" : "works", runID: runID))
        return result
    }

    /// A look the model picked, checked before the host sees it: a form or value the place has, then the quiet stage.
    /// Nil when it may go to the shell; otherwise what the model hears instead. Nothing is shown either way.
    /// A look she tried that passed this run isn't staged again.
    func staged(_ arguments: [String: String], runID: UUID) async -> (text: String, isError: Bool)? {
        guard let key = arguments["place"], let place = ElementPlace(rawValue: key),
              let change = LookWords.change(arguments), LookWords.isKnown(change, place: key)
        else {
            return ("That place has no such look. Use one from its look line", true)
        }
        if tries?.runID == runID, tries?.passed.contains(Self.tryKey(key, change)) == true {
            return nil
        }
        guard let stage else { return nil }
        let report = await stage(place, change)
        guard !report.passed else { return nil }
        return ("Not shown: \(report.line); his look stays. Try another form, or tell him why", false)
    }

    /// Runs `rehearse` on a copy of his store with the ask's one `Rehearsal`. The phone's own model reads the whole
    /// result; a Claude rung reads its fragments as the Door's policy allows (strict holds money, body and private
    /// lines back and says how many), never the receipts.
    /// Only calls this turn offered may be tried, so the Deck can't rehearse the Purse's tools.
    func rehearsed(_ input: Data, runID: UUID, onDevice: Bool, offered: Set<String>) -> (text: String, isError: Bool) {
        guard let asked = RehearseFlags.calls(input) else {
            return ("Give the calls to try, each with its name and arguments.", true)
        }
        let unoffered = asked.calls.map(\.name).filter { !offered.contains($0) || $0 == RehearseFlags.tool }
        guard unoffered.isEmpty else {
            // Only a name Tess has is read back: a made-up one is the model's own words (H5).
            let named = unoffered.filter { TessTools.tool(named: $0) != nil || ElementCatalog.shellCalls.contains($0) }
            let which = named.isEmpty ? "" : ", not \(named.joined(separator: ", "))"
            return ("Only calls offered here can be rehearsed\(which)", true)
        }
        let current: Rehearsal
        if let kept = rehearsal, kept.runID == runID {
            if kept.slow {
                return (Self.slowRehearsal, true)
            }
            current = kept.rehearsal
        } else {
            current = Rehearsal(engine: engine)
            current.seconds = rehearsalSeconds
            rehearsal = (runID, current, false)
        }
        guard current.tries < Rehearsal.budget else {
            // Said here, not as the rehearsal's own refusal, which strict holds back with the other refusals.
            return ("That's \(Rehearsal.budget) rehearsals for this ask. Ask him instead of guessing", true)
        }
        let result = current.try(asked.calls, expecting: asked.expecting,
                                 scope: MemoryScope(agent, policy: door.policy()), onDevice: onDevice)
        if result.failed.contains(where: { if case .overBudget = $0 { true } else { false } }) {
            // Nothing says the change is safe: no more tries, and no write for the rest of the ask.
            rehearsal = (runID, current, true)
            return (Self.slowRehearsal, true)
        }
        if onDevice {
            return (result.text, false)
        }
        return (RehearseFlags.forClaude(result, policy: door.policy()), false)
    }

    /// A look tried off screen (`tryLook`): the place's own list, then the quiet stage. Nothing is shown or kept. At
    /// most `maxTries` per ask; one that passed goes straight to the shell when she then sets it.
    func tryLook(_ arguments: [String: String], runID: UUID) async -> (text: String, isError: Bool) {
        guard let key = arguments["place"], let place = ElementPlace(rawValue: key),
              let change = LookWords.change(arguments), LookWords.isKnown(change, place: key)
        else {
            return ("That place has no such look. Use one from its look line.", true)
        }
        var run = tries.flatMap { $0.runID == runID ? $0 : nil } ?? LookTries(runID: runID)
        guard run.left > 0 else {
            return ("That's \(Self.maxTries) tries for this ask. Set the best one, or ask him", true)
        }
        run.left -= 1
        defer { tries = run }
        guard let stage else {
            return ("It is one of the place's looks. This phone can't draw it off screen yet; setLook checks it", false)
        }
        let report = await stage(place, change)
        guard report.passed else {
            return ("Tried, not shown: \(report.line). Try another, or tell him why", false)
        }
        run.passed.insert(Self.tryKey(key, change))
        return ("Tried, not shown: it passes every check. setLook shows it", false)
    }

    /// One look change on one place, as the tries remember it.
    static func tryKey(_ place: String, _ change: LookChange) -> String {
        "\(place) \(change)"
    }

    // MARK: Bound calls

    /// Runs a call the frame filled, with no model: a shell call is handed to the host; a tool call runs by object id,
    /// pending (a ghost row with Undo 10 s). Returns the line to say.
    private func runBound(_ bound: ToolPicker.Bound, frame _: TessFrame?,
                          active: Active) async -> (reply: String, failed: Bool)
    {
        let started = ContinuousClock.now
        let result = await performBound(bound, active: active)
        await trace.record(TraceSpan(kind: .tool, name: bound.call, at: now(), totalMs: LatencyBench.ms(.now - started),
                                     outcome: result.failed ? "error" : "bound", runID: active.id))
        return result
    }

    private func performBound(_ bound: ToolPicker.Bound, active: Active) async -> (reply: String, failed: Bool) {
        if ElementCatalog.shellCalls.contains(bound.call) {
            emit(.shell(ShellIntent(call: bound.call, object: bound.object, arguments: bound.arguments)), active)
            return (Self.shellLine(bound), false)
        }
        // The tool's arguments: each input by its name, the object by id (a label still points at the right row).
        var arguments: [String: Any] = bound.arguments
        if let object = bound.object, let call = ElementCatalog.everyCall.first(where: { $0.name == bound.call }),
           let input = call.inputs.first(where: { $0.source == .referent })
        {
            arguments[input.name] = object.uuidString
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: arguments)
            let records = try TessTools.run(bound.call, arguments: data, engine: engine, pending: true, now: now(),
                                            calendar: calendar)
            for record in records {
                emit(.ghost(record.id), active)
            }
            let line = records.compactMap(\.receipt).first ?? records.first?.summary ?? "Done"
            return (line, false)
        } catch let answer as TessToolAnswer {
            return (answer.line, false)
        } catch let error as TessToolError {
            return (Self.boundFailure(error.description), true)
        } catch {
            return ("That didn't work", true)
        }
    }

    static func shellLine(_ bound: ToolPicker.Bound) -> String {
        switch bound.call {
        case "goBack": "Back"
        case "openDoor": bound.arguments["door"].map { "Opening \($0)" } ?? "Opening it"
        case "showWindow": bound.arguments["window"].map { "\($0)" } ?? "Done"
        case "setLook": lookLine(bound.arguments)
        case "showLooks": "Here are its looks"
        default: bound.arguments["item"].map { "Opening \($0)" } ?? "Opening it"
        }
    }

    /// "The dial, as index" from a bound look; the shell's own Undo line follows.
    static func lookLine(_ arguments: [String: String]) -> String {
        guard let place = arguments["place"], let change = LookWords.change(arguments) else { return "Done" }
        let everywhere = arguments["scope"] == "everywhere" ? ", in every room" : ""
        return switch change {
        case let .form(id): "The \(place), as \(id)\(everywhere)"
        case .designed: "The \(place), as drawn\(everywhere)"
        case let .trait(name, value): "The \(place): \(name) \(value)\(everywhere)"
        }
    }

    static func boundFailure(_ text: String) -> String {
        text.isEmpty ? "That didn't work" : "I couldn't do that: \(text)"
    }

    // MARK: Resume

    /// On launch: a run still marked running resumes at the next round when its last step was a finished tool (a tool
    /// in
    /// `doneToolIDs` never runs twice), otherwise it is dropped and she says nothing about it. A write that did not
    /// finish is not run again: the model reads that it was interrupted.
    public func resumeInterrupted() async {
        for var state in runs.all(now: now()) where state.status == .running {
            // A run older than ten minutes is not picked up again: the moment has passed.
            guard now().timeIntervalSince(state.startedAt) <= Self.resumeWindow else {
                state.status = .dropped
                runs.save(state, now: now())
                continue
            }
            guard let last = state.messages.last else {
                state.status = .dropped
                runs.save(state, now: now())
                continue
            }
            var resumable = false
            if last.role == .user, last.content.contains(where: {
                if case .toolResult = $0 {
                    true
                } else {
                    false
                }
            }) {
                resumable = true
            } else if last.role == .assistant {
                // Tool calls were made; some finished.
                resumable = !state.doneToolIDs.isEmpty
            }
            guard resumable else {
                state.status = .dropped
                runs.save(state, now: now())
                continue
            }
            var about: [ObjectRecord] = []
            for id in state.aboutIDs {
                if let object = engine.store.object(id: id) {
                    about.append(object)
                }
            }
            if last.role == .assistant {
                let uses = last.content.compactMap { piece -> (String, String, Data)? in
                    if case let .toolUse(id, name, input) = piece {
                        (id, name, input)
                    } else {
                        nil
                    }
                }
                state.messages.append(BrainMessage(.user, uses.map { id, name, input in
                    if state.doneToolIDs.contains(id), let text = state.toolResults[id] {
                        return .toolResult(id: id, content: text, isError: false)
                    }
                    if name == TessGuide.name {
                        // A pure read of what the app is: it runs again rather than reading as interrupted, held to
                        // its schema like any call (H5).
                        if let misfit = ToolInputCheck.problem(input, schema: TessGuide.spec.schema) {
                            return .toolResult(id: id, content: misfit, isError: true)
                        }
                        let page = TessGuide.run(arguments: input)
                        return .toolResult(id: id, content: page.text, isError: page.isError)
                    }
                    if name == TessOpenTool.name || name == "query" || name == TessZoomTool.name {
                        return .toolResult(id: id, content: "The phone was interrupted before this ran.", isError: true)
                    }
                    return .toolResult(
                        id: id,
                        content: "The phone was interrupted before this ran. Nothing was changed",
                        isError: true
                    )
                }))
                state.round += 1
            }
            let claudeOn = flagOn() && door.asksClaude()
            let plan = claudeOn ? pickRung(state.askText) : RungPlan.deviceOnly
            let pack = pack(about: about, screen: nil, withTools: claudeOn)
            let outcome = await rounds(&state, plan: plan, pack: pack, runID: state.id) { _ in }
            finish(&state, outcome: outcome, about: about)
            runs.save(state, now: now())
        }
    }

    // MARK: Warm

    public enum WarmReason: Sendable {
        /// The Tess layer opened.
        case layerOpened
        /// The app came to the foreground.
        case foreground
    }

    /// Warms the rung the last ask used with the pack's prefix (voice, tools, profile). At most once per 4 minutes per
    /// model, never in Low Power, never with Tess asks Claude off; on foreground only if she was asked in the last 2
    /// hours. Its cost goes through the ledger like any call.
    @discardableResult
    public func warmUp(_ reason: WarmReason, lowPower: Bool) async -> BrainWarm? {
        guard !lowPower, flagOn(), door.asksClaude() else { return nil }
        let when = now()
        if reason == .foreground {
            guard let lastAskAt, when.timeIntervalSince(lastAskAt) < Self.warmWindow else { return nil }
        }
        let rung = lastRung ?? .haiku
        guard BrainRouter.isClaude(rung) else { return nil }
        if let last = lastWarm[rung], when.timeIntervalSince(last) < Self.warmSpacing {
            return nil
        }
        lastWarm[rung] = when
        let pack = pack(about: [], screen: nil, withTools: true)
        let request = BrainRequest(system: pack.system, messages: [BrainMessage(.user, text: "Hi")], tools: pack.tools,
                                   maxTokens: 1, effort: .low, cacheAfter: pack.cacheAfter)
        return await door.warm(rung, request, name: "tess-warm")
    }
}
