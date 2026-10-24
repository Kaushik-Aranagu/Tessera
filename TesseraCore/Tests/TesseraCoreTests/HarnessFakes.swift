import Foundation
@testable import TesseraCore
@testable import TesseraTess

/// A scripted brain for the harness tests: answers after a fixed delay, records what it was asked.
final class FakeBrain: Brain, @unchecked Sendable {
    let id: BrainID
    var available = true
    var outcome: ClaudeOutcome = .works
    /// Wait before the first word.
    var firstDelay: Duration = .zero
    var reply = "ok"
    var toolInput: Data?
    /// Called when a stream starts (on whatever thread), with the request.
    var onStream: (@Sendable (BrainRequest) -> Void)?
    private let lock = NSLock()
    private var streamed = 0
    private var warmed = 0
    private var requests: [BrainRequest] = []
    private(set) var cancelled = false

    init(_ id: BrainID = .haiku) {
        self.id = id
    }

    var isAvailable: Bool {
        get async { available }
    }

    var streamCount: Int {
        lock.withLock { streamed }
    }

    var warmCount: Int {
        lock.withLock { warmed }
    }

    var lastRequest: BrainRequest? {
        lock.withLock { requests.last }
    }

    func stream(_ request: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error> {
        lock.withLock {
            streamed += 1
            requests.append(request)
        }
        onStream?(request)
        let outcome = outcome, delay = firstDelay, reply = reply, tool = toolInput
        return AsyncThrowingStream { continuation in
            let work = Task {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                if Self.isClaude(self.id) {
                    continuation.yield(.status(outcome == .works ? 200 : 500))
                }
                if outcome != .works {
                    continuation.yield(.failed(outcome))
                } else {
                    if let tool {
                        continuation.yield(.toolUse(id: "t1", name: "setPlaybook", input: tool))
                    } else {
                        continuation.yield(.text(reply))
                    }
                    continuation.yield(.done(
                        BrainUsage(inTokens: 300, outTokens: 50, costNano: 40000),
                        stop: "end_turn"
                    ))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                work.cancel()
                self.lock.withLock { self.cancelled = true }
            }
        }
    }

    func warm(_: BrainRequest) async -> BrainWarm? {
        lock.withLock { warmed += 1 }
        return Self.isClaude(id) ? BrainWarm(
            status: 200,
            maxTokens: 0,
            usage: BrainUsage(inTokens: 3000, costNano: 1000)
        ) : nil
    }

    static func isClaude(_ id: BrainID) -> Bool {
        id == .haiku || id == .sonnet || id == .opus
    }
}

/// A Door over fake brains, with its ledger, sent log and trace.
@MainActor
struct DoorRig {
    let store: ObjectStore
    let classes: [SystemCatalog.Key: ClassDef]
    let trace = RunTrace(url: nil)
    let door: Door
    var ledger: TessUsageLedger {
        TessUsageLedger(store: store, classes: classes)
    }

    var sent: TessSentLog {
        TessSentLog(store: store, classes: classes)
    }

    /// `hedgeWait`: nil means the wait never ends (until cancelled); `.zero` means it is over at once. A fake clock:
    /// no real time decides which rung streams first.
    init(brains: [BrainID: any Brain], asks: Bool = true, policy: DoorPolicy = .lab,
         hedgeWait: Duration? = nil) throws
    {
        let store = ObjectStore.open(inMemory: true)
        let classes = try store.prepareCatalog()
        self.store = store
        self.classes = classes
        let router = BrainRouter(hedgeAfter: hedgeWait ?? .seconds(1), sleep: { _ in
            if hedgeWait == nil {
                try? await Task.sleep(for: .seconds(3600))
            }
        }) { brains[$0] }
        door = Door(ledger: TessUsageLedger(store: store, classes: classes),
                    sentLog: TessSentLog(store: store, classes: classes), trace: trace, router: router,
                    policy: { policy }, asksClaude: { asks })
    }

    func events(_ job: DoorJob) async -> [BrainEvent] {
        var found: [BrainEvent] = []
        do {
            for try await event in door.run(job) {
                found.append(event)
            }
        } catch {}
        return found
    }
}

extension [BrainEvent] {
    var text: String {
        compactMap {
            if case let .text(piece) = $0 {
                piece
            } else {
                nil
            }
        }.joined()
    }

    var failure: ClaudeOutcome? {
        compactMap {
            if case let .failed(outcome) = $0 {
                outcome
            } else {
                nil
            }
        }.first
    }

    var finished: Bool {
        contains {
            if case .done = $0 {
                true
            } else {
                false
            }
        }
    }
}

/// A brain that plays a script: one array of events per round (the next round starts when the last was asked for).
final class ScriptedBrain: Brain, @unchecked Sendable {
    let id: BrainID
    var available = true
    /// Wait before the first event of every round.
    var delay: Duration = .zero
    private let lock = NSLock()
    private var rounds: [[BrainEvent]]
    private var requests: [BrainRequest] = []
    private var warmed = 0

    init(_ id: BrainID = .haiku, rounds: [[BrainEvent]]) {
        self.id = id
        self.rounds = rounds
    }

    var isAvailable: Bool {
        get async { available }
    }

    var requestsSeen: [BrainRequest] {
        lock.withLock { requests }
    }

    var streamCount: Int {
        requestsSeen.count
    }

    var warmCount: Int {
        lock.withLock { warmed }
    }

    func stream(_ request: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error> {
        let script: [BrainEvent] = lock.withLock {
            requests.append(request)
            return rounds.isEmpty ? [.text("ok")] : rounds.removeFirst()
        }
        let wait = delay
        return AsyncThrowingStream { continuation in
            let work = Task {
                try? await Task.sleep(for: wait)
                if FakeBrain.isClaude(self.id) {
                    continuation.yield(.status(200))
                }
                for event in script {
                    guard !Task.isCancelled else { return }
                    continuation.yield(event)
                }
                // A script that ends with its own done (a paused turn) keeps its stop reason.
                if !script.contains(where: {
                    if case .done = $0 {
                        true
                    } else {
                        false
                    }
                }) {
                    continuation.yield(.done(
                        BrainUsage(inTokens: 100, outTokens: 20, costNano: 20000),
                        stop: "end_turn"
                    ))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in work.cancel() }
        }
    }

    func warm(_: BrainRequest) async -> BrainWarm? {
        lock.withLock { warmed += 1 }
        return FakeBrain.isClaude(id) ? BrainWarm(
            status: 200,
            maxTokens: 0,
            usage: BrainUsage(inTokens: 500, costNano: 100)
        ) : nil
    }
}
