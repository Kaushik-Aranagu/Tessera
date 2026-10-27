import Foundation
import TesseraCore

/// Picks the calls Tess gets for one ask from where he is (`TessFrame`): the calls the screen offers first, then the
/// room agent's tools, then the reads. Fewer, better-fitting tools are the accuracy rule (a model with 20 tools picks
/// wrong more often than one with 6). When the ask names one call the screen offers and the frame fills every input
/// ("done", "not now", "move it to tomorrow" with Tomorrow on the switcher), the call is bound and runs with no model.
public enum ToolPicker {
    /// One call filled from the frame, ready to run as Tess (pending, a ghost row with Undo).
    public struct Bound: Sendable, Equatable {
        public var call: String
        public var place: ElementPlace
        /// The object the call is about (a label still points at the right thing).
        public var object: UUID?
        /// The other inputs, as the tool takes them (names and the switcher's window word).
        public var arguments: [String: String]
    }

    public struct Pick: Sendable, Equatable {
        /// Tool names to send, best first. Never a `deviceOnly` call when the plan reaches Claude.
        public var tools: [String]
        public var plan: RungPlan
        public var bound: Bound?
        /// The calls the ask named, best first, so the trace can show why.
        public var matched: [String]
        /// The ask is about how something looks: the frame sends each place's look line.
        public var looks = false
    }

    /// The most tools one ask carries.
    public static let maxTools = 12
    /// The reads every ask may use.
    static let reads = ["query", "open", "recall"]
    /// A bound call is a short command; a longer ask has more in it than the frame can fill.
    static let boundWords = 6

    /// `looks` is his kept looks (settings), which a trait word steps from ("denser" is one step denser than now).
    public static func pick(_ ask: String, frame: TessFrame, agent: AgentSpec? = nil,
                            looks kept: RoomLooks = RoomLooks()) -> Pick
    {
        // A look nudge on one place ("denser", "the doors as an index", "as it was"): no model.
        let looks = LookWords.isAbout(ask)
        if let bound = lookBound(ask, frame: frame, about: looks, looks: kept) {
            return Pick(tools: [bound.call], plan: forced(bound.call), bound: bound, matched: [bound.call], looks: true)
        }
        let offered = frame.calls
        let words = TessFrame.words(ask)
        let pointed = TessFrame.points(ask)
        // A call matches when his words name it and it can act on the thing it would act on.
        let matched = offered.filter { entry in
            entry.call.phrases.contains { phrase in contains(words, TessFrame.words(phrase)) }
                && entry.call.applies(to: target(of: entry.call, at: entry.place, frame: frame, pointed: pointed))
        }

        // One call named ("open this" names two, but only one of them takes a thing), every input filled from the
        // frame: run it, no model.
        // The look tools bind only above, from the look words.
        let bindable = matched.filter { !LookWords.calls.contains($0.call.name) }
        let aboutThing = bindable.filter { entry in entry.call.inputs.contains { $0.source == .referent } }
        let single: (place: ElementPlace, call: ElementCall)? = bindable.count == 1 ? bindable.first
            : pointed && aboutThing.count == 1 ? aboutThing.first : nil
        if let entry = single, words.count <= boundWords,
           let bound = bind(entry.call, at: entry.place, frame: frame, pointed: pointed)
        {
            let plan = entry.call.reach == .deviceOnly ? device(entry.call.name) : forced(entry.call.name)
            return Pick(tools: [entry.call.name], plan: plan, bound: bound, matched: [entry.call.name])
        }

        // A money call named: the phone's own model only, with that call.
        if let money = matched.first(where: { $0.call.reach == .deviceOnly }) {
            return Pick(tools: [money.call.name], plan: device(money.call.name), bound: nil,
                        matched: matched.map { $0.call.name })
        }

        let deviceOnly = Set(offered.filter { $0.call.reach == .deviceOnly }.map { $0.call.name })
        var tools: [String] = []
        let named: [String] = matched.map { $0.call.name }
        let shown: [String] = offered.map { $0.call.name }
        let candidates: [String] = named + shown + (agent?.tools ?? []) + reads
        // The look calls ride only on an ask about looks, so she never changes a look he didn't ask about.
        for name in candidates where !deviceOnly.contains(name) && !tools.contains(name)
            && (looks || !LookWords.calls.contains(name))
        {
            tools.append(name)
        }
        let plan = matched.isEmpty ? RungPlan.pick(ask) : small(ask)
        if looks {
            // About a look: the two look calls lead, whatever else the screen offers.
            tools = ["setLook", "showLooks"] + tools.filter { !LookWords.calls.contains($0) }
        }
        if TessGuide.isAbout(ask) {
            // How the app or she works: the guide rides right after the calls he named, before the cut.
            tools.insert(TessGuide.name, at: tools.prefix { named.contains($0) }.count)
        }
        return Pick(tools: Array(tools.prefix(maxTools)), plan: plan, bound: nil, matched: matched.map { $0.call.name },
                    looks: looks)
    }

    /// Fills a call's inputs from the frame. Nil when a required input needs his words, or "this" means nothing.
    static func bind(_ call: ElementCall, at place: ElementPlace, frame: TessFrame, pointed: Bool) -> Bound? {
        var object: UUID?
        var arguments: [String: String] = [:]
        for input in call.inputs {
            switch input.source {
            case .asked:
                if input.required {
                    return nil
                }
            case .referent:
                guard let item = target(of: call, at: place, frame: frame, pointed: pointed) else {
                    if input.required { return nil }
                    continue
                }
                object = item.id
                arguments[input.name] = item.name
            case .window:
                guard let window = frame.window else {
                    if input.required { return nil }
                    continue
                }
                arguments[input.name] = window
            case .door:
                guard let door = frame.element(.dial)?.focused?.name ?? frame.door else {
                    if input.required { return nil }
                    continue
                }
                arguments[input.name] = door
            case .now:
                arguments[input.name] = ISO8601DateFormatter().string(from: frame.now)
            }
        }
        return Bound(call: call.name, place: place, object: object, arguments: arguments)
    }

    /// The thing a call would act on: what he pointed at ("this"), else the focused item on the place that offers it,
    /// else what he touched or the screen's focus. Nil for a call that takes no thing.
    static func target(of call: ElementCall, at place: ElementPlace, frame: TessFrame, pointed: Bool) -> ElementItem? {
        guard call.inputs.contains(where: { $0.source == .referent }) else { return nil }
        if pointed {
            return frame.referent()?.item
        }
        let own: ElementItem? = frame.element(place)?.focused
        return own ?? frame.referent()?.item
    }

    /// Whether `phrase` appears in `words` as whole words, in order.
    static func contains(_ words: [String], _ phrase: [String]) -> Bool {
        guard !phrase.isEmpty, phrase.count <= words.count else { return false }
        for start in 0 ... (words.count - phrase.count) where Array(words[start ..< start + phrase.count]) == phrase {
            return true
        }
        return false
    }

    /// A named call: a small action, so Haiku first (a bigger model only overthinks it), unless the ask is open.
    static func small(_ ask: String) -> RungPlan {
        RungPlan.pick(ask) == .open ? .open : .plain
    }

    /// A bound call the model still confirms when the caller wants words: the one tool, forced.
    static func forced(_ name: String) -> RungPlan {
        var plan = RungPlan.plain
        plan.toolChoice = .tool(name)
        return plan
    }

    /// Money: never Claude. The phone's own model with the one call.
    static func device(_ name: String) -> RungPlan {
        var plan = RungPlan.deviceOnly
        plan.toolChoice = .tool(name)
        return plan
    }
}
