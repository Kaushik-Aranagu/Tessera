import Foundation

/// Checks every number in a Tess reply against what she was given (checks.md C6). Accuracy first (Kaushik, Oct 23):
/// a number that isn't in her evidence (the pack, the tool results, his own ask) fails, and the run tries again one
/// rung up with the reason. The check is pure and runs on the phone in microseconds.
///
/// What counts as support for a number in the reply:
/// - the same value in the evidence (unitless numbers match any unit; 8,420 is 8420; "three" is 3);
/// - the same amount in the other unit (kg and lb, km and miles, minutes and hours), within rounding;
/// - after a change word ("up 3 kg", "4 more sets", "12 in total"), the difference or sum of two evidence numbers.
///
/// Not checked: clock times, dates, years, ordinals, and the word "one".
public struct AnswerCheck: Sendable {
    public enum Unit: String, Sendable {
        case kg, lb, km, miles, minutes, hours, percent, money, kcal, grams
    }

    /// A number as written in a reply or the evidence.
    public struct Claim: Sendable, Equatable {
        public var text: String
        public var value: Double
        public var unit: Unit?
        /// A change word sits just before it ("up 3", "+3", "4 more").
        public var derived: Bool
    }

    public struct Result: Sendable, Equatable {
        public var unsupported: [Claim]
        public var passed: Bool {
            unsupported.isEmpty
        }
    }

    public init() {}

    public func check(reply: String, evidence: [String], ask: String = "") -> Result {
        let given = (evidence + [ask]).flatMap { Self.claims(in: $0) }
        let unsupported = Self.claims(in: reply).filter { !Self.supported($0, by: given) }
        return Result(unsupported: unsupported)
    }

    /// The note the next rung gets with the run's messages when the check failed.
    public static func retryNote(_ result: Result) -> String {
        let listed = result.unsupported.map { "\"\($0.text)\"" }.joined(separator: ", ")
        return "Your last answer said \(listed), which isn't in anything you were given. Get every number from the "
            + "query or open tools, then answer again. Say you don't know if the data doesn't have it."
    }

    // MARK: Support

    static func supported(_ claim: Claim, by given: [Claim]) -> Bool {
        if given.contains(where: { matches(claim, $0) }) {
            return true
        }
        guard claim.derived else { return false }
        for (index, first) in given.enumerated() {
            for second in given[(index + 1)...] where compatible(first.unit, second.unit) {
                let unit = first.unit ?? second.unit
                for value in [abs(first.value - second.value), first.value + second.value] {
                    let made = Claim(text: "", value: value, unit: unit, derived: false)
                    if matches(claim, made) {
                        return true
                    }
                }
            }
        }
        return false
    }

    static func compatible(_ one: Unit?, _ other: Unit?) -> Bool {
        one == nil || other == nil || one == other
    }

    static func matches(_ claim: Claim, _ given: Claim) -> Bool {
        if compatible(claim.unit, given.unit) {
            return abs(claim.value - given.value) <= max(0.01, abs(given.value) * 0.001)
        }
        guard let from = given.unit, let to = claim.unit, let factor = factor(from: from, to: to) else { return false }
        return abs(given.value * factor - claim.value) <= max(0.5, abs(claim.value) * 0.01)
    }

    static func factor(from: Unit, to: Unit) -> Double? {
        switch (from, to) {
        case (.kg, .lb): 2.204_62
        case (.lb, .kg): 1 / 2.204_62
        case (.km, .miles): 1 / 1.609_344
        case (.miles, .km): 1.609_344
        case (.minutes, .hours): 1.0 / 60
        case (.hours, .minutes): 60
        default: nil
        }
    }

    // MARK: Reading numbers

    static let unitWords: [String: Unit] = [
        "kg": .kg, "kgs": .kg, "kilo": .kg, "kilos": .kg, "kilogram": .kg, "kilograms": .kg,
        "lb": .lb, "lbs": .lb, "pound": .lb, "pounds": .lb,
        "km": .km, "kilometer": .km, "kilometers": .km, "mi": .miles, "mile": .miles, "miles": .miles,
        "min": .minutes, "mins": .minutes, "minute": .minutes, "minutes": .minutes,
        "h": .hours, "hr": .hours, "hrs": .hours, "hour": .hours, "hours": .hours,
        "%": .percent, "percent": .percent, "kcal": .kcal, "cal": .kcal, "cals": .kcal, "calories": .kcal,
        "g": .grams, "gram": .grams, "grams": .grams,
    ]

    static let numberWords: [String: Double] = [
        "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "fifteen": 15, "twenty": 20, "thirty": 30,
    ]

    static let changeWords: Set<String> = [
        "up", "down", "more", "fewer", "less", "extra", "total", "combined", "difference", "gained", "lost", "added",
        "dropped", "over", "under", "than", "another",
    ]

    static let months: Set<String> = [
        "jan", "january", "feb", "february", "mar", "march", "apr", "april", "may", "jun", "june", "jul", "july",
        "aug", "august", "sep", "sept", "september", "oct", "october", "nov", "november", "dec", "december",
    ]

    private static let units = unitWords.keys.sorted { $0.count > $1.count }
        .map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
    private static let words = numberWords.keys.joined(separator: "|")
    // A digit number (not inside a word, a path or a date like 2026-10-23), or a number word; then maybe a unit.
    private nonisolated(unsafe) static let pattern = try? NSRegularExpression(
        pattern: "(\\$\\s?)?(?:(?<![\\w.])(?<!\\d[-/])(\\d{1,3}(?:,\\d{3})+|\\d+)(\\.\\d+)?|\\b(\(words))\\b)"
            + "(?:\\s?(\(units))(?![A-Za-z]))?",
        options: [.caseInsensitive]
    )

    static func claims(in text: String) -> [Claim] {
        guard let pattern else { return [] }
        let source = text as NSString
        var claims: [Claim] = []
        for match in pattern.matches(in: text, range: NSRange(location: 0, length: source.length)) {
            func part(_ index: Int) -> String? {
                let range = match.range(at: index)
                return range.location == NSNotFound ? nil : source.substring(with: range)
            }
            let value: Double
            if let digits = part(2) {
                guard let number = Double(digits.replacingOccurrences(of: ",", with: "") + (part(3) ?? "")) else {
                    continue
                }
                value = number
            } else if let word = part(4), let number = numberWords[word.lowercased()] {
                value = number
            } else {
                continue
            }
            let after = source.substring(from: match.range.location + match.range.length)
            let before = source.substring(to: match.range.location)
            let unitText = part(5)?.lowercased()
            if part(2) != nil, isSkipped(value: value, hasFraction: part(3) != nil, unit: unitText,
                                         before: before, after: after)
            {
                continue
            }
            let unit: Unit? = part(1) != nil ? .money : unitText.flatMap { unitWords[$0] }
            claims.append(Claim(text: source.substring(with: match.range).trimmingCharacters(in: .whitespaces),
                                value: value, unit: unit, derived: isDerived(before: before, after: after)))
        }
        return claims
    }

    /// Clock times, years, ordinals, dates and numbers glued to letters are not quantities.
    static func isSkipped(value: Double, hasFraction: Bool, unit: String?, before: String, after: String) -> Bool {
        let next = after.first
        if before.last == ":" || next == ":" {
            return true
        }
        if unit == nil, let next, next.isLetter, next != "x" {
            return true
        }
        let following = after.lowercased().trimmingCharacters(in: .whitespaces)
        if unit == nil, ["am", "pm", "a.m.", "p.m."].contains(where: { following.hasPrefix($0) }) {
            return true
        }
        if unit == nil, !hasFraction, value >= 1900, value <= 2100 {
            return true
        }
        let previousWord = before.lowercased().split(whereSeparator: { !$0.isLetter }).last.map(String.init)
        let nextWord = following.split(whereSeparator: { !$0.isLetter }).first.map(String.init)
        if unit == nil, let word = previousWord, months.contains(word), before.last?.isWhitespace == true {
            return true
        }
        if unit == nil, let word = nextWord, months.contains(word), following.first?.isLetter == true {
            return true
        }
        return false
    }

    /// A change word in the three words before ("up 3", "+3", "by 3") or right after ("4 more", "2 fewer").
    static func isDerived(before: String, after: String) -> Bool {
        let trimmed = before.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("+") || trimmed.hasSuffix("−") || trimmed.lowercased().hasSuffix(" by") {
            return true
        }
        let recent = trimmed.lowercased().split(whereSeparator: { !$0.isLetter }).suffix(3).map(String.init)
        let next = after.lowercased().split(whereSeparator: { !$0.isLetter }).first.map(String.init)
        return recent.contains { changeWords.contains($0) } || next.map { ["more", "fewer", "less", "extra"]
            .contains($0) } == true
    }
}
