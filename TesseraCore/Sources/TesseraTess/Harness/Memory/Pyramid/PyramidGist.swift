import Foundation

// P1b of the memory pyramid (docs/ai/harness/memory-pyramid.md): each node's gist in words, written by a model from
// its children and kept only where the children back it. A sentence with no cite, a cite to a child it never saw, a
// number its cites don't hold, or words past the level's budget is dropped, never patched. The totals stay the
// engine's; a gist only says what the children share.
//
// A gist goes to Claude through the Door, and the Door's policy decides what the model sees: under strict only the
// claude-safe children, totals and residuals, so a strict gist never rests on a walled thing. Lab and strict keep
// separate gists.

/// One sentence of a gist and the child paths that show it.
public struct PyramidSentence: Sendable, Equatable {
    public var text: String
    public var cites: [String]
    /// `deviceOnly` when anything it could rest on was walled.
    public var taint: Taint
}

/// Why the check dropped a sentence.
public enum PyramidDrop: String, Sendable, Equatable {
    /// The reply was not a gist at all.
    case unreadable
    case empty
    case noCite
    /// It cites a path that is not a child the model was shown.
    case unknownCite
    /// It holds a number that neither its cites nor the node's own totals hold.
    case unsupportedNumber
    /// It would take the gist past its level's word budget.
    case overBudget
}

public struct PyramidGist: Sendable, Equatable {
    public var path: String
    /// The node's fingerprint when the gist was written: a node whose hash moved has a stale gist.
    public var hash: UInt64
    public var policy: DoorPolicy
    public var sentences: [PyramidSentence]
    public var dropped: [PyramidDrop]
}

/// The gists of one pyramid, kept apart by policy.
public struct PyramidGists: Sendable, Equatable {
    var lab: [String: PyramidGist] = [:]
    var strict: [String: PyramidGist] = [:]

    public init() {}

    public subscript(path: String, policy: DoorPolicy) -> PyramidGist? {
        get { policy == .lab ? lab[path] : strict[path] }
        set {
            if policy == .lab {
                lab[path] = newValue
            } else {
                strict[path] = newValue
            }
        }
    }

    /// A gist still true of its node: written under this policy over the node as it is now.
    public func fresh(_ path: String, policy: DoorPolicy, in pyramid: MemoryPyramid) -> PyramidGist? {
        guard let gist = self[path, policy], gist.hash == pyramid.nodes[path]?.hash else { return nil }
        return gist
    }

    /// The nodes a policy can see whose gist is missing or stale, lowest level first, so each one is written after
    /// its children. Leaves have none: they are their own words.
    public func stale(in pyramid: MemoryPyramid, policy: DoorPolicy) -> [String] {
        let rank: [PyramidNode.Level: Int] = [.day: 0, .week: 1, .month: 1, .year: 2, .root: 3]
        return pyramid.nodes.values
            .filter { node in
                node.level != .leaf && (policy == .lab || node.safeLeaves > 0)
                    && fresh(node.path, policy: policy, in: pyramid) == nil
            }
            .sorted { a, b in
                let left = rank[a.level] ?? 0, right = rank[b.level] ?? 0
                return left == right ? a.path < b.path : left < right
            }
            .map(\.path)
    }
}

/// Writes gists through the Door. Haiku, effort low, one strict tool whose cites can only name the children it was
/// shown.
@MainActor
public struct PyramidDistiller {
    public static let toolName = "writeGist"
    /// What a forced tool call adds to a request beyond its words, padded onto every pyramid job's estimate.
    public static let toolOverheadTokens = 400

    /// What one node's gist is written from, line by line, each line with its taint.
    public struct Material: Sendable {
        public struct Child: Sendable {
            public var path: String
            public var lines: [PackFragment]
        }

        /// The node's own title and totals.
        public var head: [PackFragment]
        public var children: [Child]

        public var fragments: [PackFragment] {
            head + children.flatMap { $0.lines }
        }
    }

    public let door: Door

    public init(door: Door) {
        self.door = door
    }

    /// The most words a gist keeps at each level.
    public static func budget(_ level: PyramidNode.Level) -> Int {
        switch level {
        case .leaf: 0
        case .day: 60
        case .week: 120
        case .month, .year, .root: 200
        }
    }

    // MARK: Material

    /// What a policy lets the model see of a node: its totals, then each child it may see with that child's totals,
    /// what sets it apart and its own fresh gist, or a day's leaves word for word. Nil when the policy sees nothing.
    public static func material(_ path: String, in pyramid: MemoryPyramid, gists: PyramidGists,
                                policy: DoorPolicy) -> Material?
    {
        guard let node = pyramid.nodes[path], node.level != .leaf else { return nil }
        func visible(_ node: PyramidNode) -> Bool {
            policy == .lab || node.safeLeaves > 0
        }
        func allowed(_ taint: Taint) -> Bool {
            policy == .lab || taint == .claudeSafe
        }
        func totals(_ node: PyramidNode, _ indent: String) -> [PackFragment] {
            PyramidStats.shown.compactMap { shown in
                guard let value = shown.value(node.stats), allowed(shown.taint) else { return nil }
                return PackFragment("\(indent)\(shown.label) \(PyramidStats.format(value))", taint: shown.taint)
            }
        }
        guard visible(node) else { return nil }
        let head = [PackFragment("\(node.title) (\(node.path)), totals:")] + totals(node, "  ")
        let residuals = node.residualsSeen(by: policy)
        var children: [Material.Child] = []
        for path in node.children {
            guard let child = pyramid.nodes[path], visible(child) else { continue }
            if let text = child.text {
                guard allowed(text.taint) else { continue }
                children.append(Material.Child(path: path, lines: [PackFragment("\(path): \(text.text)",
                                                                                  taint: text.taint)]))
                continue
            }
            var lines = [PackFragment("\(path): \(child.title)")] + totals(child, "  ")
            for line in residuals.lines[path] ?? [] where allowed(line.taint) {
                lines.append(PackFragment("  stands out: \(line.text)", taint: line.taint))
            }
            for sentence in gists.fresh(path, policy: policy, in: pyramid)?.sentences ?? []
                where allowed(sentence.taint)
            {
                lines.append(PackFragment("  in short: \(sentence.text)", taint: sentence.taint))
            }
            children.append(Material.Child(path: path, lines: lines))
        }
        return Material(head: head, children: children)
    }

    // MARK: Request

    static func schema(children: [String]) -> Data {
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false, "required": ["sentences"],
            "properties": ["sentences": [
                "type": "array",
                "items": [
                    "type": "object", "additionalProperties": false, "required": ["text", "cites"],
                    "properties": ["text": ["type": "string", "description": "One plain sentence."],
                                   "cites": ["type": "array", "items": ["type": "string", "enum": children],
                                             "description": "The child paths that show it."]],
                ],
            ]],
        ]
        let options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes]
        return (try? JSONSerialization.data(withJSONObject: schema, options: options)) ?? Data("{}".utf8)
    }

    static func instructions(words: Int) -> String {
        """
        You write the gist of one node of a person's memory from its children: what they share, what changed across \
        them, and what repeats. Reply only by calling writeGist. Every sentence cites the child paths that show it. \
        Use only numbers that appear in the lines you are given, written as digits. Use at most \(words) words in \
        all. Don't list the children one by one; their own lines already do that.
        """
    }

    public static func request(_ node: PyramidNode, children: [String]) -> BrainRequest {
        let tool = ToolSpec(name: toolName, description: "Saves the gist of this node.",
                            schema: schema(children: children))
        return BrainRequest(system: [TextBlock(instructions(words: budget(node.level)))],
                            messages: [BrainMessage(.user, text: "Write the gist of \(node.title) (\(node.path)).")],
                            tools: [tool], toolChoice: .tool(toolName), maxTokens: 700, effort: .low,
                            deadline: .seconds(20))
    }

    // MARK: Check

    /// The sentences a tool call carries, or nil when it does not decode.
    nonisolated static func drafts(from input: Data) -> [(text: String, cites: [String])]? {
        guard let root = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any],
              let items = root["sentences"] as? [[String: Any]] else { return nil }
        return items.map { item in
            ((item["text"] as? String) ?? "", (item["cites"] as? [String]) ?? [])
        }
    }

    /// The numbers in a text, normalized as a total prints: "1,200" and "1200.0" are both "1200".
    nonisolated static func numbers(_ text: String) -> Set<String> {
        var found = Set<String>()
        var current = ""
        func flush() {
            let trimmed = current.trimmingCharacters(in: CharacterSet(charactersIn: ".,"))
            if let value = Double(trimmed.replacingOccurrences(of: ",", with: "")) {
                found.insert(PyramidStats.format(value))
            }
            current = ""
        }
        for character in text {
            if character.isASCII, character.isNumber {
                current.append(character)
            } else if character == "." || character == ",", !current.isEmpty {
                current.append(character)
            } else {
                flush()
            }
        }
        flush()
        return found
    }

    /// Keeps the sentences the material backs, in order, within the level's budget.
    public static func check(_ input: Data, material: Material,
                             level: PyramidNode.Level) -> (sentences: [PyramidSentence], dropped: [PyramidDrop])
    {
        guard let drafts = drafts(from: input) else { return ([], [.unreadable]) }
        let headNumbers = material.head.reduce(into: Set<String>()) { $0.formUnion(numbers($1.text)) }
        let headWalled = material.head.contains { $0.taint != .claudeSafe }
        var byPath: [String: [PackFragment]] = [:]
        for child in material.children {
            byPath[child.path] = child.lines
        }
        var kept: [PyramidSentence] = [], dropped: [PyramidDrop] = []
        var words = 0
        for draft in drafts {
            let text = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let count = text.split { $0 == " " || $0 == "\n" }.count
            let cited = draft.cites.compactMap { byPath[$0] }
            let backed = cited.joined().reduce(into: headNumbers) { $0.formUnion(numbers($1.text)) }
            func reason() -> PyramidDrop? {
                if text.isEmpty {
                    return .empty
                }
                if draft.cites.isEmpty {
                    return .noCite
                }
                if cited.count != draft.cites.count {
                    return .unknownCite
                }
                if !numbers(text).isSubset(of: backed) {
                    return .unsupportedNumber
                }
                return words + count > budget(level) ? .overBudget : nil
            }
            if let drop = reason() {
                dropped.append(drop)
                continue
            }
            words += count
            let walled = headWalled || cited.joined().contains { $0.taint != .claudeSafe }
            kept.append(PyramidSentence(text: text, cites: draft.cites, taint: walled ? .deviceOnly : .claudeSafe))
        }
        return (kept, dropped)
    }

    // MARK: Run

    /// Asks for one node's gist under a policy, the Door's own when none is given. Nil when the policy sees nothing
    /// there, the Door sent nothing, or no sentence survived the check.
    public func distill(_ path: String, in pyramid: MemoryPyramid, gists: PyramidGists,
                        policy given: DoorPolicy? = nil) async -> PyramidGist?
    {
        let policy = given ?? door.policy()
        guard let node = pyramid.nodes[path],
              let material = Self.material(path, in: pyramid, gists: gists, policy: policy),
              !material.children.isEmpty else { return nil }
        let request = Self.request(node, children: material.children.map { $0.path })
        let estimate = TessUsageLedger.estimate(
            text: Door.words(request) + material.fragments.map(\.text).joined(separator: "\n")
                + String(decoding: Self.schema(children: material.children.map { $0.path }), as: UTF8.self),
            // Tool use adds a few hundred tokens the text doesn't show; counting them as output keeps the hold high.
            maxTokens: request.maxTokens + PyramidDistiller.toolOverheadTokens,
            model: ClaudeBrain.Model.haiku.rawValue
        )
        let job = DoorJob(name: "pyramid-gist", ladder: [.haiku], request: request, fragments: material.fragments,
                          estimateNano: estimate, validator: { Self.drafts(from: $0) != nil })
        var input: Data?
        do {
            for try await event in door.run(job) {
                if case let .toolUse(_, name, data) = event, name == Self.toolName {
                    input = data
                }
            }
        } catch {
            input = nil
        }
        guard let input else { return nil }
        let checked = Self.check(input, material: material, level: node.level)
        guard !checked.sentences.isEmpty else { return nil }
        return PyramidGist(path: path, hash: node.hash, policy: policy, sentences: checked.sentences,
                           dropped: checked.dropped)
    }

    /// The night's pass for gists: every stale one the policy can see, lowest level first, so each node reads its
    /// children's new gists. `limit` caps the calls.
    public func refresh(_ pyramid: MemoryPyramid, gists: PyramidGists, limit: Int = .max) async -> PyramidGists {
        var gists = gists
        // One policy for the whole pass, so every gist is written, read and stored under the same one.
        let policy = door.policy()
        for path in gists.stale(in: pyramid, policy: policy).prefix(limit) {
            if let gist = await distill(path, in: pyramid, gists: gists, policy: policy) {
                gists[path, gist.policy] = gist
            }
        }
        return gists
    }
}
