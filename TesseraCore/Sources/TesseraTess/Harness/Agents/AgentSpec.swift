import Foundation
import TesseraCore

/// Memory spec M4: an agent is data, not a process. A run starts by compiling from its spec, its beliefs slice, its
/// notebook, its budget row and its expertise pack, so an agent "remembers" without a long-lived process. Tess is
/// the only voice: room agents return Reports (H4), never words to him.
///
/// These are the shipped specs as values. A later step mirrors them into a system class under
/// `/system/tess/agents`, so he can see each agent as an object; the values stay the source.
public struct AgentSpec: Sendable, Equatable, Identifiable {
    /// The summaries an agent's memory slice reads.
    public enum Summary: String, Sendable, CaseIterable {
        case day, week, month
    }

    /// Which expertise pack the agent carries (`ExpertisePack`). Nil until its room has one.
    public enum Expertise: String, Sendable {
        case training, kitchen
    }

    /// The agent's name, and its row in `BudgetTable` (lowercased).
    public var name: String
    /// What it answers for: an app ("training"), "today", "body", or "tess" for the front desk.
    public var room: String
    /// Lookups, counts, small actions and classification: Haiku first (his rule: never a big model on a simple task).
    public var plain: RungPlan
    /// Anything open, anything across days, and every write that changes more than one object: Sonnet first.
    public var open: RungPlan
    /// Tool names it may call. No agent ever gets a money write tool.
    public var tools: [String]
    /// The classes its beliefs slice is about (beliefs about him with no subject go to every agent).
    public var beliefClasses: [SystemCatalog.Key]
    /// Its notebook folder, for the memory tool (M2): it can't write outside it.
    public var notebook: String
    public var summaries: [Summary]
    public var expertise: Expertise?
    public var maxRounds: Int
    /// Sub-agents it may start in one run (H4), and how deep the tree may go from Tess.
    public var maxChildren: Int
    public var depth: Int
    /// Health, body, calories, sleep and money: only under lab mode (his pick, Oct 23). Strict has no Body or Money
    /// agent.
    public var labOnly: Bool

    public var id: String {
        name
    }

    public var budgetKey: String {
        name.lowercased()
    }

    // MARK: Shipped agents

    /// The tools every agent reads with. `recall`, `remember`, `web_search` and `web_fetch` arrive with M2.
    static let reads = ["query", "open", "recall"]
    static let web = ["web_search", "web_fetch"]

    public static let tess = AgentSpec(
        name: "Tess", room: "tess", plain: .plain, open: .open,
        tools: reads + web + ["remember", "ask_agent", "createTask", "completeTask", "rescheduleTask", "createNote",
                              "addToList", "addGroceries", "logSet"],
        beliefClasses: [], notebook: "/memories/tess", summaries: Summary.allCases, expertise: nil,
        maxRounds: 10, maxChildren: 3, depth: 0, labOnly: false
    )

    public static let training = AgentSpec(
        name: "Training", room: AppID.training.rawValue, plain: .plain, open: .open,
        tools: reads + ["remember", "logSet", "createNote"],
        beliefClasses: [.workout, .exercise, .routine, .plan, .set, .muscle], notebook: "/memories/training",
        summaries: Summary.allCases, expertise: .training, maxRounds: 8, maxChildren: 3, depth: 1, labOnly: false
    )

    public static let kitchen = AgentSpec(
        name: "Kitchen", room: AppID.kitchen.rawValue, plain: .plain, open: .open,
        tools: reads + web + ["remember", "createRecipe", "addGroceries", "addToList", "cookTogether",
                              "setServeTime", "startShop", "createTask"],
        beliefClasses: [.recipe, .ingredient, .cook, .cookSession, .place], notebook: "/memories/kitchen",
        summaries: Summary.allCases, expertise: .kitchen, maxRounds: 8, maxChildren: 3, depth: 1, labOnly: false
    )

    public static let today = AgentSpec(
        name: "Today", room: "today", plain: .plain, open: .open,
        tools: reads + ["remember", "createTask", "completeTask", "rescheduleTask", "addToList", "createList"],
        beliefClasses: [.task, .list, .listItem, .routine, .occasion], notebook: "/memories/today",
        summaries: [.day, .week], expertise: nil, maxRounds: 8, maxChildren: 3, depth: 1, labOnly: false
    )

    public static let notes = AgentSpec(
        name: "Notes", room: AppID.notes.rawValue, plain: .plain, open: .open,
        tools: reads + ["remember", "createNote"],
        beliefClasses: [.note], notebook: "/memories/notes", summaries: [.week, .month], expertise: nil,
        maxRounds: 8, maxChildren: 3, depth: 1, labOnly: false
    )

    /// Read only, always: money actions are never offered to Claude (his standing rule). Lab only, like Body: under
    /// strict no money detail reaches Claude, so there is nothing for it to read.
    public static let money = AgentSpec(
        name: "Money", room: AppID.money.rawValue, plain: .plain, open: .open,
        tools: reads + ["remember"],
        beliefClasses: [.spend, .pool, .inflow, .poolMove], notebook: "/memories/money", summaries: [.week, .month],
        expertise: nil, maxRounds: 8, maxChildren: 3, depth: 1, labOnly: true
    )

    public static let body = AgentSpec(
        name: "Body", room: "body", plain: .plain, open: .open,
        tools: reads + ["remember"],
        beliefClasses: [.sleepNight, .stepsDay, .restingHeartRate], notebook: "/memories/body",
        summaries: Summary.allCases, expertise: nil, maxRounds: 8, maxChildren: 3, depth: 1, labOnly: true
    )

    public static let shipped: [AgentSpec] = [tess, training, kitchen, today, notes, money, body]

    /// The agents a policy allows: strict has no Body or Money agent.
    public static func available(under policy: DoorPolicy) -> [AgentSpec] {
        shipped.filter { !$0.labOnly || policy == .lab }
    }

    /// Belief classes only lab may send: calendar, body and money. Under strict their beliefs stay on the phone.
    public static let labOnlyBeliefs: Set<SystemCatalog.Key> = [
        .occasion, .sleepNight, .stepsDay, .restingHeartRate, .spend, .pool, .inflow, .poolMove,
    ]

    /// The classes its beliefs slice reads under a policy: strict drops the lab-only ones (Today's calendar).
    public func beliefClasses(under policy: DoorPolicy) -> [SystemCatalog.Key] {
        policy == .lab ? beliefClasses : beliefClasses.filter { !Self.labOnlyBeliefs.contains($0) }
    }

    public static func named(_ name: String) -> AgentSpec? {
        shipped.first { $0.name.lowercased() == name.lowercased() }
    }

    // MARK: Checks

    /// Every tool name an agent may list: the Tess tools, `open`, and the M2 fetch, memory and delegation tools.
    @MainActor
    public static var knownTools: Set<String> {
        Set(TessRun.toolSpecs().map(\.name)).union(["query", "open", "recall", "remember", "ask_agent"] + web)
    }

    /// What is wrong with a spec, in plain words; empty when it compiles.
    @MainActor
    public func problems() -> [String] {
        var out: [String] = []
        for (kind, plan) in [("plain", plain), ("open", open)] {
            if plan.ladder.first == .opus {
                out.append("\(name): the \(kind) ladder starts with Opus, which is an escalation rung only")
            }
            if let opus = plan.ladder.firstIndex(of: .opus),
               !plan.ladder[..<opus].contains(.sonnet)
            {
                out.append("\(name): Opus on the \(kind) ladder isn't after Sonnet")
            }
        }
        let money = Set(tools).intersection(Door.moneyActions)
        if !money.isEmpty {
            out.append("\(name): money actions are never offered to Claude (\(money.sorted().joined(separator: ", ")))")
        }
        let unknown = Set(tools).subtracting(Self.knownTools)
        if !unknown.isEmpty {
            out.append("\(name): unknown tools \(unknown.sorted().joined(separator: ", "))")
        }
        if Set(tools).count != tools.count {
            out.append("\(name): a tool is listed twice")
        }
        if maxRounds < 1 || maxRounds > TessRun.maxRounds {
            out.append("\(name): \(maxRounds) rounds is outside 1 to \(TessRun.maxRounds)")
        }
        if maxChildren > 3 || depth > 2 || (depth == 2 && maxChildren > 0) {
            out.append("\(name): sub-agents go at most 3 wide and 2 deep")
        }
        if !notebook.hasPrefix("/memories/") {
            out.append("\(name): its notebook must live under /memories/")
        }
        return out
    }

    /// Problems across the shipped set: each spec's own, plus names that clash.
    @MainActor
    public static func problems(_ specs: [AgentSpec] = shipped) -> [String] {
        var out = specs.flatMap { $0.problems() }
        let names = specs.map(\.budgetKey)
        if Set(names).count != names.count {
            out.append("two agents share a name")
        }
        let notebooks = specs.map(\.notebook)
        if Set(notebooks).count != notebooks.count {
            out.append("two agents share a notebook")
        }
        return out
    }
}
