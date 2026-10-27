import Foundation

// C6 in shadow (checks.md, m3-wiring.md): every finished reply's numbers are checked against what she was given, and
// the verdict goes on the run's trace as a `check` span, so the live runner can measure false fails on the test world
// before the check may retry anything. Nothing retries yet. The span carries the verdict and a count, never the
// numbers or his words: a body or money number never reaches a log.

extension TessRun {
    /// The check span's name.
    static let answerCheck = "answer-check"

    /// The keys whose strings are a server tool result's readable words.
    static let readableKeys: Set<String> = ["text", "content", "title", "data", "cited_text"]

    /// What she was given for a run: the system blocks, the pack's fragments, his messages, every tool result, and
    /// the readable words of server tool results (web search and fetch), which arrive inside her own turns.
    static func evidence(system: [TextBlock], fragments: [PackFragment], messages: [BrainMessage]) -> [String] {
        var texts = system.map(\.text) + fragments.map(\.text)
        for message in messages {
            for piece in message.content {
                switch piece {
                case let .text(text) where message.role == .user:
                    texts.append(text)
                case let .toolResult(_, content, _):
                    texts.append(content)
                case let .raw(data):
                    let block = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                    if let block, (block["type"] as? String)?.hasSuffix("_result") == true {
                        texts += readable(block)
                    }
                default:
                    break
                }
            }
        }
        return texts
    }

    /// A result's readable words: never its ids, URLs, page ages or encrypted content, whose stray digits would
    /// "support" a number she made up.
    static func readable(_ value: Any, key: String? = nil) -> [String] {
        switch value {
        case let text as String:
            key.map { readableKeys.contains($0) } == true ? [text] : []
        case let list as [Any]:
            list.flatMap { readable($0, key: key) }
        case let object as [String: Any]:
            object.flatMap { readable($0.value, key: $0.key) }
        default:
            []
        }
    }

    /// Checks a finished reply and records the verdict on the run's trace.
    func recordAnswerCheck(reply: String, ask: String, pack: Pack, messages: [BrainMessage], runID: UUID) async {
        let started = ContinuousClock.now
        let evidence = Self.evidence(system: pack.system, fragments: pack.fragments, messages: messages)
        let result = AnswerCheck().check(reply: reply, evidence: evidence, ask: ask)
        await trace.record(TraceSpan(kind: .check, name: Self.answerCheck, at: now(),
                                     totalMs: LatencyBench.ms(.now - started),
                                     outcome: result.passed ? "passed" : "failed", runID: runID,
                                     unsupported: result.unsupported.count))
    }
}
