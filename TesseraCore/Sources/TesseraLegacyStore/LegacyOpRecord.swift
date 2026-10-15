import Foundation
import SwiftData
import TesseraCore

/// One entry in the append-only operation log: a typed action, who did it, and the ops it applied.
/// State tables (objects, links) are the fast cache; this log is the history behind undo, receipts and export.
@Model
final class OpRecord {
    var id: UUID = UUID()
    /// The typed action's name, e.g. "logSet".
    var action: String = ""
    var actorRaw: String = Actor.user.rawValue
    var stateRaw: String = OpState.committed.rawValue
    /// One line, in Tess's voice, for receipts: "Logged bench press 82.5 × 8".
    var summary: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    /// The encoded `[Op]`, in the order applied.
    var opsData: Data?
    /// Objects this action touched, for "what changed this?" lookups.
    var objectIDs: [UUID] = []

    init(action: String, actor: Actor, summary: String, ops: [Op], state: OpState) {
        id = .v7()
        self.action = action
        actorRaw = actor.rawValue
        self.summary = summary
        stateRaw = state.rawValue
        opsData = try? JSONEncoder().encode(ops)
        var seen = Set<UUID>()
        objectIDs = ops.map(\.objectID).filter { seen.insert($0).inserted }
    }

    var actor: Actor {
        Actor(rawValue: actorRaw) ?? .user
    }

    var state: OpState {
        get { OpState(rawValue: stateRaw) ?? .committed }
        set {
            stateRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    var ops: [Op] {
        opsData.flatMap { try? JSONDecoder().decode([Op].self, from: $0) } ?? []
    }
}
