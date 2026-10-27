import Foundation

// C6 in shadow (checks.md, m3-wiring.md): every finished reply's numbers are checked against what she was given, and
// the verdict goes on the run's trace as a `check` span, so the live runner can measure false fails on the test world
// before the check may retry anything. Nothing retries yet. The span carries the verdict and a count, never the
// numbers or his words: a body or money number never reaches a log.

extension TessRun {
    /// The check span's name.
    static let answerCheck = "answer-check"

    /// What she was given for a run: the system blocks, the pack's fragments, his messages, every tool result, and
    /// the results of server tools (web search and fetch), which arrive inside her own turns.
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
                    if (block?["type"] as? String)?.hasSuffix("_result") == true {
                        texts.append(String(decoding: data, as: UTF8.self))
                    }
                default:
                    break
                }
            }
        }
        return texts
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
