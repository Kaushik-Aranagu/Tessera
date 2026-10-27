import Foundation
import TesseraCore

// Tess's calls as an inherited template (Design sheet 288, section 6; docs/ai/harness/elements.md). `ElementCall` is
// the base: a call names only what differs from it (a tool that acts on nothing, on any rung, for any kind of thing,
// with a reaction). Every call on every place passes the same checks, so a new call that passes keeps every rule:
// the base case is the first call that passed, and the step is that the checks test the rules, not the call.
// `ElementCatalog.everyCall` is the registry: a Tess tool missing from it fails, so nothing escapes the checks.

@MainActor
public enum CallConformance {
    /// The checks one call fails on one place in one room, by name, or none.
    public static func failures(_ call: ElementCall, room: String, place: ElementPlace) -> [String] {
        var failed: [String] = []
        // Real: a Tess tool, `open`, a proposed tool, or the shell.
        let tool = TessTools.tool(named: call.name)
        switch call.kind {
        case .tool:
            if tool == nil, call.name != TessOpenTool.name, !ElementCatalog.proposed.contains(call.name) {
                failed.append("real")
            }
        case .shell:
            if !ElementCatalog.shellCalls.contains(call.name) {
                failed.append("real")
            }
        }
        // Reach: the call and its tool agree on money, so a device-only tool is never offered as an any-rung call.
        if let tool, tool.deviceOnly != (call.reach == .deviceOnly) {
            failed.append("reach")
        }
        // Inputs: each is an argument the tool or shell call takes.
        if let names = argumentNames(call), !Set(call.inputs.map(\.name)).isSubset(of: names) {
            failed.append("inputs")
        }
        // Bound: with nothing asked of him, the frame fills every input.
        let needsWords = call.inputs.contains { $0.source == .asked && $0.required }
        if !needsWords, ToolPicker.bind(call, at: place, frame: sample(for: call, room: room, place: place),
                                        pointed: false) == nil
        {
            failed.append("bound")
        }
        // Wall: a device-only call never reaches a rung beyond the phone, bound or open.
        if call.reach == .deviceOnly {
            let frame = sample(for: call, room: room, place: place)
            let claude: Set<BrainID> = [.haiku, .sonnet, .opus]
            let asks = Array(call.phrases.prefix(1)) + ["could you help me with this one please, it matters today"]
            for ask in asks {
                let pick = ToolPicker.pick(ask, frame: frame)
                if pick.tools.contains(call.name), pick.plan.ladder.contains(where: claude.contains) {
                    failed.append("wall")
                    break
                }
            }
        }
        return failed
    }

    /// Every Tess tool that no place offers: each must be on some place, or it escapes the checks.
    public static var unregistered: [String] {
        let placed = Set(ElementCatalog.everyCall.map(\.name))
        return TessTools.all.map(\.name).filter { !placed.contains($0) }
    }

    /// The argument names a call's tool or shell call takes; nil when it has no schema here (`open`, a proposed tool).
    static func argumentNames(_ call: ElementCall) -> Set<String>? {
        if let tool = TessTools.tool(named: call.name), case let .object(properties) = tool.input {
            return Set(properties.map { $0.0 })
        }
        guard call.kind == .shell, let spec = TessRun.shellSpecs().first(where: { $0.name == call.name }),
              let json = (try? JSONSerialization.jsonObject(with: spec.schema)) as? [String: Any],
              let properties = json["properties"] as? [String: Any] else { return nil }
        return Set(properties.keys)
    }

    /// A screen where the call is on its place with a thing it acts on in focus, a window and a door.
    static func sample(for call: ElementCall, room: String, place: ElementPlace) -> TessFrame {
        let item = ElementItem(id: UUID(), kind: call.kinds.sorted().first ?? "task", name: "Sample")
        var elements = [ElementMeaning(place: place, items: [item], focus: 0, calls: [call])]
        if place != .dial {
            elements.append(ElementMeaning(place: .dial, items: [ElementItem(kind: "door", name: "Plans")], focus: 0))
        }
        return TessFrame(room: room, window: "Tomorrow", elements: elements)
    }
}
