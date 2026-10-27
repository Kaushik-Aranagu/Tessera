import Foundation

/// Procedural memory (input-hygiene H6): which tool paths answered each job, learned from run digests at night. It
/// holds tool names and counts only, so its hint may go in any pack.
///
/// It learns only from clean signals (rule 8):
/// - never from a run that read a page or an untrusted tool result;
/// - never from a run that ended for a reason the path didn't cause: no network, a busy server, the cap, a wall, or
///   a run he cancelled;
/// - and never from cost, which a tuner never reads.
public struct ProcedureBook: Sendable, Equatable, Codable {
    /// The most paths kept; past it the one used longest ago goes.
    public static let maxPaths = 200
    /// The fewest tries before a path is offered as one that works.
    public static let minTries = 3
    /// The outcomes a path is judged by when no brain answered. Every other ending says nothing about the path.
    public static let pathFailures: Set<String> = [ClaudeOutcome.refused.rawValue, ClaudeOutcome.other.rawValue]

    public struct Record: Sendable, Equatable, Codable {
        public var job: String
        public var path: [String]
        public var tries: Int
        public var answered: Int
        public var failedCalls: Int
        public var totalMs: Int
        public var lastAt: Date

        /// The answered share with one answer and one miss added, so 1 of 1 never outranks 9 of 10.
        public var rate: Double {
            Double(answered + 1) / Double(tries + 2)
        }

        public var averageMs: Int {
            tries > 0 ? totalMs / tries : 0
        }
    }

    public private(set) var records: [String: Record] = [:]

    public init() {}

    static func key(job: String, path: [String]) -> String {
        job + "|" + path.joined(separator: ">")
    }

    /// Learns one run. False when the run is no signal and nothing changed.
    @discardableResult
    public mutating func learn(_ run: RunDigest) -> Bool {
        guard !run.reading.untrusted, run.answered || Self.pathFailures.contains(run.failure ?? "") else {
            return false
        }
        let key = Self.key(job: run.job, path: run.path)
        var record = records[key] ?? Record(job: run.job, path: run.path, tries: 0, answered: 0, failedCalls: 0,
                                            totalMs: 0, lastAt: run.at)
        record.tries += 1
        record.answered += run.answered ? 1 : 0
        record.failedCalls += run.steps.count(where: { !$0.ok })
        record.totalMs += run.totalMs
        record.lastAt = max(record.lastAt, run.at)
        records[key] = record
        if records.count > Self.maxPaths,
           let oldest = records.min(by: { ($0.value.lastAt, $0.key) < ($1.value.lastAt, $1.key) })?.key
        {
            records[oldest] = nil
        }
        return true
    }

    /// Forgets every path not used since `date`.
    public mutating func expire(before date: Date) {
        records = records.filter { $0.value.lastAt >= date }
    }

    /// The paths that worked for a job, best first: the answered share, then the faster one. Only paths with
    /// `minTries` tries.
    public func best(for job: String) -> [Record] {
        records.values.filter { $0.job == job && $0.tries >= Self.minTries }
            .sorted { ($1.rate, $0.averageMs, $0.path.joined()) < ($0.rate, $1.averageMs, $1.path.joined()) }
    }

    /// One line for the job's pack: the two paths that answered most often. Nil until one has enough tries.
    public func hint(for job: String) -> String? {
        let top = best(for: job).filter { !$0.path.isEmpty }.prefix(2)
        guard !top.isEmpty else { return nil }
        let paths = top.map { "\($0.path.joined(separator: " then ")) (\($0.answered) of \($0.tries))" }
        return "Tool paths that answered before: \(paths.joined(separator: "; "))."
    }
}
