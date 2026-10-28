import Foundation
import TesseraCore

/// P2 of the memory pyramid (docs/ai/harness/memory-pyramid.md): his past as one read tool, `zoom`. A path reads one
/// node (`MemoryPyramid.zoom`): its totals, its gist when a fresh one was written, then what sets each child apart, so
/// she opens only as deep as an ask needs. The pack carries one line on how paths look and, when the router is sure,
/// where to start (tier 1), so a plain "how many sets last week" is one call.
///
/// A read: it writes nothing, and the Door's policy decides what a node shows (under strict, money, body and calendar
/// things are not there at all).
public enum TessZoomTool {
    public static let name = "zoom"

    /// How paths look, as the pack's line gives it.
    public static let contentsLine = "His past by time (call zoom with a path): /time, then a year like /time/2026, "
        + "a month /time/2026/10, a week /time/2026/w43 or a day /time/2026/10/27; each answer names the paths under it"

    public static var spec: ToolSpec {
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false, "required": ["path"],
            "properties": [
                "path": [
                    "type": "string",
                    "description": "A path in his past, like /time/2026/10 for October 2026 or /time/2026/w43.",
                ],
            ],
        ]
        return ToolSpec(name: name, description: "Read his past by time: a year, month, week or day with its "
            + "totals and what set each part apart, then zoom into the part that answers; read only.",
            schema: (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])) ?? Data("{}".utf8))
    }

    /// The text the tool returns: the node at a path, or how to ask when there is no path.
    public static func run(arguments: Data, pyramid: MemoryPyramid, policy: DoorPolicy,
                           gists: PyramidGists = PyramidGists()) -> (text: String, isError: Bool)
    {
        let object = (try? JSONSerialization.jsonObject(with: arguments)) as? [String: Any]
        let asked = (object?["path"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard asked.hasPrefix(MemoryPyramid.root) else {
            return ("Say a path that starts \(MemoryPyramid.root), like \(MemoryPyramid.root)/2026", true)
        }
        let read = pyramid.zoom(asked, policy: policy, gists: gists)
        guard read.isError else { return read }
        // Nothing there: the nearest node above it that holds something, so she steps up instead of guessing. An
        // empty root (no past yet) holds nothing.
        var path = asked.hasSuffix("/") ? String(asked.dropLast()) : asked
        while path.count > MemoryPyramid.root.count {
            path = MemoryPyramid.parent(path)
            if pyramid.nodes[path]?.children.isEmpty == false, !pyramid.zoom(path, policy: policy).isError {
                return ("Nothing there. Try \(path)", true)
            }
        }
        return ("Nothing in his past yet", true)
    }

    /// The pack's line: how paths look, and the node to open first when the router is sure of it (a day, else a
    /// month). The router reads the ask's words with its dates resolved; nothing it reads is kept.
    public static func line(for ask: String, pyramid: MemoryPyramid, router: PyramidRouter, policy: DoorPolicy,
                            now: Date, calendar: Calendar) -> String
    {
        let terms = PyramidAsk.terms(ask, now: now, calendar: calendar)
        for level in [PyramidNode.Level.day, .month] {
            let steps = router.guess(terms, to: level, in: pyramid, policy: policy)
            if router.isSure(steps), let start = steps.last?.path {
                return contentsLine + ". Start at \(start)"
            }
        }
        return contentsLine
    }

    // MARK: Asks about his past

    /// Asks about what he did ("how many sets last week", "when did I last cook chili"): the picker offers `zoom` on
    /// these. A day name alone is left out, since "move it to friday" looks ahead; "last friday" has "last".
    static let pastPhrases = [
        "last week", "last month", "last year", "last time", "last night", "yesterday", "ago", "this week",
        "this month", "this year", "so far", "since", "lately", "recently", "how often", "how many times",
        "when did", "when was", "did i", "have i", "what did i", "in the past",
    ] + ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"].map { "last \($0)" }

    /// Month names, but not "may" or "march", which are words too often.
    static let months = [
        "january", "february", "april", "june", "july", "august", "september", "october", "november", "december",
    ]

    public static func isAbout(_ ask: String) -> Bool {
        let spaced = " " + ask.lowercased().split { !$0.isLetter && $0 != "'" }.joined(separator: " ") + " "
        return (pastPhrases + months).contains { spaced.contains(" \($0) ") }
    }
}
