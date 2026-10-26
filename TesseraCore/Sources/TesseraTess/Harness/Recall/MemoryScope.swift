import Foundation
import TesseraCore

/// Which memory one agent may read and write (docs/ai/harness/memory-scopes.md). Memory is virtualized:
/// - **Shared:** the record (his objects) and the beliefs, read by every agent through its own slice. A room agent
///   sees its room's classes and the beliefs about him; Tess sees every room. The Door's policy cuts both: under
///   strict, money, body, health and calendar never enter a slice.
/// - **Private:** each agent's own notebook folder (`/memories/<agent>/`). Only that agent reads or writes it. Tess
///   reads a room agent's notebook only by asking that agent, the way she would ask a colleague.
///
/// A belief marked "stays on this phone" is in no slice: it never reaches a model.
public struct MemoryScope: Sendable, Equatable {
    /// The agent's name, as in `AgentSpec`.
    public var agent: String
    /// The classes its shared slice reads; nil is every class (Tess, the front desk).
    public var classes: Set<SystemCatalog.Key>?
    /// Its private folder, with no trailing slash ("/memories/deck").
    public var notebook: String
    public var policy: DoorPolicy

    public init(agent: String, classes: Set<SystemCatalog.Key>?, notebook: String, policy: DoorPolicy) {
        self.agent = agent
        self.classes = classes
        self.notebook = notebook
        self.policy = policy
    }

    /// An agent's scope under a policy. Tess's spec lists no belief classes, which means every room; a room agent
    /// reads its own classes, minus what strict keeps on the phone.
    public init(_ spec: AgentSpec, policy: DoorPolicy) {
        let own = spec.beliefClasses(under: policy)
        self.init(agent: spec.name, classes: spec.room == AgentSpec.tess.room ? nil : Set(own),
                  notebook: spec.notebook, policy: policy)
    }

    /// The system's own bookkeeping never enters a slice: turns, sent rows, settings, the profile and the memory lines
    /// that beliefs already carry.
    static let neverRead: Set<SystemCatalog.Key> = [
        .tessTurn, .tessCall, .tessSent, .tessSentExact, .tessWaiting, .tessMemory, .settings, .meProfile, .heldNotice,
        .closedDay,
    ]

    /// Whether an object of `classDef` is in this slice. A subclass counts as its parent (a barbell lift is an
    /// exercise).
    @MainActor
    public func reads(_ classDef: ClassDef?, classes all: [SystemCatalog.Key: ClassDef]) -> Bool {
        guard let classDef else { return false }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            all[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
        if Self.neverRead.contains(where: isA) {
            return false
        }
        let labOnly = AgentSpec.labOnlyBeliefs.contains(where: isA) || ClassResolver.app(for: classDef) == .money
        if policy == .strict, labOnly {
            return false
        }
        guard let classes else { return true }
        return classes.contains(where: isA)
    }

    /// Whether `path` is inside this agent's own notebook folder.
    public func owns(_ path: String) -> Bool {
        let normalized = Self.normalize(path)
        return normalized.hasPrefix(notebook + "/") && !normalized.contains("/../") && !normalized.hasSuffix("/..")
    }

    /// Whether `path` is some agent's notebook (so it is private to that agent).
    public static func isNotebook(_ path: String) -> Bool {
        normalize(path).hasPrefix("/memories/")
    }

    static func normalize(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespaces)
        let rooted = trimmed.hasPrefix("/") ? trimmed : "/" + trimmed
        return rooted.lowercased()
    }
}
