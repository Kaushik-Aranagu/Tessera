import Foundation
import TesseraCore

/// H3: the Tess streaming loop. One `TessRun` object serves the layer; each ask is a run. The phone's capture grammar
/// gets the text first, and a phrase it can do never reaches here. Then `pickRung` chooses the smallest rung that fits,
/// the pack is built so the prefix caches, and up to three rounds of the Door run, with each tool started the moment
/// its
/// block closes. Every settled step is checkpointed so a kill never repeats a write.
@MainActor
public final class TessRun {
    public static let maxRounds = 3
    public static let sameAskWindow: TimeInterval = 10
    public static let warmSpacing: TimeInterval = 240
    public static let warmWindow: TimeInterval = 2 * 3600

    public static let tooManySteps = "That needed more steps than I take. Try it in two."
    public static let cannotThink = "I can't think that through right now. The rest still works."
    public static let keyLine = "That looks like a key, so I won't send it."
    public static let noAnswer = "I couldn't get an answer just now. Try again in a moment."

    /// Her voice and rules: fixed text, so the prefix caches (cache breakpoint after it).
    public static let voice = """
    You are Tess, the assistant inside Tessera, a personal app on one person's phone. Voice: brief, warm, a little dry. \
    Answer in a sentence or two unless asked for more. Use the tools to look things up and to make small changes; a \
    change you make is only proposed until the person approves it. You never move or record money, and you never \
    invent facts about the person's data: say you don't know. Objects in the pack have short handles like o1; read one \
    with open. Do not repeat the pack back.
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

    private final class Active: @unchecked Sendable {
        let id = UUID()
        let text: String
        let startedAt: Date
        var task: Task<Void, Never>?
        var buffer: [TessRunEvent] = []
        var subscribers: [UUID: AsyncStream<TessRunEvent>.Continuation] = [:]
        var done = false

        init(text: String, startedAt: Date) {
            self.text = text
            self.startedAt = startedAt
        }
    }

    private var current: Active?
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

    /// Starts a run. The same text again within 10 s joins the running stream; any other ask cancels the one in flight.
    public func ask(_ text: String, about: [ObjectRecord] = [], screen: String? = nil) -> AsyncStream<TessRunEvent> {
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
            await self?.execute(active, about: about, screen: screen)
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
        active.buffer.append(event)
        for continuation in active.subscribers.values {
            continuation.yield(event)
        }
        if event.isTerminal {
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
        var cacheAfter: [Int]
        var tools: [ToolSpec]
        var fragments: [PackFragment]
        var handles: [String: UUID]
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
        return specs + [TessOpenTool.spec]
    }

    /// system[0] voice (cache), tools, system[1] profile (cache); fragments ride on the ask.
    func pack(about: [ObjectRecord], screen: String?, withTools: Bool) -> Pack {
        var system = [TextBlock(Self.voice)]
        var cache = [0]
        let profile = profile()
        if !profile.isEmpty {
            system.append(TextBlock(profile))
            cache.append(1)
        }
        var fragments: [PackFragment] = []
        var handles: [String: UUID] = [:]
        let store = engine.store, classes = engine.classes
        if let screen, !screen.isEmpty {
            fragments.append(PackFragment("On screen: \(screen)"))
        }
        if let digest = dayDigest(), !digest.isEmpty {
            fragments.append(PackFragment("Today: \(digest)"))
        }
        for (index, object) in about.enumerated() where !object.isDeleted {
            let handle = "o\(index + 1)"
            handles[handle] = object.id
            let shown = ObjectPrivacy.shownLabel(of: object, in: store, classes: classes)
                ?? Describe.sentence(object, in: store, classes: classes, calendar: calendar)
                ?? (object.title.isEmpty ? "an object" : object.title)
            // Money, health, body, calorie and calendar things go to Claude only under lab mode.
            let taint: Taint = TessAskRouter.isUnnameable(object, classes: classes) ? .deviceOnly : .claudeSafe
            fragments.append(PackFragment("[\(handle)] \(shown)", taint: taint))
        }
        return Pack(system: system, cacheAfter: cache, tools: withTools ? Self.toolSpecs() : [],
                    fragments: fragments, handles: handles)
    }

    private func history() -> [BrainMessage] {
        conversation.forClaude(asksClaude: door.asksClaude()).map {
            BrainMessage($0.role == .user ? .user : .assistant, text: $0.text)
        }
    }

    // MARK: Execute

    private func execute(_ active: Active, about: [ObjectRecord], screen: String?) async {
        emit(.waiting, active)
        let text = active.text
        // A key-shaped ask goes nowhere: no Door call, no stored turn.
        if looksLikeClaudeKey(text) {
            return emit(.failed(Self.keyLine), active)
        }
        let claudeOn = flagOn() && door.asksClaude()
        let plan = claudeOn ? pickRung(text) : RungPlan.deviceOnly
        lastRung = plan.ladder.first
        lastAskAt = now()
        let pack = pack(about: about, screen: screen, withTools: claudeOn)
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
        while state.round <= Self.maxRounds {
            let request = BrainRequest(system: pack.system, messages: state.messages, tools: pack.tools,
                                       toolChoice: pack.tools.isEmpty ? .auto : plan.toolChoice,
                                       maxTokens: plan.maxTokens, effort: plan.effort, cacheAfter: pack.cacheAfter,
                                       thinking: false, deadline: .seconds(30))
            let estimate = TessUsageLedger.estimate(
                text: Door.words(request) + pack.fragments.map(\.text).joined() + pack.tools.map(\.description)
                    .joined(),
                maxTokens: plan.maxTokens,
                model: (plan.ladder.first == .sonnet ? ClaudeBrain.Model.sonnet : .haiku).rawValue
            )
            let job = DoorJob(name: "tess-turn", ladder: plan.ladder, request: request, fragments: pack.fragments,
                              estimateNano: estimate, hedge: plan.hedge, runID: runID)
            var roundText = ""
            var uses: [(id: String, name: String, input: Data)] = []
            var results: [String: (text: String, isError: Bool)] = [:]
            var failure: ClaudeOutcome?
            do {
                for try await event in door.run(job) {
                    switch event {
                    case let .text(piece):
                        roundText += piece
                        state.words += piece
                        sink(.words(piece))
                    case let .toolUse(id, name, input):
                        uses.append((id, name, input))
                        // Started at once: the tool runs now, not when the stream ends.
                        let result = await runTool(id: id, name: name, input: input, handles: pack.handles,
                                                   budget: &budget, runID: runID, sink: sink)
                        results[id] = result
                        state.doneToolIDs.append(id)
                        state.toolResults[id] = result.text
                        runs.save(state, now: now())
                    case let .failed(outcome):
                        failure = outcome
                    case .status, .done:
                        break
                    }
                }
            } catch {
                failure = .other
            }
            if Task.isCancelled {
                return .phone("")
            }
            if let failure, uses.isEmpty {
                return .phone(Self.line(for: failure, onlyDevice: plan.ladder == [.appleOnDevice]))
            }
            if uses.isEmpty {
                return state.words.isEmpty ? .phone(Self.noAnswer) : .reply(state.words)
            }
            if state.round == Self.maxRounds {
                return .phone(Self.tooManySteps)
            }
            // All tool results go back together in one user message.
            var assistant: [BrainContent] = roundText.isEmpty ? [] : [.text(roundText)]
            assistant += uses.map { .toolUse(id: $0.id, name: $0.name, input: $0.input) }
            state.messages.append(BrainMessage(.assistant, assistant))
            state.messages.append(BrainMessage(.user, uses.map { use in
                let result = results[use.id] ?? ("Nothing ran.", true)
                return .toolResult(id: use.id, content: result.text, isError: result.isError)
            }))
            state.round += 1
            runs.save(state, now: now())
        }
        return .phone(Self.tooManySteps)
    }

    static func line(for outcome: ClaudeOutcome, onlyDevice: Bool) -> String {
        if onlyDevice {
            return cannotThink
        }
        switch outcome {
        case .refused: return "I can't help with that one."
        case .notAllowed: return cannotThink
        default: return noAnswer
        }
    }

    // MARK: Tools

    /// Runs one tool. Reads (open, answerQuery) are read only; every other tool is a write that lands as a pending
    /// ghost,
    /// within the per-phrase budget. Never throws: a failure is the result the model reads.
    func runTool(id _: String, name: String, input: Data, handles: [String: UUID], budget: inout Int, runID: UUID,
                 sink: (TessRunEvent) -> Void) async -> (text: String, isError: Bool)
    {
        let started = ContinuousClock.now
        var result: (text: String, isError: Bool)
        switch name {
        case TessOpenTool.name:
            result = TessOpenTool.run(arguments: input, handles: handles, engine: engine, policy: door.policy(),
                                      calendar: calendar)
        default:
            do {
                let records = try TessTools.run(name, arguments: input, engine: engine, pending: true, now: now(),
                                                calendar: calendar, budget: budget)
                budget -= records.count
                for record in records {
                    sink(.ghost(record.id))
                }
                result = ("Done: \(records.count) waiting for approval.", false)
            } catch let answer as TessToolAnswer {
                result = (answer.line, false)
            } catch let error as TessToolError {
                result = (error.description, true)
            } catch {
                result = ("That didn't work.", true)
            }
        }
        await trace.record(TraceSpan(kind: .tool, name: name, at: now(), totalMs: LatencyBench.ms(.now - started),
                                     outcome: result.isError ? "error" : "works", runID: runID))
        return result
    }

    // MARK: Resume

    /// On launch: a run still marked running resumes at the next round when its last step was a finished tool (a tool
    /// in
    /// `doneToolIDs` never runs twice), otherwise it is dropped and she says nothing about it. A write that did not
    /// finish is not run again: the model reads that it was interrupted.
    public func resumeInterrupted() async {
        for var state in runs.all(now: now()) where state.status == .running {
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
                let uses = last.content.compactMap { piece -> (String, String)? in
                    if case let .toolUse(id, name, _) = piece {
                        (id, name)
                    } else {
                        nil
                    }
                }
                state.messages.append(BrainMessage(.user, uses.map { id, name in
                    if state.doneToolIDs.contains(id), let text = state.toolResults[id] {
                        return .toolResult(id: id, content: text, isError: false)
                    }
                    if name == TessOpenTool.name || name == "answerQuery" {
                        return .toolResult(id: id, content: "The phone was interrupted before this ran.", isError: true)
                    }
                    return .toolResult(
                        id: id,
                        content: "The phone was interrupted before this ran. Nothing was changed.",
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
