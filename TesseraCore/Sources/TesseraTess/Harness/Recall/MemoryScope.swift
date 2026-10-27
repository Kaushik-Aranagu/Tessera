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
    /// Kinds it reads beyond the system classes: a spawned room's own kind and its subclasses.
    public var classIDs: Set<UUID>
    /// Its private folder, with no trailing slash ("/memories/deck").
    public var notebook: String
    public var policy: DoorPolicy

    public init(agent: String, classes: Set<SystemCatalog.Key>?, classIDs: Set<UUID> = [], notebook: String,
                policy: DoorPolicy)
    {
        self.agent = agent
        self.classes = classes
        self.classIDs = classIDs
        // Paths are compared lowercased, so the folder is too.
        self.notebook = Self.normalize(notebook)
        self.policy = policy
    }

    /// An agent's scope under a policy. Tess's spec lists no belief classes, which means every room; a room agent
    /// reads its own classes, minus what strict keeps on the phone.
    public init(_ spec: AgentSpec, policy: DoorPolicy) {
        let own = spec.beliefClasses(under: policy)
        self.init(agent: spec.name, classes: spec.room == AgentSpec.tess.room ? nil : Set(own),
                  classIDs: Set(spec.classIDs), notebook: spec.notebook, policy: policy)
    }

    /// The system's own bookkeeping never enters a slice: turns, sent rows, settings, the profile and the memory lines
    /// that beliefs already carry.
    static var neverRead: Set<SystemCatalog.Key> {
        ClassPolicy.neverReadKeys
    }

    /// What strict keeps on the phone beyond the lab-only belief classes: the calendar and Health mirrors and held
    /// notices (their titles are free text the Door's scan can't read), and meal numbers. `strictRawKeys` names system
    /// classes by key so a class that lands later (meal nutrition) is walled the day it exists.
    static let strictNever: Set<SystemCatalog.Key> = [.event, .sleepNight, .stepsDay, .restingHeartRate, .heldNotice]
    static let strictRawKeys: Set<String> = ["mealNutrition", "nutrition", "nutritionRow"]
    /// Never in any slice, by key, for classes that may land after this file (meal numbers are never recalled).
    static let neverRawKeys: Set<String> = ["mealNutrition"]

    /// Whether `classDef` or a class above it has one of these system keys.
    @MainActor
    static func lineage(_ classDef: ClassDef, has keys: Set<String>) -> Bool {
        ClassResolver.lineage(of: classDef).contains { node in
            node.systemKey.map { keys.contains(String($0.dropFirst("system.".count))) } ?? false
        }
    }

    /// Whether an object of `classDef` is in this slice. A subclass counts as its parent (a barbell lift is an
    /// exercise).
    @MainActor
    public func reads(_ classDef: ClassDef?, classes all: [SystemCatalog.Key: ClassDef]) -> Bool {
        guard let classDef else { return false }
        func isA(_ key: SystemCatalog.Key) -> Bool {
            all[key].map { ClassResolver.isSubclass(classDef, of: $0) } ?? false
        }
        if Self.neverRead.contains(where: isA) || Self.lineage(classDef, has: Self.neverRawKeys) {
            return false
        }
        let labOnly = AgentSpec.labOnlyBeliefs.contains(where: isA) || ClassResolver.app(for: classDef) == .money
            || Self.strictNever.contains(where: isA) || Self.lineage(classDef, has: Self.strictRawKeys)
        if policy == .strict, labOnly {
            return false
        }
        guard let classes else { return true }
        return classes.contains(where: isA) || classIDs.contains { ClassResolver.isSubclass(classDef, ofClassID: $0) }
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
