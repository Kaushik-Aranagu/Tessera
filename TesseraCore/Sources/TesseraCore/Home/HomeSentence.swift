import Foundation

/// The one sentence Home says about the day (Together, piece 1, switch `daySentence`): one clause from each app that
/// has something to say, in the order of the day. Every clause is the app's own landing sentence, nothing new; money
/// gives due words only, never an amount; a private workout or recipe reads "Private workout" or "Private recipe"
/// because the landing facts it is built from are already masked. Computed on the phone; none of it goes to a model.
public enum HomeSentence {
    /// What tapping a clause opens.
    public enum Opens: Equatable, Sendable {
        case object(UUID)
        case app(AppID)
    }

    public struct Clause: Equatable, Sendable {
        /// Nil for a clause that belongs to no app (a task in the past sentence).
        public let app: AppID?
        public let text: String
        /// The accent word, as UTF-16 offsets into `text` (an `NSRange` without the framework): nil if none.
        public let keyWord: Range<Int>?
        public let opens: Opens
        /// When in the day it belongs (cook start, workout usual start, a due date at 9:00); nil sorts last.
        public let time: Date?
        /// How old an untimed clause is, so the oldest goes first when there are more than four.
        public let since: Date?

        public init(app: AppID?, sentence: LandingSentence, opens: Opens, time: Date? = nil, since: Date? = nil) {
            self.app = app
            text = sentence.text
            keyWord = sentence.key.flatMap { key in
                sentence.text.range(of: key).map { range in
                    let start = sentence.text.utf16.distance(from: sentence.text.startIndex, to: range.lowerBound)
                    return start ..< start + key.utf16.count
                }
            }
            self.opens = opens
            self.time = time
            self.since = since
        }
    }

    public static let maxClauses = 4
    public static let quietDay = "A quiet day"

    /// What each app has to say, already as clauses. An app with nothing gives `nil`.
    public struct Inputs: Sendable {
        public var training: Clause?
        public var kitchen: Clause?
        public var money: Clause?
        public var notes: Clause?
        public var lists: Clause?
        public var routines: Clause?

        public init(training: Clause? = nil, kitchen: Clause? = nil, money: Clause? = nil, notes: Clause? = nil,
                    lists: Clause? = nil, routines: Clause? = nil)
        {
            self.training = training
            self.kitchen = kitchen
            self.money = money
            self.notes = notes
            self.lists = lists
            self.routines = routines
        }

        var all: [Clause] {
            [training, kitchen, money, notes, lists, routines].compactMap(\.self)
        }
    }

    /// The day's clauses: by clock time, the untimed last; at most four, the oldest untimed dropped first.
    public static func compose(_ inputs: Inputs) -> [Clause] {
        var timed = inputs.all.filter { $0.time != nil }
            .sorted { ($0.time ?? .distantFuture) < ($1.time ?? .distantFuture) }
        var untimed = inputs.all.filter { $0.time == nil }
            .sorted { ($0.since ?? .distantPast) > ($1.since ?? .distantPast) }
        while timed.count + untimed.count > maxClauses, !untimed.isEmpty {
            untimed.removeLast()
        }
        if timed.count > maxClauses {
            timed.removeLast(timed.count - maxClauses)
        }
        return timed + untimed
    }

    /// The whole line: the clauses joined, or "A quiet day" when no app has anything.
    public static func text(_ clauses: [Clause]) -> String {
        clauses.isEmpty ? quietDay : clauses.map(\.text).joined(separator: ". ")
    }
}
