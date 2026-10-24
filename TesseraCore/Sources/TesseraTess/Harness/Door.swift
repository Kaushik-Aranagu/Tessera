import Foundation
import TesseraCore

/// One queue the Door reads: events tagged by the rung that made them. A rung that ends pushes a nil.
actor TaggedQueue {
    private var buffer: [(Int, BrainEvent?)] = []
    private var waiter: CheckedContinuation<(Int, BrainEvent?), Never>?

    func push(_ tag: Int, _ event: BrainEvent?) {
        if let waiter {
            self.waiter = nil
            waiter.resume(returning: (tag, event))
        } else {
            buffer.append((tag, event))
        }
    }

    func next() async -> (Int, BrainEvent?) {
        if !buffer.isEmpty {
            return buffer.removeFirst()
        }
        return await withCheckedContinuation { waiter = $0 }
    }
}

/// The one way to Claude (harness H1b). Steps, in order: policy, pack, key-shape scan, reserve, route, stream, check,
/// settle, trace, sent log. A Claude rung never starts unless "Tess asks Claude" is on, the $50 cap has room, and no
/// fragment holds a key-shaped string; the exact words of every Claude request go to "What was sent".
///
/// An actor in spirit: it is main-actor isolated because the ledger and the sent log are.
@MainActor
public final class Door {
    public let ledger: TessUsageLedger
    public let sentLog: TessSentLog
    public let trace: RunTrace
    public var router: BrainRouter
    public var policy: @MainActor () -> DoorPolicy
    public var asksClaude: @MainActor () -> Bool
    public var now: () -> Date = { .now }
    public var calendar: Calendar = .current

    public init(ledger: TessUsageLedger, sentLog: TessSentLog, trace: RunTrace, router: BrainRouter,
                policy: @escaping @MainActor () -> DoorPolicy, asksClaude: @escaping @MainActor () -> Bool)
    {
        self.ledger = ledger
        self.sentLog = sentLog
        self.trace = trace
        self.router = router
        self.policy = policy
        self.asksClaude = asksClaude
    }

    // MARK: Pack

    /// The request for a rung: the job's request plus the fragments that rung may carry, as one more text block on
    /// the last user message.
    func pack(_ job: DoorJob, policy: DoorPolicy, onClaude: Bool) -> BrainRequest {
        var request = job.request
        let text = job.fragments.filter { policy.allows($0, onClaude: onClaude) }.map(\.text)
        guard !text.isEmpty else { return request }
        let block = BrainContent.text(text.joined(separator: "\n"))
        if let last = request.messages.indices.last, request.messages[last].role == .user {
            request.messages[last].content.append(block)
        } else {
            request.messages.append(BrainMessage(.user, [block]))
        }
        return request
    }

    /// Every word the job would carry to any rung, for the key-shape scan.
    static func allText(_ job: DoorJob) -> [String] {
        job.request.system.map(\.text) + job.fragments.map(\.text) + requestText(job.request)
    }

    /// The text of a request apart from the system blocks: messages, tool_use inputs, tool results, and the tools'
    /// own names, descriptions and schemas.
    static func requestText(_ request: BrainRequest) -> [String] {
        request.messages.flatMap { message in
            message.content.compactMap { piece -> String? in
                switch piece {
                case let .text(text): text
                // A replayed block holds the model's own words and tool results: scanned for a key like the rest.
                case let .raw(data): String(decoding: data, as: UTF8.self)
                case let .toolResult(_, content, _): content
                case let .toolUse(_, _, input): String(decoding: input, as: UTF8.self)
                }
            }
        } + request.tools.flatMap { [$0.name, $0.description, String(decoding: $0.schema, as: UTF8.self)] }
    }

    /// Actions that move or record money. A model is never offered one, under either policy: money actions need his
    /// tap.
    static let moneyActions: Set<String> = [
        "logSpend", "editSpend", "logShopTotal", "skipShopTotal", "createPool", "logInflow", "reassignSpend", "logMove",
        "recordRate", "archivePool",
    ]

    /// Strict mode's own scan of everything a Claude rung would carry: the request's words, not only its fragments.
    func strictHit(_ request: BrainRequest) -> Bool {
        let lastKg = BodyWeight.lastKg(in: ledger.store)
        return (request.system.map(\.text) + Self.requestText(request)).contains { text in
            SecretWords.mentions(text) || PrivateFacts.isWalled(text, lastWeightKg: lastKg)
                || PrivateFacts.isCalorieShaped(text)
        }
    }

    /// The words of a request as sent, for the sent log.
    static func words(_ request: BrainRequest) -> String {
        (request.system.map(\.text) + request.messages.flatMap { message in
            message.content.compactMap { piece -> String? in
                switch piece {
                case let .text(text): text
                // A replayed block holds the model's own words and tool results: scanned for a key like the rest.
                case let .raw(data): String(decoding: data, as: UTF8.self)
                case let .toolResult(_, content, _): content
                case .toolUse: nil
                }
            }
        }).joined(separator: "\n\n")
    }

    // MARK: Run

    public func run(_ job: DoorJob) -> AsyncThrowingStream<BrainEvent, Error> {
        AsyncThrowingStream { continuation in
            let work = Task { @MainActor in
                await self.execute(job, continuation: continuation)
            }
            continuation.onTermination = { _ in work.cancel() }
        }
    }

    private struct Rung {
        var brain: any Brain
        var request: BrainRequest
        var reservation: TessUsageLedger.Reservation?
        var started: ContinuousClock.Instant
        var ttftMs: Int?
        var usage = BrainUsage()
        var status: Int?
        var outcome: ClaudeOutcome = .works
        var pump: Task<Void, Never>?
    }

    private func execute(_ job: DoorJob, continuation: AsyncThrowingStream<BrainEvent, Error>.Continuation) async {
        func end(_ outcome: ClaudeOutcome) {
            continuation.yield(.failed(outcome))
            continuation.finish()
        }
        // 1 policy, 2 pack (per rung, below), 3 key-shape scan: always, under both policies.
        let policy = policy()
        if Self.allText(job).contains(where: { looksLikeClaudeKey($0) }) {
            await trace.record(TraceSpan(kind: .brain, name: job.name, at: now(), totalMs: 0, outcome: "keyShape"))
            return end(.refused)
        }
        if job.request.tools.contains(where: { Self.moneyActions.contains($0.name) }) {
            await trace.record(TraceSpan(kind: .brain, name: job.name, at: now(), totalMs: 0, outcome: "moneyAction"))
            return end(.refused)
        }
        let asks = asksClaude()
        let candidates = await router.candidates(for: job.ladder, asksClaude: asks)
        guard !candidates.isEmpty else {
            let onlyClaude = job.ladder.allSatisfy(BrainRouter.isClaude)
            return end(onlyClaude && !asks ? .notAllowed : .other)
        }
        var lastOutcome: ClaudeOutcome = .other
        var skipped = Set<Int>()
        for index in candidates.indices where !skipped.contains(index) {
            // A hedge starts the next rung too, but only for Sonnet first and Haiku second.
            var group = [index]
            if job.hedge, candidates[index].id == .sonnet, index + 1 < candidates.count,
               candidates[index + 1].id == .haiku
            {
                group.append(index + 1)
            }
            let result = await attempt(job, brains: group.map { candidates[$0] }, policy: policy,
                                       continuation: continuation)
            switch result {
            case .answered:
                return continuation.finish()
            case let .failed(outcome, sentAnything):
                lastOutcome = outcome
                if sentAnything {
                    return end(outcome)
                }
                skipped.formUnion(group)
            }
        }
        end(lastOutcome)
    }

    private enum Attempt {
        case answered
        case failed(ClaudeOutcome, sentAnything: Bool)
    }

    /// Runs one rung, or two raced rungs (the hedge). Forwards the winner's events.
    private func attempt(_ job: DoorJob, brains: [any Brain], policy: DoorPolicy,
                         continuation: AsyncThrowingStream<BrainEvent, Error>.Continuation) async -> Attempt
    {
        let queue = TaggedQueue()
        var rungs: [Int: Rung] = [:]
        var alive = Set<Int>()
        var failure: ClaudeOutcome = .other
        var winner: Int?
        var hedgeStarted = brains.count == 1
        var tick: Task<Void, Never>?

        func start(_ tag: Int) -> Bool {
            let brain = brains[tag]
            let claude = BrainRouter.isClaude(brain.id)
            let request = pack(job, policy: policy, onClaude: claude)
            var reservation: TessUsageLedger.Reservation?
            if claude, policy == .strict, strictHit(request) {
                // Strict: his own words in the request are judged too, not only the fragments.
                failure = .refused
                return false
            }
            if claude {
                // The $50 cap refuses before any network.
                guard let held = ledger.reserve(job.estimateNano, now: now(), calendar: calendar) else {
                    failure = .capReached
                    return false
                }
                reservation = held
                // The exact words, as sent, before they go.
                sentLog.record(words: Self.words(request), use: .door, requestID: nil, at: now(), exact: policy == .lab)
            }
            var rung = Rung(brain: brain, request: request, reservation: reservation, started: .now)
            let stream = brain.stream(request)
            rung.pump = Task {
                do {
                    for try await event in stream {
                        await queue.push(tag, event)
                    }
                } catch {
                    await queue.push(tag, .failed(.other))
                }
                await queue.push(tag, nil)
            }
            rungs[tag] = rung
            alive.insert(tag)
            return true
        }

        func finish(_ tag: Int, cancelled: Bool = false) async {
            guard var rung = rungs.removeValue(forKey: tag) else { return }
            rung.pump?.cancel()
            let total = LatencyBench.ms(.now - rung.started)
            if cancelled {
                rung.outcome = .cancelled
                // A cancelled rung may have been billed up to what was held for it: it is recorded at that estimate.
                rung.usage.costNano = max(rung.usage.costNano, job.estimateNano)
            }
            if let held = rung.reservation {
                ledger.settle(held)
                ledger.record(use: .door, model: Self.modelName(rung.brain) ?? "", input: rung.usage.inTokens,
                              output: rung.usage.outTokens, costNano: rung.usage.costNano,
                              latency: Double(total) / 1000, outcome: rung.outcome.rawValue, requestID: nil,
                              at: now())
            }
            await trace.record(TraceSpan(kind: .brain, name: job.name, brain: rung.brain.id.rawValue,
                                         model: Self.modelName(rung.brain), at: now(), ttftMs: rung.ttftMs,
                                         totalMs: total, usage: rung.usage,
                                         outcome: rung.status.map { "\(rung.outcome.rawValue) \($0)" }
                                             ?? rung.outcome.rawValue))
        }

        if !start(0) {
            return .failed(failure, sentAnything: false)
        }
        if !hedgeStarted {
            let wait = router.hedgeAfter
            tick = Task {
                await router.sleep(wait)
                guard !Task.isCancelled else { return }
                await queue.push(-1, .status(0))
            }
        }
        var sent = false
        while true {
            let (tag, event) = await queue.next()
            if tag == -1 {
                // No first token yet: start the second rung too, if the cap allows.
                if winner == nil, !hedgeStarted {
                    hedgeStarted = true
                    _ = start(1)
                }
                continue
            }
            if let winner, tag != winner {
                continue
            }
            guard let event else {
                // This rung ended.
                alive.remove(tag)
                if tag == winner {
                    tick?.cancel()
                    await finish(tag)
                    for other in Array(rungs.keys) {
                        await finish(other, cancelled: true)
                    }
                    return .answered
                }
                await finish(tag)
                if alive.isEmpty, winner == nil {
                    tick?.cancel()
                    return .failed(failure, sentAnything: sent)
                }
                continue
            }
            switch event {
            case let .status(code):
                rungs[tag]?.status = code
            case let .failed(outcome):
                rungs[tag]?.outcome = outcome
                failure = outcome
                if tag == winner {
                    sent = true
                    continuation.yield(event)
                    tick?.cancel()
                    await finish(tag)
                    return .failed(outcome, sentAnything: true)
                }
                alive.remove(tag)
                await finish(tag)
                if alive.isEmpty, winner == nil {
                    tick?.cancel()
                    // The hedge partner may not have been started yet; a lone failure ends this attempt.
                    return .failed(outcome, sentAnything: false)
                }
            case let .toolUse(_, _, input) where !job.validator(input):
                // The job refuses this call: a failure of the rung, before anything was passed on.
                rungs[tag]?.outcome = .other
                failure = .other
                alive.remove(tag)
                await finish(tag)
                if tag == winner {
                    return .failed(.other, sentAnything: sent)
                }
                if alive.isEmpty {
                    tick?.cancel()
                    return .failed(.other, sentAnything: sent)
                }
            case .assistant:
                if winner == nil {
                    winner = tag
                    tick?.cancel()
                    for other in Array(rungs.keys) where other != tag {
                        await finish(other, cancelled: true)
                        alive.remove(other)
                    }
                }
                sent = true
                continuation.yield(event)
            case let .done(usage, stop: stop):
                if winner == nil {
                    winner = tag
                    tick?.cancel()
                    for other in Array(rungs.keys) where other != tag {
                        await finish(other, cancelled: true)
                        alive.remove(other)
                    }
                }
                rungs[tag]?.usage = usage
                continuation.yield(.done(usage, stop: stop))
                sent = true
            case .text, .toolUse:
                if winner == nil {
                    winner = tag
                    tick?.cancel()
                    for other in Array(rungs.keys) where other != tag {
                        await finish(other, cancelled: true)
                        alive.remove(other)
                    }
                }
                if rungs[tag]?.ttftMs == nil, let started = rungs[tag]?.started {
                    rungs[tag]?.ttftMs = LatencyBench.ms(.now - started)
                }
                sent = true
                continuation.yield(event)
            }
        }
    }

    private static func modelName(_ brain: any Brain) -> String? {
        switch brain.id {
        case .haiku: ClaudeBrain.Model.haiku.rawValue
        case .sonnet: ClaudeBrain.Model.sonnet.rawValue
        default: nil
        }
    }

    // MARK: Warm

    /// Warms a rung through the same gate as a call: Claude only when allowed, a reserve before and a ledger row and
    /// a span after, so the cap sees it. Returns what the warm-up got (status and the `max_tokens` that worked).
    @discardableResult
    public func warm(_ id: BrainID, _ prefix: BrainRequest, name: String = "warm") async -> BrainWarm? {
        guard let brain = router.provider(id) else { return nil }
        let claude = BrainRouter.isClaude(id)
        guard !claude || asksClaude() else { return nil }
        var reservation: TessUsageLedger.Reservation?
        if claude {
            let estimate = TessUsageLedger.estimate(text: Self.words(prefix), maxTokens: 1,
                                                    model: Self.modelName(brain) ?? "")
            guard let held = ledger.reserve(estimate, now: now(), calendar: calendar) else { return nil }
            reservation = held
        }
        let started = ContinuousClock.now
        let result = await brain.warm(prefix)
        let total = LatencyBench.ms(.now - started)
        if let reservation {
            ledger.settle(reservation)
        }
        if claude, let result {
            ledger.record(use: .door, model: Self.modelName(brain) ?? "", input: result.usage.inTokens,
                          output: result.usage.outTokens, costNano: result.usage.costNano,
                          latency: Double(total) / 1000, outcome: result.status == 200 ? "works" : "other",
                          requestID: nil, at: now())
        }
        await trace.record(TraceSpan(kind: .brain, name: name, brain: id.rawValue, model: Self.modelName(brain),
                                     at: now(), totalMs: total, usage: result?.usage ?? BrainUsage(),
                                     outcome: result.map { "warm \($0.status) max_tokens \($0.maxTokens)" } ?? "none"))
        return result
    }
}
