import Foundation

/// Secret words (Research 134, Product NE1/NE2 and Q1): a line with a password, PIN, passcode, code or wifi key in it
/// becomes a private note on the phone. It never reaches the on-device model, Claude, memory or the miss log, and
/// outside the note itself it reads "Private note". It does ride in his own backups (Q1).
public enum SecretWords {
    /// What a private note is called everywhere outside its own page.
    public static let title = "Private note"

    /// Whole words only: "pin" never catches "pinch" or "spinach".
    static let words: Set<String> = ["password", "passwords", "passcode", "passcodes", "pin", "pins", "code", "codes",
                                     "combo", "combination", "passphrase", "pw", "pwd"]

    /// The words of a line, lowercased, punctuation off, ":" kept as its own word.
    static func tokens(_ text: String) -> [String] {
        // Any whitespace, newlines included: a secret word that starts a line is its own word (Research 137 PL2).
        text.lowercased().replacingOccurrences(of: ":", with: " : ").split(whereSeparator: \.isWhitespace)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;'\"()")) }
            .filter { !$0.isEmpty }
    }

    /// Where the secret words sit in a line (indexes into `tokens`). "wifi" counts only before ":" or "is".
    static func secretIndexes(_ tokens: [String]) -> [Int] {
        tokens.indices.filter { index in
            if words.contains(tokens[index]) {
                return true
            }
            guard tokens[index] == "wifi", index + 1 < tokens.count else { return false }
            return [":", "is"].contains(tokens[index + 1])
        }
    }

    /// Whether a line holds a secret word at all.
    public static func mentions(_ text: String) -> Bool {
        !secretIndexes(tokens(text)).isEmpty
    }

    /// Whether the line carries a value after a secret word: the next word with a digit, letters mixed with digits or
    /// symbols, three or more spoken digits, or any word after "is" or ":" that follows the secret word (R3).
    public static func hasValue(_ text: String) -> Bool {
        let tokens = tokens(text)
        for index in secretIndexes(tokens) {
            var next = index + 1
            // "wifi password is …": skip a second secret word.
            while next < tokens.count, words.contains(tokens[next]) {
                next += 1
            }
            guard next < tokens.count else { continue }
            if [":", "is", "=", "-"].contains(tokens[next]) {
                return next + 1 < tokens.count
            }
            let word = tokens[next]
            if word.contains(where: \.isNumber) || word.contains(where: { "@#$%&*_/".contains($0) }) {
                return true
            }
            let spokenDigits: Set = ["zero", "oh", "one", "two", "three", "four", "five", "six", "seven", "eight",
                                     "nine"]
            if tokens[next...].prefix(while: { spokenDigits.contains($0) }).count >= 3 {
                return true
            }
        }
        return false
    }
}

/// Pasted text and fetched pages (Research 137): each line with a secret and a value is cut before anything reads,
/// stores or sends the text; the rest of the recipe reads as before. The cut line is dropped, never a private note.
public extension SecretWords {
    /// Words that name an account or card, private only with "#", "no." or "number" and four or more digits (PL4).
    internal static let accountWords: Set<String> = ["account", "acct", "member", "membership", "card"]

    /// The text with every private line cut, and how many were cut.
    static func cut(_ text: String) -> (text: String, cut: Int) {
        var cut = 0
        let kept = text.components(separatedBy: .newlines).filter { line in
            guard isPrivateLine(line) else { return true }
            cut += 1
            return false
        }
        return (kept.joined(separator: "\n"), cut)
    }

    /// Whether one pasted or fetched line holds a secret with a value. Stricter than a capture (PR5), since recipes
    /// are full of small numbers: "code 3" and "PIN the dough" pass, "door code 4417" and "pw tacocat24" do not.
    static func isPrivateLine(_ line: String) -> Bool {
        let tokens = tokens(line)
        if isAccountLine(tokens) {
            return true
        }
        for index in secretIndexes(tokens) {
            var next = index + 1
            while next < tokens.count, words.contains(tokens[next]) {
                next += 1
            }
            guard next < tokens.count else { continue }
            let needsDigit = ["combo", "combination"].contains(tokens[index])
            if [":", "is", "=", "-"].contains(tokens[next]) {
                guard next + 1 < tokens.count else { continue }
                if !needsDigit || tokens[(next + 1)...].contains(where: { $0.contains(where: \.isNumber) }) {
                    return true
                }
                continue
            }
            if isPastedValue(Array(tokens[next...])) {
                return true
            }
        }
        return false
    }

    /// A value in pasted text: 3 or more digits in a row of number words, a word mixing letters with digits or
    /// symbols, or 3 or more spoken digits.
    internal static func isPastedValue(_ rest: [String]) -> Bool {
        guard let word = rest.first else { return false }
        let digitRun = rest.prefix { $0.allSatisfy { $0.isNumber || "-.".contains($0) } }.joined()
        if digitRun.count(where: \.isNumber) >= 3 {
            return true
        }
        if word.contains(where: \.isNumber), word.contains(where: { $0.isLetter || "@#$%&*_/".contains($0) }) {
            return true
        }
        let spoken: Set = ["zero", "oh", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
        return rest.prefix(while: spoken.contains).count >= 3
    }

    /// "Costco member # 1112 2233 4455", "Account #: 0000 1234 5678", "Member account 0000 1234 5678".
    internal static func isAccountLine(_ tokens: [String]) -> Bool {
        guard tokens.joined().count(where: \.isNumber) >= 4 else { return false }
        return tokens.indices.contains { index in
            guard accountWords.contains(tokens[index]) else { return false }
            let after = tokens[(index + 1)...].prefix(2)
            return after.contains { ["#", "no", "no.", "number"].contains($0) || accountWords.contains($0) }
                || after.first?.hasPrefix("#") == true
                || after.first?.allSatisfy(\.isNumber) == true && (after.first?.count ?? 0) >= 4
        }
    }
}

public extension TessMemoryScreen {
    /// A secret word in a line meant for memory: never kept there (Research 134 SW3).
    static func isSecret(_ text: String) -> Bool {
        SecretWords.mentions(text)
    }
}
