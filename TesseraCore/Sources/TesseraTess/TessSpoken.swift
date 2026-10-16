import Foundation

/// Spoken numbers to digits, before the grammar (docs/research/fixtures/spoken-normaliser.md, "Live-workout number
/// words", board item 78). Pure and idempotent: digits pass through, the clock is never read, a weight is never
/// snapped and reps are never decided here (that's S701 to S706). The Speak layer runs it on a transcript.
public enum TessSpoken {
    /// "eighty two and a half for eight" → "82.5 for 8"; "a hundred, five" → "100, 5"; "plus five" → "+5".
    public static func numbers(_ heard: String) -> String {
        var text = heard.lowercased().replacingOccurrences(of: "-", with: " ")
            .replacing(/\s+/, with: " ").trimmingCharacters(in: .whitespaces)
        text = text.replacing(/[.!]+$/, with: "")
        // A comma is a token of its own: it ends a number run ("a hundred, five" is never 105).
        let words = text.replacingOccurrences(of: ",", with: " , ").split(separator: " ").map(String.init)
        var tokens = protect(dropLeadingFillers(words))
        tokens = readRuns(tokens)
        tokens = afterRuns(tokens)
        return tokens.joined(separator: " ").replacingOccurrences(of: " ,", with: ",")
    }

    // MARK: Words

    static let units: [String: Double] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
    ]
    static let teens: [String: Double] = [
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16,
        "seventeen": 17, "eighteen": 18, "nineteen": 19,
    ]
    static let tens: [String: Double] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    ]

    static func isNumberWord(_ word: String) -> Bool {
        units[word] != nil || teens[word] != nil || tens[word] != nil || word == "hundred"
    }

    /// A token that is already a number ("82.5", "100").
    static func digits(_ word: String) -> Double? {
        word.firstMatch(of: /^\d+(?:\.\d+)?$/) != nil ? Double(word) : nil
    }

    /// Leading "and", "so", "okay" go (N21); "a" goes before a plain number word ("a eight", N20) but stays before
    /// hundred, couple, few and the like.
    static func dropLeadingFillers(_ words: [String]) -> [String] {
        var words = words
        while let first = words.first, ["and", "so", "okay", "ok"].contains(first) {
            words.removeFirst()
        }
        var kept: [String] = []
        for (index, word) in words.enumerated() {
            let next = index + 1 < words.count ? words[index + 1] : ""
            if word == "a", units[next] != nil || teens[next] != nil || tens[next] != nil {
                continue
            }
            kept.append(word)
        }
        return kept
    }

    /// Spans no later step touches: "one more", "same again", "a couple", "a few", a number word before a load noun.
    /// A protected token carries a leading "\u{1}" until the end.
    static func protect(_ words: [String]) -> [String] {
        var words = words
        for index in words.indices {
            let next = index + 1 < words.count ? words[index + 1] : ""
            if words[index] == "one", next == "more" {
                words[index] = "\u{1}one"
            }
            if isNumberWord(words[index]), ["plates", "plate", "side"].contains(next) || next == "a"
                && index + 2 < words.count && words[index + 2] == "side"
            {
                words[index] = "\u{1}" + words[index]
            }
        }
        return words
    }

    // MARK: Runs

    /// Each series of number words (no comma inside) becomes one or more numbers: "a hundred and five" 105, "eighty
    /// two" 82, "one oh five" 105, "one twenty five" 125, "eighty two point four" 82.4, "and a half" +0.5. A word that
    /// can't join the number so far starts a new one ("eighty four eight" is 84 8, "ten ten ten" stays three).
    static func readRuns(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var index = 0
        while index < tokens.count {
            if let (value, used) = readNumber(tokens, from: index) {
                out.append(format(value))
                index += used
            } else {
                out.append(tokens[index])
                index += 1
            }
        }
        return out
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func readNumber(_ tokens: [String], from start: Int) -> (Double, Int)? {
        func word(_ offset: Int) -> String {
            start + offset < tokens.count ? tokens[start + offset] : ""
        }
        var index = 0
        var value: Double
        // "a hundred" / "one hundred" / "two hundred"
        if word(0) == "a", word(1) == "hundred" {
            value = 100
            index = 2
        } else if let unit = units[word(0)], word(1) == "hundred" {
            value = unit * 100
            index = 2
        } else if let unit = units[word(0)], word(1) == "oh", let last = units[word(2)] {
            // "one oh five": 105 (an "oh" only counts inside a run).
            value = unit * 100 + last
            index = 3
        } else if let unit = units[word(0)], (1 ... 3).contains(unit), tens[word(1)] != nil || teens[word(1)] != nil,
                  !isOperator(word(2)) || units[word(2)] != nil
        {
            // "one twenty five": 125, only 100 to 399.
            value = unit * 100 + (tens[word(1)] ?? teens[word(1)] ?? 0)
            index = 2
            if tens[word(1)] != nil, let last = units[word(2)], last > 0 {
                value += last
                index = 3
            }
        } else if let ten = tens[word(0)] {
            value = ten
            index = 1
            if let unit = units[word(1)], unit > 0 {
                value += unit
                index = 2
            }
        } else if let teen = teens[word(0)] {
            value = teen
            index = 1
        } else if let unit = units[word(0)] {
            value = unit
            index = 1
        } else if let number = digits(word(0)), word(1) == "and" || word(1) == "point" {
            // Digits the transcriber wrote, joined by "and a half" or "point" below.
            value = number
            index = 1
        } else {
            return nil
        }
        // After a hundred: "and five", "five", "twenty four", "twelve".
        if value >= 100, value.truncatingRemainder(dividingBy: 100) == 0, index >= 2, word(index - 1) == "hundred" {
            var next = index
            if word(next) == "and", isNumberWord(word(next + 1)) || digits(word(next + 1)) != nil,
               word(next + 1) != "a"
            {
                next += 1
            }
            if let ten = tens[word(next)] {
                value += ten
                next += 1
                if let unit = units[word(next)], unit > 0 {
                    value += unit
                    next += 1
                }
                index = next
            } else if let small = teens[word(next)] ?? units[word(next)] {
                value += small
                index = next + 1
            } else if let number = digits(word(next)), next > index {
                value += number // "100 and 7.5"
                index = next + 1
            }
        }
        // "point four", "point two five".
        if word(index) == "point" {
            var decimals = ""
            var next = index + 1
            while let unit = units[word(next)] {
                decimals += String(Int(unit))
                next += 1
            }
            if !decimals.isEmpty, let fraction = Double("0.\(decimals)") {
                value += fraction
                index = next
            }
        }
        // "and a half" (and en-IN "and half").
        if word(index) == "and", word(index + 1) == "a", word(index + 2) == "half" {
            value += 0.5
            index += 3
        } else if word(index) == "and", word(index + 1) == "half" {
            value += 0.5
            index += 2
        }
        // A bare digits token that joined nothing is left as it was.
        if index == 1, digits(word(0)) != nil {
            return nil
        }
        return (value, index)
    }

    static func isOperator(_ word: String) -> Bool {
        ["for", "x", "times", "by", "into"].contains(word)
    }

    static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%g", value)
    }

    // MARK: After the runs

    /// Signs, "for"/"four", "times"/"into" between numbers, units, reps, stutters.
    static func afterRuns(_ tokens: [String]) -> [String] {
        var tokens = tokens
        let isNumber = { (token: String) in digits(token) != nil }
        // "plus five" → "+5", "minus five" → "-5" at the start (N24).
        if tokens.count >= 2, let sign = ["plus": "+", "minus": "-"][tokens[0]], isNumber(tokens[1]) {
            tokens = [sign + tokens[1]] + tokens.dropFirst(2)
        }
        // A trailing "for" after exactly one number is 4, "for for" included (N18); "for" between numbers stays.
        if tokens.count >= 2, tokens.last == "for", tokens.dropLast().count(where: isNumber) == 1,
           isNumber(tokens[tokens.count - 2]) || tokens[tokens.count - 2] == "for"
        {
            tokens[tokens.count - 1] = "4"
        }
        var out: [String] = []
        for (index, token) in tokens.enumerated() {
            let previous = out.last ?? ""
            let next = index + 1 < tokens.count ? tokens[index + 1] : ""
            switch token {
            case "times", "into" where isNumber(previous) && isNumber(next):
                out.append("x")
            case "kilos", "kilo", "kilograms", "kgs", "k" where isNumber(previous):
                out.append("kg")
            case "pounds", "lbs", "lbs.", "pound" where isNumber(previous):
                out.append("lb")
            case "rep" where isNumber(previous):
                out.append("reps")
            case "reps" where out.count >= 3 && isNumber(previous) && ["for", "x"].contains(out[out.count - 2]):
                continue // "80 for 8 reps": the full set already says it (N21)
            default:
                // A number said twice right before an operator is a stutter ("eighty eighty for eight").
                if isNumber(token), token == previous, isOperator(next) {
                    continue
                }
                out.append(token)
            }
        }
        return out.map { $0.replacingOccurrences(of: "\u{1}", with: "") }
    }
}
