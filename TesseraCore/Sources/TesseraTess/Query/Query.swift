import Foundation

/// The query AST (docs/research/questions-eval.md): `from`, `where`, `during`, `group`, `agg`, `sort`, `limit`. It is
/// the one way Tess reads numbers out of the store, so counts, bests and averages come from the data and never from a
/// model's arithmetic. A query only reads: it never writes, and it only sees what `answerQuery` always saw (the
/// allow-list of classes, minus anything private for Claude).
public struct Query: Codable, Equatable, Sendable {
    public struct Pred: Codable, Equatable, Sendable {
        /// A field, or a path through links: `exercise.pattern`, `workout.routine`, `parent.title`.
        public var field: String
        /// `=` `!=` `<` `<=` `>` `>=` `~` (contains) `isa` `has` `none`
        public var op: String
        public var value: String?

        public init(field: String, op: String, value: String? = nil) {
            self.field = field
            self.op = op
            self.value = value
        }
    }

    public struct During: Codable, Equatable, Sendable {
        /// today, tomorrow, thisWeek, lastWeek, thisMonth, lastMonth, thisYear, last7d, last30d, last90d,
        /// date:2026-10-12,
        /// month:2026-09
        public var range: String
        /// The date field; nil means the class's own (a set's loggedAt, a workout's endedAt, a task's due).
        public var field: String?

        public init(range: String, field: String? = nil) {
            self.range = range
            self.field = field
        }
    }

    public struct Agg: Codable, Equatable, Sendable {
        /// list, count, sum, avg, min, max, latest
        public var kind: String
        public var field: String?

        public init(kind: String, field: String? = nil) {
            self.kind = kind
            self.field = field
        }
    }

    public struct Sort: Codable, Equatable, Sendable {
        public var field: String
        public var descending: Bool

        public init(field: String, descending: Bool = false) {
            self.field = field
            self.descending = descending
        }
    }

    public var from: [String]
    public var predicates: [Pred]
    public var during: During?
    public var group: String?
    public var agg: Agg
    public var sort: Sort?
    public var limit: Int?

    private enum CodingKeys: String, CodingKey {
        case from, predicates = "where", during, group, agg, sort, limit
    }

    public init(from: [String], where predicates: [Pred] = [], during: During? = nil, group: String? = nil,
                agg: Agg = Agg(kind: "list"), sort: Sort? = nil, limit: Int? = nil)
    {
        self.from = from
        self.predicates = predicates
        self.during = during
        self.group = group
        self.agg = agg
        self.sort = sort
        self.limit = limit
    }

    public static let ops: Set<String> = ["=", "!=", "<", "<=", ">", ">=", "~", "isa", "has", "none"]
    public static let aggs: Set<String> = ["list", "count", "sum", "avg", "min", "max", "latest"]
    public static let ranges: Set<String> = ["today", "tomorrow", "thisWeek", "lastWeek", "thisMonth", "lastMonth",
                                             "thisYear", "last7d", "last30d", "last90d"]

    /// The tool's JSON, or nil when it does not decode.
    public init?(json: Data) {
        guard let decoded = try? JSONDecoder().decode(Query.self, from: json) else { return nil }
        self = decoded
    }
}

/// Why a query could not be answered, in a line the model (and the phone) can read.
public struct QueryError: Error, Equatable, CustomStringConvertible, Sendable {
    public let description: String

    public init(_ description: String) {
        self.description = description
    }
}

/// What a query found: the one-line answer, the objects behind it (for handles), and the number if there is one.
public struct QueryResult: Sendable {
    public var line: String
    public var matched: [UUID]
    public var value: Double?
    /// Per-group counts or values, in the order the line shows them.
    public var groups: [(name: String, value: Double)] = []
}
