import Foundation
import TesseraCore

/// A brain that sends every request through the Door, for a job written against `Brain` (the room job, an eval): the
/// policy, the key-shape scan, the money-action wall, the $100 reserve before any network, the sent log and a ledger
/// row after, exactly as for any other call. It adds no rules of its own and never calls a model directly.
public struct DoorBrain: Brain {
    public let door: Door
    /// The span and ledger name of each call.
    public let name: String
    /// The rungs the Door tries, in order.
    public let ladder: [BrainID]

    public init(door: Door, name: String, ladder: [BrainID] = [.haiku]) {
        self.door = door
        self.name = name
        self.ladder = ladder
    }

    public var id: BrainID {
        ladder.first ?? .haiku
    }

    /// The Door decides at call time which rung can answer.
    public var isAvailable: Bool {
        true
    }

    public func stream(_ request: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error> {
        AsyncThrowingStream { continuation in
            let work = Task { @MainActor in
                let estimate = Self.estimate(request, on: ladder)
                let job = DoorJob(name: name, ladder: ladder, request: request, estimateNano: estimate)
                do {
                    for try await event in door.run(job) {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in work.cancel() }
        }
    }

    /// Nothing is warmed: a warm-up would be a call the job did not ask for.
    public func warm(_: BrainRequest) async -> BrainWarm? {
        nil
    }

    /// What the Door holds before it sends: the words and the tool schemas at the dearest rung's price, with the whole
    /// `max_tokens` counted as output, so the cap is never passed by a call that runs long.
    @MainActor
    static func estimate(_ request: BrainRequest, on ladder: [BrainID]) -> Int64 {
        let schemas = request.tools.map { String(decoding: $0.schema, as: UTF8.self) }.joined(separator: "\n")
        let text = Door.words(request) + "\n" + schemas
        let models: [String] = ladder.compactMap { id in
            switch id {
            case .haiku: ClaudeBrain.Model.haiku.rawValue
            case .sonnet: ClaudeBrain.Model.sonnet.rawValue
            case .opus: ClaudeBrain.Model.opus.rawValue
            default: nil
            }
        }
        return models.map { TessUsageLedger.estimate(text: text, maxTokens: request.maxTokens, model: $0) }.max() ?? 0
    }
}
