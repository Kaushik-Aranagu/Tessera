import Foundation

// The P1b score (docs/ai/harness/memory-pyramid.md): test-world questions at three depths, each answered three ways
// from the same memory: the leaves themselves (flat), one zoom without gists, and one zoom with them. Every answer
// is computed from the world, never typed, so scoring is exact. The node a question reads is given, not found: this
// scores what a node holds, and finding the node is P2's walk.

public struct PyramidQuestion: Sendable, Equatable {
    public enum Depth: String, Sendable, Codable {
        /// One day: "How many sets did he do on Fri, Oct 2, 2026?"
        case detail
        /// Across a month's days: a count, or the day that stands out.
        case trend
        /// What repeats: the routine or the recipe he came back to most, the month that led a year.
        case pattern
    }

    public enum Expected: Sendable, Equatable {
        case number(Double)
        case day(Date)
        case month(String)
        case text(String)
    }

    public var id: String
    public var depth: Depth
    /// The node whose memory answers it.
    public var path: String
    public var ask: String
    public var expected: Expected
}

public enum PyramidScore {
    public enum Arm: String, Sendable, Codable, CaseIterable {
        case flat, zoom, zoomWithGists
    }

    public static let toolName = "answer"

    // MARK: Questions

    /// Questions over the last `months` months of the world. A question whose answer is a tie is left out, so every
    /// answer is one thing.
    public static func questions(_ world: EvalWorld, months: Int = 6) -> [PyramidQuestion] {
        let calendar = EvalWorld.calendar
        func two(_ value: Int) -> String {
            value < 10 ? "0\(value)" : String(value)
        }
        func monthPath(_ date: Date) -> String {
            let parts = calendar.dateComponents([.year, .month], from: date)
            return "\(MemoryPyramid.root)/\(parts.year ?? 0)/\(two(parts.month ?? 0))"
        }
        func dayPath(_ date: Date) -> String {
            "\(monthPath(date))/\(two(calendar.component(.day, from: date)))"
        }
        func title(_ date: Date, _ template: String) -> String {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = template
            return formatter.string(from: date)
        }
        /// The one key that leads, or nil on a tie.
        func leader(_ counts: [String: Double]) -> String? {
            guard let best = counts.values.max(), counts.values.count(where: { $0 == best }) == 1 else { return nil }
            return counts.first { $0.value == best }?.key
        }
        let lifts = world.workouts.filter { !$0.isDeleted && !$0.isPrivate }
        let byMonth = Dictionary(grouping: lifts) { monthPath($0.start) }
        let cooksByMonth = Dictionary(grouping: world.cooks) { monthPath($0.day) }
        var out: [PyramidQuestion] = []
        for month in byMonth.keys.sorted().suffix(months) {
            let workouts = byMonth[month] ?? []
            guard let first = workouts.first else { continue }
            let name = title(first.start, "MMMM yyyy")
            out.append(PyramidQuestion(id: "\(month)-workouts", depth: .trend, path: month,
                                       ask: "How many workouts did he log in \(name), not counting private ones?",
                                       expected: .number(Double(workouts.count))))
            let byDay = Dictionary(grouping: workouts) { dayPath($0.start) }
            let sets = byDay.mapValues { Double($0.reduce(0) { $0 + $1.sets.count }) }
            if let day = leader(sets), let date = byDay[day]?.first?.start {
                out.append(PyramidQuestion(id: "\(month)-most-sets", depth: .trend, path: month,
                                           ask: "Which day in \(name) had the most sets?", expected: .day(date)))
            }
            let routines = Dictionary(grouping: workouts, by: \.routine).mapValues { Double($0.count) }
            if let routine = leader(routines) {
                out.append(PyramidQuestion(id: "\(month)-routine", depth: .pattern, path: month,
                                           ask: "Which routine did he do most often in \(name)?",
                                           expected: .text(routine)))
            }
            let recipes = Dictionary(grouping: cooksByMonth[month] ?? [], by: \.recipe).mapValues { Double($0.count) }
            if let recipe = leader(recipes) {
                out.append(PyramidQuestion(id: "\(month)-recipe", depth: .pattern, path: month,
                                           ask: "Which recipe did he cook most often in \(name)?",
                                           expected: .text(recipe)))
            }
            // Two days with one workout each: the first and the middle one.
            let single = byDay.keys.sorted().filter { byDay[$0]?.count == 1 }
            for day in [single.first, single.dropFirst(single.count / 2).first].compactMap({ $0 }) {
                guard let workout = byDay[day]?.first else { continue }
                let when = title(workout.start, "EEE, MMM d, yyyy")
                out.append(PyramidQuestion(id: "\(day)-sets", depth: .detail, path: day,
                                           ask: "How many sets did he do on \(when)?",
                                           expected: .number(Double(workout.sets.count))))
                out.append(PyramidQuestion(id: "\(day)-routine", depth: .detail, path: day,
                                           ask: "Which routine did he do on \(when)?",
                                           expected: .text(workout.routine)))
            }
        }
        // The last year with at least six months of training: the month that led it.
        let years = Dictionary(grouping: lifts) { calendar.component(.year, from: $0.start) }
        if let year = years.keys.sorted().last(where: { year in
            Set((years[year] ?? []).map { calendar.component(.month, from: $0.start) }).count >= 6
        }) {
            let counts = Dictionary(grouping: years[year] ?? []) { title($0.start, "MMMM") }
                .mapValues { Double($0.count) }
            if let month = leader(counts) {
                out.append(PyramidQuestion(id: "\(year)-month", depth: .pattern, path: "\(MemoryPyramid.root)/\(year)",
                                           ask: "Which month of \(year) had the most workouts?",
                                           expected: .month(month)))
            }
        }
        return out
    }

    // MARK: Scoring

    public static func score(_ question: PyramidQuestion, answer: String) -> Bool {
        let lower = answer.lowercased()
        switch question.expected {
        case let .number(value):
            return PyramidDistiller.numbers(answer).contains(PyramidStats.format(value))
        case let .text(text):
            return lower.contains(text.lowercased())
        case let .month(name):
            return lower.contains(name.lowercased())
        case let .day(date):
            let calendar = EvalWorld.calendar
            let day = calendar.component(.day, from: date)
            let month = calendar.component(.month, from: date)
            let symbols = DateFormatter()
            symbols.locale = Locale(identifier: "en_US_POSIX")
            let names = [symbols.shortMonthSymbols[month - 1], symbols.monthSymbols[month - 1]]
            // "Oct 2" but not "Oct 23".
            return names.contains { name in
                lower.ranges(of: "\(name.lowercased()) \(day)").contains { range in
                    range.upperBound == lower.endIndex || !(lower[range.upperBound].isNumber)
                }
            }
        }
    }

    // MARK: Context

    /// What an arm hands the reader for a question, as fragments with their taints, so the Door filters them too.
    public static func context(_ question: PyramidQuestion, arm: Arm, pyramid: MemoryPyramid, gists: PyramidGists,
                               policy: DoorPolicy) -> [PackFragment]
    {
        switch arm {
        case .flat:
            return pyramid.leaves(under: question.path).compactMap { leaf in
                guard let text = leaf.text, policy == .lab || text.taint == .claudeSafe else { return nil }
                let day = MemoryPyramid.parent(leaf.path)
                return PackFragment("\(pyramid.nodes[day]?.title ?? day): \(text.text)", taint: text.taint)
            }
        case .zoom, .zoomWithGists:
            let read = pyramid.zoom(question.path, policy: policy, gists: arm == .zoom ? PyramidGists() : gists)
            // A zoom is already cut to its policy; under lab it may hold walled lines.
            return [PackFragment(read.text, taint: policy == .strict ? .claudeSafe : .deviceOnly)]
        }
    }

    static var schema: Data {
        let schema: [String: Any] = [
            "type": "object", "additionalProperties": false, "required": ["answer"],
            "properties": ["answer": ["type": "string", "description": "The answer alone, in a few words."]],
        ]
        return (try? JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys])) ?? Data("{}".utf8)
    }

    static let instructions = """
    Answer a question about a person's past from the memory lines you are given, and only from them. Reply only by \
    calling answer. Paths like /time/2026/10/02 name a day (Oct 2, 2026). Give a day like Oct 2, a month by its \
    name, and a number as digits. If the lines don't hold the answer, answer unknown.
    """

    public static func request(_ question: PyramidQuestion) -> BrainRequest {
        BrainRequest(system: [TextBlock(instructions)], messages: [BrainMessage(.user, text: question.ask)],
                     tools: [ToolSpec(name: toolName, description: "Gives the answer.", schema: schema)],
                     toolChoice: .tool(toolName), maxTokens: 200, effort: .low, deadline: .seconds(30))
    }

    /// The answer a tool call carries.
    public static func answer(from input: Data) -> String? {
        ((try? JSONSerialization.jsonObject(with: input)) as? [String: Any])?["answer"] as? String
    }
}
