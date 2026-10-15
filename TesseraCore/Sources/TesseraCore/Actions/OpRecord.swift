import Foundation
import SwiftData

/// One entry in the append-only operation log: a typed action, who did it, and the ops it applied.
/// State tables (objects, links) are the fast cache; this log is the history behind undo, receipts and export.
@Model
public final class OpRecord {
    public var id: UUID = UUID()
    /// The typed action's name, e.g. "logSet".
    public var action: String = ""
    public var actorRaw: String = Actor.user.rawValue
    public var stateRaw: String = OpState.committed.rawValue
    /// One line, in Tess's voice, for receipts: "Logged bench press 82.5 × 8".
    public var summary: String = ""
    public var createdAt: Date = Date.now
    public var updatedAt: Date = Date.now
    /// The encoded `[Op]`, in the order applied.
    public var opsData: Data?
    /// Objects this action touched, for "what changed this?" lookups.
    public var objectIDs: [UUID] = []

    public init(action: String, actor: Actor, summary: String, ops: [Op], state: OpState) {
        self.action = action
        actorRaw = actor.rawValue
        self.summary = summary
        stateRaw = state.rawValue
        opsData = try? JSONEncoder().encode(ops)
        var seen = Set<UUID>()
        objectIDs = ops.map(\.objectID).filter { seen.insert($0).inserted }
    }

    public var actor: Actor {
        Actor(rawValue: actorRaw) ?? .user
    }

    public var state: OpState {
        get { OpState(rawValue: stateRaw) ?? .committed }
        set {
            stateRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    public var ops: [Op] {
        opsData.flatMap { try? JSONDecoder().decode([Op].self, from: $0) } ?? []
    }
}
